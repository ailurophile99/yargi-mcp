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

#### 1. Yol: İndir ve Çift Tıkla (En Kolay)
1. **[Yargi-MCP-Kurulum-Windows.zip dosyasını indirin](https://github.com/ailurophile99/yargi-mcp/releases/latest/download/Yargi-MCP-Kurulum-Windows.zip)**
2. ZIP'e sağ tıklayıp **"Tümünü ayıkla"** deyin, çıkan `kurulum_windows.bat` dosyasına **çift tıklayın**.
3. Mavi **"Windows bilgisayarınızı korudu"** ekranı çıkarsa: **"Ek bilgi" → "Yine de çalıştır"**.
4. Visual C++ için yönetici izni sorulursa **"Evet"** deyin. Pencere kurulum bitene kadar açık kalır.

> Doğrudan `.bat` indirmek isterseniz: [kurulum_windows.bat](https://github.com/ailurophile99/yargi-mcp/releases/latest/download/kurulum_windows.bat) (tarayıcı "tehlikeli olabilir" derse **"Sakla"** seçin).

#### 2. Yol: PowerShell Tek Satır
Başlat menüsüne **PowerShell** yazıp açın, şu satırı yapıştırıp **Enter**'a basın:
```powershell
irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
```

> Kurulum tekrar çalıştırılabilir: her seferinde en güncel sürüme günceller ve kaldığı yerden devam eder.

---

## 🤖 Otomatik Olarak Tanınan ve Yapılandırılan Yapay Zekâlar

Kurulum betiği aşağıdaki tüm ortamlara otomatik entegre olur:

| Yapay Zekâ / Araç | Yapılandırma Dosyası | Durum |
| :--- | :--- | :---: |
| **Claude Code (CLI)** | `~/.claude.json` ve `.mcp.json` | Otomatik |
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
* **Windows:** `kurulum_windows.bat` dosyasına çift tıklayın.
* **macOS:** `kurulum_macos.command` dosyasına sağ tıklayıp **Aç** deyin (macOS 15+: *Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç*). Terminal komutu bu adımları gerektirmediği için macOS'ta önerilen yoldur.

Her iki başlatıcı da tek başına indirilse bile çalışır; kurulum her zaman `~/yargi-mcp` (Windows: `C:\Users\<ad>\yargi-mcp`) klasörüne yapılır.

### Sorun Giderme
| Belirti | Çözüm |
| :--- | :--- |
| `.bat` açılıp hemen kapanıyor / hiç açılmıyor | ZIP'ten ayıkladıktan sonra çalıştırın veya PowerShell tek satır komutunu kullanın. |
| `claude : The term 'claude' is not recognized` | `claude mcp add` gerekmez; kurulum `~/.claude.json` dosyasını doğrudan günceller. Uygulamayı tamamen kapatıp açın. |
| Sunucu `0xC0000005` ile çöküyor | Kurulum Visual C++ çalışma zamanını otomatik kurar; izin verilmediyse [vc_redist.x64.exe](https://aka.ms/vs/17/release/vc_redist.x64.exe) kurup kurulumu tekrar çalıştırın. |
| Araçlar asistanda görünmüyor | Asistanı tamamen kapatıp açın (Claude: tepsi simgesi → Quit / macOS: Cmd+Q). Asistanı kurulumdan *sonra* yüklediyseniz kurulumu tekrar çalıştırın. |
| Ayar dosyam bozuldu mu? | Değiştirilen her dosyanın ilk hali `<dosya>.yargi-yedek` olarak saklanır. Okunamayan dosyalara hiç dokunulmaz. |

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
