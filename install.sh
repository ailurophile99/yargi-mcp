#!/usr/bin/env bash
# =============================================================================
# Yargı & UYAP Mevzuat MCP - macOS / Linux Tek Satırlık Kurulum Betiği
# Kullanım:
#   curl -fsSL https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh | bash
# =============================================================================
set -e

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}================================================================${NC}"
echo -e "${CYAN}${BOLD}   Yargı & UYAP Mevzuat MCP - Tek Satırlık Kurulum (macOS/Linux)${NC}"
echo -e "${CYAN}${BOLD}================================================================${NC}"
echo ""

# Hedef kurulum dizini
YARGI_DIR="${YARGI_DIR:-$HOME/yargi-mcp}"

# 1. ADIM: Deponun İndirilmesi veya Güncellenmesi
echo -e "${YELLOW}[1/5] MCP kaynak dosyaları hazırlanıyor (${YARGI_DIR})...${NC}"

if [ -d "$YARGI_DIR/.git" ]; then
    echo -e "      -> Mevcut kurulum tespit edildi, güncelleniyor..."
    git -C "$YARGI_DIR" pull --ff-only 2>/dev/null || true
elif [ -d "$YARGI_DIR" ] && [ -f "$YARGI_DIR/mcp_server_main.py" ]; then
    echo -e "      -> Yerel dosyalar mevcut."
else
    if command -v git >/dev/null 2>&1; then
        echo -e "      -> GitHub üzerinden klonlanıyor..."
        git clone https://github.com/ailurophile99/yargi-mcp.git "$YARGI_DIR"
    else
        echo -e "      -> Git bulunamadı, arşiv indirilip açılıyor..."
        TMP_ZIP="$(mktemp /tmp/yargi-mcp-XXXXXX.zip)"
        TMP_DIR="$(mktemp -d /tmp/yargi-mcp-XXXXXX)"
        curl -fsSL "https://api.github.com/repos/ailurophile99/yargi-mcp/zipball/master" -o "$TMP_ZIP"
        unzip -q "$TMP_ZIP" -d "$TMP_DIR"
        FIRST_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        mkdir -p "$YARGI_DIR"
        cp -R "$FIRST_DIR/"* "$YARGI_DIR/"
        rm -rf "$TMP_ZIP" "$TMP_DIR"
    fi
fi
echo -e "${GREEN}      -> OK: Kaynak dosyalar hazır.${NC}"

# 2. ADIM: uv Paket Yöneticisi Kontrolü ve Kurulumu
echo -e "${YELLOW}[2/5] 'uv' paket yöneticisi kontrol ediliyor...${NC}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if command -v uv >/dev/null 2>&1; then
    UV_EXE="$(command -v uv)"
else
    echo -e "      -> 'uv' bulunamadı. Resmi kaynaktan (https://astral.sh/uv) kuruluyor..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if command -v uv >/dev/null 2>&1; then
        UV_EXE="$(command -v uv)"
    else
        echo -e "${RED}HATA: 'uv' kurulamadı. İnternet bağlantınızı kontrol edin.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}      -> OK: $UV_EXE ($("$UV_EXE" --version))${NC}"

# 3. ADIM: Python 3.12 Çalışma Ortamı
echo -e "${YELLOW}[3/5] Python 3.12 çalışma ortamı kontrol ediliyor...${NC}"
"$UV_EXE" python install 3.12
echo -e "${GREEN}      -> OK: Python 3.12 hazır.${NC}"

# 4. ADIM: Sanal Ortam (.venv) ve Kütüphaneler
echo -e "${YELLOW}[4/5] Python sanal ortamı (.venv) ve bağımlılıklar senkronize ediliyor...${NC}"
cd "$YARGI_DIR"
"$UV_EXE" sync --python 3.12

VENV_PYTHON="$YARGI_DIR/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ]; then
    echo -e "${RED}HATA: Sanal ortam Python çalıştırılabilir dosyası bulunamadı ($VENV_PYTHON).${NC}"
    exit 1
fi
echo -e "${GREEN}      -> OK: Tüm bağımlılıklar kuruldu.${NC}"

# 5. ADIM: MCP Yapılandırması ve Canlı Bağlantı Testi
echo -e "${YELLOW}[5/5] Tüm Yapay Zekâ Asistanları (Claude, Gemini, ChatGPT/Codex, OpenCode, Cline, Kimi, Hermes) otomatik yapılandırılıyor ve canlı UYAP testi yapılıyor...${NC}"
PYTHONIOENCODING="utf-8" "$VENV_PYTHON" "$YARGI_DIR/setup_helper.py" "$YARGI_DIR" "$VENV_PYTHON"

echo ""
echo -e "${GREEN}${BOLD}================================================================${NC}"
echo -e "${GREEN}${BOLD} ✔ KURULUM BAŞARIYLA TAMAMLANDI!                               ${NC}"
echo -e "${GREEN}${BOLD}   Kullandığınız yapay zekâ asistanını (Claude Desktop,        ${NC}"
echo -e "${GREEN}${BOLD}   Gemini Antigravity, ChatGPT Codex, OpenCode, Cline, Kimi,   ${NC}"
echo -e "${GREEN}${BOLD}   Hermes Agent veya Cursor) yeniden başlatıp hemen kullanın.  ${NC}"
echo -e "${GREEN}${BOLD}================================================================${NC}"
