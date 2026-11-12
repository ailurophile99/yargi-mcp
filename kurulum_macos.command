#!/usr/bin/env bash
# =============================================================================
# Yargı & UYAP Mevzuat MCP - macOS Çift Tıklama Başlatıcısı
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URL="https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.sh"

TMP_SCRIPT="$(mktemp "${TMPDIR:-/tmp}/yargi-install-XXXXXX")"
if curl -fsSL "$URL" -o "$TMP_SCRIPT"; then
    bash "$TMP_SCRIPT"
    RC=$?
elif [ -f "$SCRIPT_DIR/install.sh" ]; then
    echo "İnternetten alınamadı, yerel install.sh kullanılıyor..."
    bash "$SCRIPT_DIR/install.sh"
    RC=$?
else
    echo "HATA: Kurulum betiği indirilemedi. İnternet bağlantınızı kontrol edin."
    RC=1
fi
rm -f "$TMP_SCRIPT"

echo ""
read -r -n 1 -s -p "Pencereyi kapatmak için bir tuşa basın..." </dev/tty 2>/dev/null || true
echo ""
exit $RC
