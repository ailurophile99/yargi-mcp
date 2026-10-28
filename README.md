# Yargı & UYAP Mevzuat MCP Sunucusu

Türk yargı kararlarına (**Yargıtay, Danıştay, UYAP Emsal, Bölge Adliye / İstinaf Mahkemeleri, Yerel Mahkemeler, Anayasa Mahkemesi, Uyuşmazlık Mahkemesi, Sayıştay, AİHM**) ve **UYAP Mevzuat / Resmî Gazete** sistemlerine (**Kanun, Yönetmelik, Tebliğ, CBK, KHK, Tüzük**) doğrudan ve ücretsiz erişim sağlayan yerel **Model Context Protocol (MCP)** sunucusudur.

---

## ⚡ Tek Satırla Evrensel Kurulum (Windows & macOS)

Hangi yapay zekâyı kullanırsanız kullanın, terminalinize tek bir satır yapıştırmanız yeterlidir. Kurulum motoru bilgisayarınızdaki asistanları **otomatik tespit eder** ve MCP ayarlarını anında tanımlar:

### 🍎 macOS / Linux
Terminal uygulamasını açın ve şu tek satırı yapıştırıp **Enter**'a basın:
```bash
curl -fsSL https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh | bash
```

### 🪟 Windows
PowerShell uygulamasını açın ve şu tek satırı yapıştırıp **Enter**'a basın:
```powershell
irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
```

---

## 🤖 Otomatik Olarak Tanınan ve Yapılandırılan Yapay Zekâlar

Kurulum betiği aşağıdaki tüm ortamlara otomatik entegre olur:

| Yapay Zekâ / Araç | Yapılandırma Dosyası | Durum |
| :--- | :--- | :---: |
| **Claude Desktop** | `claude_desktop_config.json` | Otomatik |
| **Gemini (Antigravity)** | `~/.gemini/config/mcp_config.json` | Otomatik |
| **ChatGPT (Codex)** | `~/.codex/config.toml` & `mcp.json` | Otomatik |
| **OpenCode** | `opencode.json` (`mcp` bloğu) | Otomatik |
| **Cline** (VS Code, Cursor & CLI) | `cline_mcp_settings.json` | Otomatik |
| **Kimi Code** | `~/.kimi-code/mcp.json` | Otomatik |
| **Hermes Agent** | `~/.hermes/config.yaml` (`mcp_servers`) | Otomatik |
| **Cursor** | `~/.cursor/mcp.json` | Otomatik |

> *Bir asistanı henüz kurmamış olsanız bile yapılandırması önceden hazırlandığı için, gelecekte o asistanı kurup açtığınızda Yargı MCP sunucusu doğrudan çalışmaya hazır olacaktır.*

---

## 🛠️ Alternatif Kurulum Yolları

### Klasörden Çift Tıklamayla Kurulum
Depoyu ZIP olarak indirdiyseniz veya klonladıysanız:
* **Windows:** `kurulum_windows.bat` dosyasına çift tıklayın.
* **macOS:** `kurulum_macos.command` dosyasına çift tıklayın.

### `uvx` İle Doğrudan Çalıştırma
```json
{
  "mcpServers": {
    "yargi-ve-mevzuat-mcp": {
      "command": "uvx",
      "args": [
        "--from",
        "git+https://github.com/ailurophile99/yargi-mcp",
        "yargi-mcp"
      ]
    }
  }
}
```

---

## Özellikler (55 Araç)

* **UYAP Mevzuat (`bedesten.adalet.gov.tr/mevzuat`):**
  * `mevzuat_ara`: Kanun, yönetmelik, tebliğ, KHK, CBK ve tüzüklerde başlık veya tam metin (`phrase`) araması.
  * `mevzuat_madde_agaci`: Kanun ve yönetmeliklerin bölüm/madde ağacını (içindekiler) getirme.
  * `mevzuat_madde_getir`: Sadece ilgili tek bir kanun/yönetmelik maddesini çekme (yüksek token tasarrufu).
  * `get_mevzuat_document` & `mevzuat_icinde_ara`: Mevzuat tam metni ve mevzuat içi kavram arama.
* **Yüksek Yargı ve Emsal Kararlar:**
  * **Bedesten Birleşik İçtihat API:** Yargıtay, Danıştay, İstinaf (BAM), Yerel Hukuk ve Kanun Yararına Bozma kararları (`ictihat_ara`, `ictihat_getir`, `karar_atif_zinciri`, `search_bedesten_unified`, `get_bedesten_document_markdown`).
  * **Yargıtay & Danıştay Resmi API:** Daire/kurul filtreli detaylı arama (`search_yargitay_detailed`, `search_danistay_detailed`).
  * **UYAP Emsal:** `search_emsal_detailed_decisions`, `get_emsal_document_markdown`.
  * **Anayasa Mahkemesi, Uyuşmazlık Mahkemesi, Sayıştay, AİHM (HUDOC) ve Resmî Gazete.**
* **Düzenleyici Kurum Kararları:**
  * KİK, Rekabet Kurumu, KVKK, BDDK, BTK, SPK, EPDK, HSK, KDK, TBB, GİB Özelgeleri, Sigorta Tahkim Komisyonu, Reklam Kurulu.
