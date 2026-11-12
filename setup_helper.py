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


# =============================================================================
# Güvenli yapılandırma dosyası yazımı
# =============================================================================
SERVER_NAME = "yargi-ve-mevzuat-mcp"


def _strip_jsonc(raw: str) -> str:
    """// ve /* */ yorumlarını ve sondaki virgülleri temizler (string içlerine dokunmadan)."""
    out, i, n, in_str, esc = [], 0, len(raw), False, False
    while i < n:
        c = raw[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
        elif raw.startswith("//", i):
            while i < n and raw[i] not in "\r\n":
                i += 1
        elif raw.startswith("/*", i):
            end = raw.find("*/", i + 2)
            i = n if end == -1 else end + 2
        else:
            out.append(c)
            i += 1
    import re
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))


def _load_json(path: pathlib.Path):
    """Dosyayı okur. Okunamıyorsa None döner (bu durumda dosyaya ASLA dokunulmaz)."""
    if not path.exists() or path.stat().st_size == 0:
        return {}
    try:
        raw = path.read_text(encoding="utf-8-sig")
    except Exception:
        return None
    for candidate in (raw, None):
        try:
            data = json.loads(candidate if candidate is not None else _strip_jsonc(raw))
            return data if isinstance(data, dict) else None
        except Exception:
            continue
    return None


def _backup_once(path: pathlib.Path) -> None:
    """İlk değişiklikten önce dosyanın yedeğini alır (<dosya>.yargi-yedek)."""
    if path.exists():
        bak = path.with_name(path.name + ".yargi-yedek")
        if not bak.exists():
            try:
                shutil.copy2(path, bak)
            except Exception:
                pass


