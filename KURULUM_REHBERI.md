# Yargı & UYAP Mevzuat MCP — Evrensel Kurulum Rehberi

Bu MCP sunucusu; **Claude Desktop**, **Gemini (Antigravity)**, **ChatGPT (Codex)**, **OpenCode**, **Cline**, **Kimi Code**, **Hermes Agent** ve **Cursor** dahil olmak üzere popüler tüm yapay zekâ asistanlarıyla tam uyumludur.

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

1. **Claude Desktop:**
   * macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   * Windows: `%APPDATA%\Claude\claude_desktop_config.json`
2. **Gemini (Antigravity):**
   * `~/.gemini/config/mcp_config.json`
3. **ChatGPT (Codex):**
   * `~/.codex/config.toml` ve `~/.codex/mcp.json`
4. **OpenCode:**
   * `~/.config/opencode/opencode.json` (`mcp` formatı)
5. **Cline (VS Code, Cursor & CLI):**
   * `cline_mcp_settings.json` (tüm VS Code ve Cursor uzantı konumları)
6. **Kimi Code:**
   * `~/.kimi-code/mcp.json`
7. **Hermes Agent:**
   * `~/.hermes/config.yaml` (`mcp_servers` bloğu)
8. **Cursor:**
   * `~/.cursor/mcp.json`

---

## 📁 2. Yöntem: İndirilen Klasörden Çift Tıklamayla Kurulum

* **Windows:** Klasör içindeki `kurulum_windows.bat` dosyasına çift tıklayın.
* **macOS:** Klasör içindeki `kurulum_macos.command` dosyasına çift tıklayın.
