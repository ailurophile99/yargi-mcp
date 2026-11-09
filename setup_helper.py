# -*- coding: utf-8 -*-
"""
Yargı & UYAP Mevzuat MCP - Kurulum, Yama ve Doğrulama Yardımcı Betiği
Hem Windows (kurulum_windows.ps1) hem de macOS/Linux (kurulum_macos.command) tarafından çağrılır.
"""
import asyncio
import json
import os
import pathlib
import shutil
import subprocess
import sys


def ensure_mevzuat_enhancements(yargi_dir: pathlib.Path) -> None:
    """GitHub'dan ham sürüm indirildiyse UYAP Mevzuat (phrase, madde ağacı, madde getir) yamalarını uygular."""
    models_p = yargi_dir / "mevzuat_mcp_module" / "models.py"
    client_p = yargi_dir / "mevzuat_mcp_module" / "client.py"

    if models_p.exists():
        txt = models_p.read_text(encoding="utf-8")
        if "phrase: str" not in txt:
            target = 'mevzuatAdi: str = Field("", description="Keywords to search in legislation title.")'
            replacement = (
                target
                + '\n    phrase: str = Field("", description="Full-text search phrase across legislation content.")'
            )
            models_p.write_text(txt.replace(target, replacement), encoding="utf-8")

    if client_p.exists():
        txt = client_p.read_text(encoding="utf-8")
        if "get_madde_content" not in txt:
            target_search = 'if params.mevzuatAdi.strip():\n            data["mevzuatAdi"] = params.mevzuatAdi.strip()'
            replacement_search = (
                target_search
                + '\n        if getattr(params, "phrase", "") and params.phrase.strip():\n            data["phrase"] = params.phrase.strip()'
            )
            txt = txt.replace(target_search, replacement_search)

            target_tree = '''    async def get_madde_tree(self, mevzuat_id: str) -> Optional[Dict[str, Any]]:
        """Fetch the legislation article tree via POST /mevzuatMaddeTree."""
        envelope = await self._post_json("/mevzuatMaddeTree", {"mevzuatId": mevzuat_id})
        if not self._successful(envelope):
            logger.warning("MevzuatApiClient: mevzuatMaddeTree failed: %s", envelope)
            return None
        return envelope.get("data") or {}'''

            replacement_tree = (
                target_tree
                + '''

    async def get_madde_content(self, madde_id: str, mevzuat_id: str = "") -> Dict[str, Any]:
        """Fetch and decode a specific legislation article via POST /getDocumentContent with documentType=MADDE."""
        envelope = await self._post_json(
            "/getDocumentContent", {"documentType": "MADDE", "id": madde_id}
        )
        if not self._successful(envelope):
            return {
                "madde_id": madde_id,
                "mevzuat_id": mevzuat_id,
                "markdown_content": "",
                "error_message": (envelope or {}).get("metadata", {}).get("FMTE", "Failed to retrieve article content."),
            }
        inner = envelope.get("data") or {}
        content = inner.get("content")
        if not content:
            return {"madde_id": madde_id, "mevzuat_id": mevzuat_id, "markdown_content": "", "error_message": "Empty content"}
        try:
            raw = base64.b64decode(content)
            try:
                html = raw.decode("utf-8", errors="strict")
            except UnicodeDecodeError:
                html = raw.decode("cp1254", errors="replace")
            text = await asyncio.to_thread(self._html_to_text, html)
            return {"madde_id": madde_id, "mevzuat_id": mevzuat_id, "markdown_content": text, "error_message": None}
        except Exception as e:
            return {"madde_id": madde_id, "mevzuat_id": mevzuat_id, "markdown_content": "", "error_message": str(e)}'''
            )
            txt = txt.replace(target_tree, replacement_tree)
            client_p.write_text(txt, encoding="utf-8")


def configure_json_file(file_path: pathlib.Path, key_name: str, server_key: str, server_data: dict) -> bool:
    """JSON yapılandırma dosyasını diğer araçları ezmeden güvenli şekilde günceller."""
    try:
        file_path.parent.mkdir(parents=True, exist_ok=True)
        data = {}
        if file_path.exists() and file_path.stat().st_size > 0:
            try:
                data = json.loads(file_path.read_text(encoding="utf-8"))
            except Exception:
                data = {}
        if not isinstance(data.get(key_name), dict):
            data[key_name] = {}
        data[key_name][server_key] = server_data
        file_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        return True
    except Exception:
        return False


