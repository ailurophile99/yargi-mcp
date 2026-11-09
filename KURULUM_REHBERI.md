# Yargı & UYAP Mevzuat MCP — Evrensel Kurulum Rehberi

Bu MCP sunucusu; **Claude Code (CLI)**, **Claude Desktop**, **Gemini (Antigravity)**, **ChatGPT (Codex)**, **OpenCode**, **Cline**, **Kimi Code**, **Hermes Agent** ve **Cursor** dahil olmak üzere popüler tüm yapay zekâ asistanlarıyla tam uyumludur.

---

## ⚡ 1. Yöntem: Tek Satırla Otomatik Kurulum (Önerilen)

Kurulum betiği bilgisayarınızdaki yapay zekâları tarayarak hepsini tek seferde otomatik yapılandırır.

### 🍎 macOS / Linux
**Terminal** uygulamasını açıp şu komutu yapıştırın:
```bash
curl -fsSL https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh | bash
```

### 🪟 Windows
**PowerShell** uygulamasını açıp şu komutu yapıştırın:
```powershell
irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
```

---

## 🤖 Otomatik Tanımlanan Yapay Zekâ Dosyaları

Betik çalıştırıldığında aşağıdaki konfigürasyonlar otomatik olarak güncellenir:

1. **Claude Code (CLI):**
   * Global: `~/.claude.json` (`mcpServers`) ve CLI `claude mcp add`
   * Proje: `.mcp.json`
2. **Claude Desktop:**
   * macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   * Windows: `%APPDATA%\Claude\claude_desktop_config.json`
3. **Gemini (Antigravity):**
   * `~/.gemini/config/mcp_config.json`
4. **ChatGPT (Codex):**
   * `~/.codex/config.toml` ve `~/.codex/mcp.json`
5. **OpenCode:**
   * `~/.config/opencode/opencode.json` (`mcp` formatı)
6. **Cline (VS Code, Cursor & CLI):**
   * `cline_mcp_settings.json` (tüm VS Code ve Cursor uzantı konumları)
7. **Kimi Code:**
   * `~/.kimi-code/mcp.json`
8. **Hermes Agent:**
   * `~/.hermes/config.yaml` (`mcp_servers` bloğu)
9. **Cursor:**
   * `~/.cursor/mcp.json`

---

## 📁 2. Yöntem: İndirilen Klasörden Çift Tıklamayla Kurulum

* **Windows:** Klasör içindeki `kurulum_windows.bat` dosyasına çift tıklayın.
* **macOS:** Klasör içindeki `kurulum_macos.command` dosyasına çift tıklayın.
