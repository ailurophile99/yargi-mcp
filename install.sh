#!/usr/bin/env bash
# =============================================================================
# Yargı & UYAP Mevzuat MCP - macOS / Linux Kurulum Betiği
# Kullanım:
#   curl -fsSL https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh | bash
# =============================================================================
# Tüm betik bir fonksiyon içindedir: "curl | bash" ile çalışırken betiğin tamamı
# okunmadan hiçbir komut çalışmaz (yarım indirme / stdin tüketme sorunlarını önler).

yargi_install() {
    set -u
    local BOLD='\033[1m' CYAN='\033[0;36m' GREEN='\033[0;32m' YELLOW='\033[0;33m' RED='\033[0;31m' NC='\033[0m'
    step() { printf "\n${YELLOW}[%s/5] %s${NC}\n" "$1" "$2"; }
    info() { printf "      -> %s\n" "$1"; }
    ok()   { printf "${GREEN}      -> OK: %s${NC}\n" "$1"; }
    warn() { printf "${YELLOW}      -> UYARI: %s${NC}\n" "$1"; }
    fail() { printf "\n${RED}${BOLD}HATA: %s${NC}\n" "$1"; printf "${RED}Kurulumu tekrar çalıştırmak güvenlidir.${NC}\n"; return 1; }

    local REPO="ailurophile99/yargi-mcp" BRANCH="master"
    local REPO_URL="https://github.com/${REPO}.git"
    local TAR_URL="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH}"
    local YARGI_DIR="${YARGI_DIR:-$HOME/yargi-mcp}"
    export UV_LINK_MODE=copy PYTHONIOENCODING=utf-8 PYTHONUTF8=1

    printf "${CYAN}${BOLD}================================================================${NC}\n"
    printf "${CYAN}${BOLD}   Yargı & UYAP Mevzuat MCP - Otomatik Kurulum (macOS/Linux)${NC}\n"
    printf "${CYAN}${BOLD}================================================================${NC}\n"
    echo "   Kurulum klasörü: $YARGI_DIR"

    # Kullanılabilir git var mı? (macOS'ta /usr/bin/git, Xcode araçları yoksa kurulum penceresi açar)
    local HAS_GIT=0
    if command -v git >/dev/null 2>&1; then
        if [ "$(uname -s)" = "Darwin" ] && [ "$(command -v git)" = "/usr/bin/git" ]; then
            xcode-select -p >/dev/null 2>&1 && HAS_GIT=1
        else
            HAS_GIT=1
        fi
    fi

    fetch_tarball() {
        local tmp
        tmp="$(mktemp -d "${TMPDIR:-/tmp}/yargi-mcp-XXXXXX")" || return 1
        info "GitHub'dan arşiv indiriliyor..."
        curl -fL --progress-bar "$TAR_URL" -o "$tmp/src.tar.gz" </dev/null || { rm -rf "$tmp"; return 1; }
        mkdir -p "$tmp/x" "$YARGI_DIR"
        tar -xzf "$tmp/src.tar.gz" -C "$tmp/x" || { rm -rf "$tmp"; return 1; }
        local src
        src="$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
        cp -R "$src/." "$YARGI_DIR/"
        rm -rf "$tmp"
    }

    # ------------------------------------------------------------------ 1
    step 1 "MCP kaynak dosyaları hazırlanıyor"
    if [ -d "$YARGI_DIR" ] && [ ! -f "$YARGI_DIR/mcp_server_main.py" ] && [ ! -d "$YARGI_DIR/.git" ]; then
        local OLD="${YARGI_DIR}.eski-$(date +%Y%m%d-%H%M%S)"
        warn "Yarım kalmış eski kurulum bulundu, '$OLD' olarak kenara alınıyor."
        mv "$YARGI_DIR" "$OLD" || return 1
    fi

    if [ -d "$YARGI_DIR/.git" ]; then
        if [ "${YARGI_SKIP_UPDATE:-0}" = "1" ]; then
            info "Güncelleme atlandı (YARGI_SKIP_UPDATE=1)."
        elif [ "$HAS_GIT" = "1" ]; then
            info "Mevcut kurulum güncelleniyor..."
            if git -C "$YARGI_DIR" diff --quiet 2>/dev/null && git -C "$YARGI_DIR" diff --cached --quiet 2>/dev/null; then
                git -C "$YARGI_DIR" pull --ff-only --quiet origin "$BRANCH" </dev/null \
                    || warn "Güncelleme alınamadı, mevcut sürümle devam ediliyor."
            else
                warn "Klasörde yerel değişiklikler var; dokunulmadı, mevcut sürümle devam ediliyor."
            fi
        fi
    elif [ -f "$YARGI_DIR/mcp_server_main.py" ]; then
        if [ "${YARGI_SKIP_UPDATE:-0}" != "1" ]; then
            fetch_tarball || warn "Güncelleme indirilemedi, mevcut dosyalarla devam ediliyor."
        fi
    else
        local CLONED=0
        if [ "$HAS_GIT" = "1" ]; then
            info "GitHub'dan indiriliyor (git)..."
            git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$YARGI_DIR" </dev/null && CLONED=1
            [ "$CLONED" = "1" ] || rm -rf "$YARGI_DIR"
        fi
        [ "$CLONED" = "1" ] || fetch_tarball || { fail "Kaynak dosyalar indirilemedi. İnternet bağlantınızı kontrol edin."; return 1; }
    fi
    [ -f "$YARGI_DIR/mcp_server_main.py" ] || { fail "Kaynak dosyalar eksik: $YARGI_DIR"; return 1; }
    ok "Kaynak dosyalar hazır."

    # ------------------------------------------------------------------ 2
    step 2 "'uv' paket yöneticisi kontrol ediliyor"
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
    local UV_EXE=""
    UV_EXE="$(command -v uv 2>/dev/null || true)"
    if [ -z "$UV_EXE" ]; then
        info "'uv' bulunamadı, resmi kaynaktan (astral.sh) kuruluyor..."
        if command -v curl >/dev/null 2>&1; then
            curl -LsSf https://astral.sh/uv/install.sh </dev/null | sh
        else
            wget -qO- https://astral.sh/uv/install.sh </dev/null | sh
        fi
        hash -r 2>/dev/null || true
        UV_EXE="$(command -v uv 2>/dev/null || true)"
        [ -z "$UV_EXE" ] && [ -x "$HOME/.local/bin/uv" ] && UV_EXE="$HOME/.local/bin/uv"
    fi
    [ -n "$UV_EXE" ] || { fail "'uv' kurulamadı. İnternet bağlantınızı kontrol edin."; return 1; }
    ok "$UV_EXE ($("$UV_EXE" --version))"

    # ------------------------------------------------------------------ 3
    step 3 "Python 3.12 hazırlanıyor"
    "$UV_EXE" python install 3.12 </dev/null || { fail "Python 3.12 kurulamadı."; return 1; }
    ok "Python 3.12 hazır."

    # ------------------------------------------------------------------ 4
    step 4 "Python kütüphaneleri kuruluyor (ilk kurulumda 1-3 dakika sürebilir)"
    local VENV_PYTHON="$YARGI_DIR/.venv/bin/python"
    if [ -d "$YARGI_DIR/.venv" ] && ! "$VENV_PYTHON" -c "import sys" >/dev/null 2>&1; then
        info "Bozuk sanal ortam temizleniyor..."
        rm -rf "$YARGI_DIR/.venv"
    fi
    ( cd "$YARGI_DIR" && { "$UV_EXE" sync --frozen --python 3.12 </dev/null \
        || { warn "Kilitli sürümlerle kurulum başarısız, yeniden deneniyor..."; "$UV_EXE" sync --python 3.12 </dev/null; }; } ) \
        || { fail "Python kütüphaneleri kurulamadı."; return 1; }
    [ -x "$VENV_PYTHON" ] || { fail "Sanal ortam oluşturulamadı ($VENV_PYTHON)."; return 1; }
    ok "Tüm kütüphaneler kuruldu."

    # ------------------------------------------------------------------ 5
    step 5 "Sunucu testi ve yapay zekâ asistanları yapılandırması"
    "$VENV_PYTHON" "$YARGI_DIR/setup_helper.py" "$YARGI_DIR" "$VENV_PYTHON" </dev/null
    local HELPER_RC=$?

    echo ""
    if [ "$HELPER_RC" = "0" ]; then
        printf "${GREEN}${BOLD}================================================================${NC}\n"
        printf "${GREEN}${BOLD}  ✔ KURULUM BAŞARIYLA TAMAMLANDI${NC}\n"
        printf "${GREEN}${BOLD}================================================================${NC}\n"
        echo "  Kullandığınız yapay zekâ uygulamasını TAMAMEN kapatıp açın"
        echo "  (Claude Desktop için: Cmd+Q). Ardından doğrudan sorun:"
        echo "  \"Yargıtay'da kira tespit kararlarını ara\""
        return 0
    fi
    fail "Kurulum tamamlanamadı - yukarıdaki [HATA] satırlarına bakın."
    return 1
}

yargi_install "$@"