def _atomic_write(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".yargi-tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def configure_json_file(file_path: pathlib.Path, key_name: str, server_key: str, server_data: dict):
    """JSON yapılandırmasını diğer ayarları ezmeden günceller. (başarılı_mı, açıklama) döner."""
    try:
        data = _load_json(file_path)
        if data is None:
            return False, "dosya okunamadı (bozuk/özel format) - güvenlik için dokunulmadı"
        section = data.get(key_name)
        if not isinstance(section, dict):
            section = {}
        if section.get(server_key) == server_data:
            return True, "zaten güncel"
        section[server_key] = server_data
        data[key_name] = section
        _backup_once(file_path)
        _atomic_write(file_path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        return True, "güncellendi"
    except Exception as e:  # noqa: BLE001
        return False, f"yazılamadı: {e}"


def _toml_str(s: str) -> str:
    # JSON string kaçışları TOML temel string'leri ile uyumludur (Windows ters eğik çizgileri güvenli).
    return json.dumps(str(s), ensure_ascii=False)


def configure_codex_toml(toml_path: pathlib.Path, venv_python: str, main_script: str, yargi_dir: str):
    """Codex ~/.codex/config.toml: [mcp_servers.<ad>] bloğunu ekler; eski/hatalı blokları temizler."""
    try:
        text = toml_path.read_text(encoding="utf-8-sig") if toml_path.exists() else ""
        ours = {
            f"mcpServers.{SERVER_NAME}", f'mcpServers."{SERVER_NAME}"',
            f"mcp_servers.{SERVER_NAME}", f'mcp_servers."{SERVER_NAME}"',
            f"mcp_servers.{SERVER_NAME}.env", f'mcp_servers."{SERVER_NAME}".env',
            f"mcpServers.{SERVER_NAME}.env",
        }
        kept, skipping = [], False
        for line in text.splitlines():
            s = line.strip()
            if s.startswith("[") and s.endswith("]"):
                header = s.strip("[]").strip()
                skipping = header in ours
            if not skipping:
                kept.append(line)
        block = "\n".join([
            f"[mcp_servers.{SERVER_NAME}]",
            f"command = {_toml_str(venv_python)}",
            f"args = [{_toml_str(main_script)}]",
            f"cwd = {_toml_str(yargi_dir)}",
            "startup_timeout_sec = 120",
            "tool_timeout_sec = 180",
            "",
            f"[mcp_servers.{SERVER_NAME}.env]",
            'PYTHONIOENCODING = "utf-8"',
            'PYTHONUTF8 = "1"',
            f"PYTHONPATH = {_toml_str(yargi_dir)}",
        ])
        new_text = ("\n".join(kept).rstrip() + "\n\n" if "".join(kept).strip() else "") + block + "\n"
        if new_text == text:
            return True, "zaten güncel"
        _backup_once(toml_path)
        _atomic_write(toml_path, new_text)
        return True, "güncellendi"
    except Exception as e:  # noqa: BLE001
        return False, f"yazılamadı: {e}"


def configure_all_ai_assistants(venv_python: str, main_script: str, yargi_dir: pathlib.Path) -> list:
    """
    Bilgisayarda YÜKLÜ / TESPİT EDİLEN yapay zekâ asistanlarını yapılandırır.
    Yüklü olmayan araçlar için klasör veya dosya oluşturmaz.
    Dönüş: [(asistan_adı, dosya_yolu, başarılı_mı, açıklama), ...]
    """
    home = pathlib.Path.home()
    is_win = sys.platform == "win32"
    appdata = pathlib.Path(os.environ.get("APPDATA") or (home / "AppData" / "Roaming"))
    localappdata = pathlib.Path(os.environ.get("LOCALAPPDATA") or (home / "AppData" / "Local"))
    ydir = str(yargi_dir)

    env = {"PYTHONIOENCODING": "utf-8", "PYTHONUTF8": "1", "PYTHONPATH": ydir}
    std_server = {"command": str(venv_python), "args": [str(main_script)], "env": dict(env)}
    claude_code_server = {"type": "stdio", **std_server}
    cwd_server = {**std_server, "cwd": ydir}

    results = []

    def add(label, path, ok_msg):
        ok, msg = ok_msg
        results.append((label, str(path), ok, msg))

    # 1. Claude Desktop (Chat sekmesi) - klasik kurulum + Microsoft Store (MSIX) kurulumu
    if is_win:
        desktop_cfgs = [appdata / "Claude" / "claude_desktop_config.json"]
        pkgs = localappdata / "Packages"
        if pkgs.exists():
            for p in pkgs.glob("Claude_*"):
                desktop_cfgs.append(p / "LocalCache" / "Roaming" / "Claude" / "claude_desktop_config.json")
    else:
        desktop_cfgs = [home / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"]
    claude_desktop_installed = False
    for cfg in desktop_cfgs:
        if cfg.parent.exists():
            claude_desktop_installed = True
            add("Claude Desktop (Chat)", cfg, configure_json_file(cfg, "mcpServers", SERVER_NAME, std_server))

    # 2. Claude Code (CLI + Claude Desktop 'Code' sekmesi) -> ~/.claude.json
    #    'claude mcp add' komutuna (ve dolayısıyla Node.js'e) gerek yoktur; dosya doğrudan güncellenir.
    claude_code_cfg = home / ".claude.json"
    if claude_code_cfg.exists() or (home / ".claude").exists() or shutil.which("claude") or claude_desktop_installed:
        add("Claude Code (CLI/Code)", claude_code_cfg,
            configure_json_file(claude_code_cfg, "mcpServers", SERVER_NAME, claude_code_server))

    # 3. Gemini / Antigravity
    gemini_dir = home / ".gemini"
    if gemini_dir.exists():
        targets = [gemini_dir / "config" / "mcp_config.json"]
        if (gemini_dir / "antigravity").exists():
            targets.append(gemini_dir / "antigravity" / "mcp_config.json")
        for cfg in targets:
            add("Antigravity (Gemini)", cfg, configure_json_file(cfg, "mcpServers", SERVER_NAME, cwd_server))
        gemini_cli = gemini_dir / "settings.json"
        if gemini_cli.exists():
            add("Gemini CLI", gemini_cli,
                configure_json_file(gemini_cli, "mcpServers", SERVER_NAME, {**cwd_server, "timeout": 180000}))

    # 4. ChatGPT (Codex) -> ~/.codex/config.toml  ([mcp_servers.*] biçimi)
    codex_dir = home / ".codex"
    if codex_dir.exists():
        cfg = codex_dir / "config.toml"
        add("ChatGPT (Codex)", cfg, configure_codex_toml(cfg, str(venv_python), str(main_script), ydir))

    # 5. OpenCode
    opencode_cfg = (appdata / "opencode" / "opencode.json") if is_win else (home / ".config" / "opencode" / "opencode.json")
    if not opencode_cfg.parent.exists() and is_win and (home / ".config" / "opencode").exists():
        opencode_cfg = home / ".config" / "opencode" / "opencode.json"
    if opencode_cfg.parent.exists():
        add("OpenCode", opencode_cfg, configure_json_file(opencode_cfg, "mcp", SERVER_NAME, {
            "type": "local",
            "command": [str(venv_python), str(main_script)],
            "environment": dict(env),
            "enabled": True,
        }))

    # 6. Cline (VS Code, Cursor, CLI)
    cline_server = {**std_server, "disabled": False, "autoApprove": []}
    base = appdata if is_win else (home / "Library" / "Application Support")
    cline_paths = [
        (base / "Code" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (VS Code)"),
        (base / "Cursor" / "User" / "globalStorage" / "saoudrizwan.claude-dev" / "settings" / "cline_mcp_settings.json", "Cline (Cursor)"),
        (home / ".cline" / "data" / "settings" / "cline_mcp_settings.json", "Cline (CLI)"),
    ]
    for c_path, c_label in cline_paths:
        if c_path.parent.exists():
            add(c_label, c_path, configure_json_file(c_path, "mcpServers", SERVER_NAME, cline_server))

    # 7. Kimi Code
    kimi_dir = home / ".kimi-code"
    if kimi_dir.exists():
        cfg = kimi_dir / "mcp.json"
        add("Kimi Code", cfg, configure_json_file(cfg, "mcpServers", SERVER_NAME, std_server))

    # 8. Hermes Agent
    hermes_dir = home / ".hermes"
    if hermes_dir.exists():
        cfg = hermes_dir / "config.yaml"
        try:
            import yaml
            h_data = {}
            if cfg.exists() and cfg.stat().st_size > 0:
                h_data = yaml.safe_load(cfg.read_text(encoding="utf-8"))
                if not isinstance(h_data, dict):
                    raise ValueError("beklenmeyen YAML yapısı")
            servers = h_data.get("mcp_servers") if isinstance(h_data.get("mcp_servers"), dict) else {}
            if servers.get(SERVER_NAME) == std_server:
                add("Hermes Agent", cfg, (True, "zaten güncel"))
            else:
                servers[SERVER_NAME] = dict(std_server)
                h_data["mcp_servers"] = servers
                _backup_once(cfg)
                _atomic_write(cfg, yaml.safe_dump(h_data, sort_keys=False, allow_unicode=True))
                add("Hermes Agent", cfg, (True, "güncellendi"))
        except Exception as e:  # noqa: BLE001
            add("Hermes Agent", cfg, (False, f"dokunulmadı: {e}"))

    # 9. Cursor
    cursor_dir = home / ".cursor"
    if cursor_dir.exists():
        cfg = cursor_dir / "mcp.json"
        add("Cursor", cfg, configure_json_file(cfg, "mcpServers", SERVER_NAME, std_server))

    # 10. Proje içi .mcp.json (git tarafından yok sayılır)
    configure_json_file(yargi_dir / ".mcp.json", "mcpServers", SERVER_NAME, claude_code_server)

    return results


# =============================================================================
# Doğrulama
# =============================================================================
WIN_ACCESS_VIOLATION = (3221225477, -1073741819)  # 0xC0000005


def check_server_import(venv_python: str, yargi_dir: pathlib.Path) -> bool:
    """Sunucu modülünün ayrı bir süreçte çökmeden yüklenebildiğini doğrular."""
    env = dict(os.environ, PYTHONIOENCODING="utf-8", PYTHONUTF8="1", PYTHONPATH=str(yargi_dir))
    try:
        proc = subprocess.run(
            [venv_python, "-c", "import mcp_server_main; print('OK')"],
            cwd=str(yargi_dir), env=env, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=300,
        )
    except subprocess.TimeoutExpired:
        print("      -> [UYARI] Sunucu yüklemesi 5 dakikada tamamlanamadı (antivirüs taraması olabilir).")
        return False
    if proc.returncode == 0:
        print("      -> [OK] MCP sunucusu çökmeden yükleniyor.")
        return True
    print(f"      -> [HATA] MCP sunucusu yüklenemedi (çıkış kodu: {proc.returncode}).")
    if proc.returncode in WIN_ACCESS_VIOLATION:
        print("         Windows erişim ihlali (0xC0000005): Microsoft Visual C++ Redistributable eksik/eski.")
        print("         Çözüm: https://aka.ms/vs/17/release/vc_redist.x64.exe indirip kurun, sonra kurulumu tekrar çalıştırın.")
    tail = (proc.stderr or "").strip().splitlines()[-8:]
    for line in tail:
        print("         " + line)
    return False


async def run_live_verification(yargi_dir: pathlib.Path) -> None:
    """UYAP Mevzuat ve Bedesten İçtihat API'lerine canlı doğrulama testi yapar."""
    if str(yargi_dir) not in sys.path:
        sys.path.insert(0, str(yargi_dir))
    import logging
    logging.disable(logging.WARNING)  # Test sırasında sunucunun ayrıntılı günlüklerini gizle
    import mcp_server_main as m

    res_mevzuat = await m.mevzuat_ara(
        query="", phrase="", mevzuat_turu="KANUN", mevzuat_no="6098",
        baslangic_tarihi="", bitis_tarihi="", sayfa=1, sayfa_boyutu=1,
    )
    if not res_mevzuat.get("results"):
        raise RuntimeError("UYAP Mevzuat: 6098 sayılı kanun bulunamadı.")
    first = res_mevzuat["results"][0]
    print(f"      -> [TEST 1 OK] UYAP Mevzuat: {first['mevzuat_adi']} (ID: {first['mevzuat_id']})")

    app = m.create_app()
    res_bedesten = await app.call_tool(
        "search_bedesten_unified",
        {"phrase": "kira", "court_types": ["YARGITAYKARARI", "DANISTAYKARAR"]},
    )
    if not res_bedesten:
        raise RuntimeError("UYAP Bedesten İçtihat yanıt vermedi.")
    print("      -> [TEST 2 OK] Yargıtay & Danıştay Bedesten API bağlantısı aktif.")


def main() -> None:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace", line_buffering=True)
        except Exception:
            pass

    if len(sys.argv) < 3:
        print("Kullanım: python setup_helper.py <yargi_mcp_dir> <venv_python_path>")
        sys.exit(1)

    yargi_dir = pathlib.Path(sys.argv[1]).resolve()
    venv_python = str(pathlib.Path(sys.argv[2]).absolute())
    main_script = str(yargi_dir / "mcp_server_main.py")

    ensure_mevzuat_enhancements(yargi_dir)

    print("   [1] MCP sunucusu yükleme testi")
    server_ok = check_server_import(venv_python, yargi_dir)

    print("\n   [2] Yapay zekâ asistanları yapılandırılıyor")
    configured = configure_all_ai_assistants(venv_python, main_script, yargi_dir)
    if not configured:
        print("      -> Desteklenen bir yapay zekâ asistanı bulunamadı.")
        print("         Asistanı kurduktan sonra bu kurulumu tekrar çalıştırmanız yeterli.")
    for name, path, ok, msg in configured:
        tag = "[OK]  " if ok else "[ATLA]"
        print(f"      -> {tag} {name:24} {msg:14} {path}")

    print("\n   [3] Canlı UYAP bağlantı testi")
    if server_ok:
        try:
            asyncio.run(run_live_verification(yargi_dir))
        except Exception as e:  # noqa: BLE001
            print(f"      -> [UYARI] Canlı test tamamlanamadı: {e}")
            print("         (Devlet sunucuları geçici olarak yanıt vermiyor olabilir; kurulum yine de tamamdır.)")
    else:
        print("      -> Sunucu yüklenemediği için atlandı.")

    # Çıkışta sunucunun temizlik günlükleri kullanıcıyı yanıltmasın
    import logging
    logging.disable(logging.CRITICAL)
    sys.stdout.flush()
    os._exit(0 if server_ok else 2)


if __name__ == "__main__":
    main()
