#!/usr/bin/env bash
# =============================================================================
# Yargı & UYAP Mevzuat MCP - macOS Çift Tıklama Başlatıcısı
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "   Yargı ve UYAP Mevzuat MCP - macOS Kurulum Başlatılıyor...    "
echo "================================================================"
echo ""

if [ -f "$SCRIPT_DIR/install.sh" ]; then
    echo "[1/2] Yerel kurulum betiği çalıştırılıyor..."
    export YARGI_DIR="$SCRIPT_DIR"
    chmod +x "$SCRIPT_DIR/install.sh" 2>/dev/null || true
    exec "$SCRIPT_DIR/install.sh"
else
    echo "[BİLGİ] Yerel kurulum betiği bulunamadı (tek dosya indirildi)."
    echo "        Güncel kurulum GitHub üzerinden otomatik başlatılıyor..."
    echo ""
    curl -fsSL https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh | bash
fi