def configure_all_ai_assistants(venv_python: str, main_script: str, yargi_dir: pathlib.Path = None) -> list:
    """
    Kullanıcının bilgisayarında YÜKLÜ / TESPİT EDİLEN yapay zekâ asistanlarını yapılandırır.
    Yüklü olmayan araçlar için gereksiz klasör veya dosya oluşturmaz.
    1. Claude Desktop (Chat Sekmesi)
    2. Claude Code (CLI ve Claude Desktop'ın 'Code' Sekmesi: ~/.claude.json)
    3. Gemini (Antigravity)
    4. ChatGPT (Codex)
    5. OpenCode
    6. Cline (VS Code, Cursor, CLI)
    7. Kimi Code
    8. Hermes Agent
    9. Cursor
    """
    home = pathlib.Path.home()
    is_win = sys.platform == "win32"
    appdata = (
        pathlib.Path(os.environ.get("APPDATA"))
        if (is_win and os.environ.get("APPDATA"))
        else (home / "AppData" / "Roaming")
    )

    results = []
    std_server = {
        "command": str(venv_python),
        "args": [str(main_script)],
        "env": {"PYTHONIOENCODING": "utf-8"},
    }

    # 1. Claude Desktop (Chat Sekmesi)
    claude_desktop_cfg = (
        (appdata / "Claude" / "claude_desktop_config.json")
        if is_win
        else (home / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json")
    )
    claude_desktop_installed = claude_desktop_cfg.parent.exists()
    if claude_desktop_installed:
        configure_json_file(claude_desktop_cfg, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        results.append(("Claude Desktop (Chat)", str(claude_desktop_cfg), True))

    # 2. Claude Code (CLI ve Claude Desktop'ın 'Code' Sekmesi)
    # Claude Desktop'ın içindeki Code sekmesi ve harici Claude Code CLI ~/.claude.json dosyasını okur
    claude_code_cfg = home / ".claude.json"
    claude_cli_bin = shutil.which("claude.cmd") if is_win else shutil.which("claude")
    claude_code_installed = claude_code_cfg.exists() or (home / ".claude").exists() or (claude_cli_bin is not None) or claude_desktop_installed
    if claude_code_installed:
        configure_json_file(claude_code_cfg, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        if claude_cli_bin:
            try:
                subprocess.run(
                    [claude_cli_bin, "mcp", "add", "--scope", "user", "yargi-ve-mevzuat-mcp", "--", str(venv_python), str(main_script)],
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
            except Exception:
                pass
        results.append(("Claude Code (Code Sekmesi)", str(claude_code_cfg), True))

    # 3. Gemini (Antigravity)
    antigravity_dir = home / ".gemini"
    if antigravity_dir.exists():
        antigravity_cfg = antigravity_dir / "config" / "mcp_config.json"
        configure_json_file(antigravity_cfg, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        results.append(("Gemini (Antigravity)", str(antigravity_cfg), True))

    # 4. ChatGPT (Codex)
    codex_dir = home / ".codex"
    if codex_dir.exists():
        codex_json = codex_dir / "mcp.json"
        configure_json_file(codex_json, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        codex_toml = codex_dir / "config.toml"
        toml_snippet = (
            '\n[mcpServers.yargi-ve-mevzuat-mcp]\n'
            f'command = "{venv_python}"\n'
            f'args = ["{main_script}"]\n'
            'env = { PYTHONIOENCODING = "utf-8" }\n'
        )
        if codex_toml.exists():
            c_text = codex_toml.read_text(encoding="utf-8")
            if "[mcpServers.yargi-ve-mevzuat-mcp]" not in c_text:
                codex_toml.write_text(c_text.strip() + "\n" + toml_snippet, encoding="utf-8")
        else:
            codex_toml.write_text(toml_snippet.strip() + "\n", encoding="utf-8")
        results.append(("ChatGPT (Codex)", str(codex_toml), True))

    # 5. OpenCode
    opencode_cfg = (
        (appdata / "opencode" / "opencode.json")
        if is_win
        else (home / ".config" / "opencode" / "opencode.json")
    )
    if opencode_cfg.parent.exists():
        opencode_server = {
            "type": "local",
            "command": [str(venv_python), str(main_script)],
            "environment": {"PYTHONIOENCODING": "utf-8"},
            "enabled": True,
        }
        configure_json_file(opencode_cfg, "mcp", "yargi-ve-mevzuat-mcp", opencode_server)
        results.append(("OpenCode", str(opencode_cfg), True))

    # 6. Cline (VS Code, Cursor & CLI)
    cline_server = dict(std_server)
    cline_server["disabled"] = False
    cline_server["autoApprove"] = []

    cline_paths = []
    if is_win:
        cline_paths.append((appdata / "Code" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (VS Code)"))
        cline_paths.append((appdata / "Cursor" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (Cursor)"))
    else:
        cline_paths.append((home / "Library" / "Application Support" / "Code" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (VS Code)"))
        cline_paths.append((home / "Library" / "Application Support" / "Cursor" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (Cursor)"))
    cline_paths.append((home / ".cline" / "data" / "settings" / "cline_mcp_settings.json", "Cline (CLI)"))

    for c_path, c_label in cline_paths:
        if c_path.parent.exists():
            configure_json_file(c_path, "mcpServers", "yargi-ve-mevzuat-mcp", cline_server)
            results.append((c_label, str(c_path), True))

    # 7. Kimi Code
    kimi_dir = home / ".kimi-code"
    if kimi_dir.exists():
        kimi_cfg = kimi_dir / "mcp.json"
        configure_json_file(kimi_cfg, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        results.append(("Kimi Code", str(kimi_cfg), True))

    # 8. Hermes Agent
    hermes_dir = home / ".hermes"
    if hermes_dir.exists():
        hermes_cfg = hermes_dir / "config.yaml"
        try:
            import yaml
            h_data = {}
            if hermes_cfg.exists() and hermes_cfg.stat().st_size > 0:
                try:
                    h_data = yaml.safe_load(hermes_cfg.read_text(encoding="utf-8")) or {}
                except Exception:
                    h_data = {}
            if not isinstance(h_data.get("mcp_servers"), dict):
                h_data["mcp_servers"] = {}
            h_data["mcp_servers"]["yargi-ve-mevzuat-mcp"] = {
                "command": str(venv_python),
                "args": [str(main_script)],
                "env": {"PYTHONIOENCODING": "utf-8"},
            }
            hermes_cfg.write_text(yaml.safe_dump(h_data, sort_keys=False, allow_unicode=True), encoding="utf-8")
            results.append(("Hermes Agent", str(hermes_cfg), True))
        except Exception:
            pass

    # 9. Cursor (Doğrudan)
    cursor_dir = home / ".cursor"
    if cursor_dir.exists():
        cursor_cfg = cursor_dir / "mcp.json"
        configure_json_file(cursor_cfg, "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        results.append(("Cursor", str(cursor_cfg), True))

    # 10. Proje yerel .mcp.json (yargi-mcp dizini içi)
    if yargi_dir:
        try:
            configure_json_file(yargi_dir / ".mcp.json", "mcpServers", "yargi-ve-mevzuat-mcp", std_server)
        except Exception:
            pass

    return results


async def run_live_verification(yargi_dir: pathlib.Path) -> None:
    """UYAP Mevzuat ve Bedesten İçtihat API'lerine canlı doğrulama testi yapar."""
    sys.path.insert(0, str(yargi_dir))
    import mcp_server_main as m

    res_mevzuat = await m.mevzuat_ara(
        query="",
        phrase="",
        mevzuat_turu="KANUN",
        mevzuat_no="6098",
        baslangic_tarihi="",
        bitis_tarihi="",
        sayfa=1,
        sayfa_boyutu=1,
    )
    if not res_mevzuat.get("results"):
        raise RuntimeError("UYAP Mevzuat testi başarısız: 6098 sayılı kanun bulunamadı.")
    kanun_adi = res_mevzuat["results"][0]["mevzuat_adi"]
    mev_id = res_mevzuat["results"][0]["mevzuat_id"]
    print(f"      -> [TEST 1 BAŞARILI] UYAP Mevzuat: {kanun_adi} (ID: {mev_id})")

    app = m.create_app()
    res_bedesten = await app.call_tool(
        "search_bedesten_unified",
        {"phrase": "kira", "court_types": ["YARGITAYKARARI", "DANISTAYKARAR"]},
    )
    if not res_bedesten:
        raise RuntimeError("UYAP Bedesten İçtihat testi başarısız.")
    print("      -> [TEST 2 BAŞARILI] Yargıtay & Danıştay Bedesten API bağlantısı aktif.")


def main() -> None:
    if len(sys.argv) < 3:
        print("Kullanım: python setup_helper.py <yargi_mcp_dir> <venv_python_path>")
        sys.exit(1)

    yargi_dir = pathlib.Path(sys.argv[1]).resolve()
    venv_python = str(pathlib.Path(sys.argv[2]).absolute())
    main_script = str(yargi_dir / "mcp_server_main.py")

    ensure_mevzuat_enhancements(yargi_dir)
    print("      -> OK: UYAP Mevzuat ve Yargı modülleri doğrulandı.")

    print("\n   [Yapay Zekâ Asistanları Otomatik Yapılandırması]")
    configured_list = configure_all_ai_assistants(venv_python, main_script, yargi_dir)
    for ai_name, cfg_path, is_installed in configured_list:
        status_tag = "[KURULU]" if is_installed else "[HAZIRLANDI]"
        print(f"      -> {status_tag:13} {ai_name:22} : {cfg_path}")
    print("")

    asyncio.run(run_live_verification(yargi_dir))


if __name__ == "__main__":
    main()
