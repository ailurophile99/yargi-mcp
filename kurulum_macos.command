#!/usr/bin/env bash
# =============================================================================
# Yargı & UYAP Mevzuat MCP - macOS Çift Tıklama Başlatıcısı
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export YARGI_DIR="$SCRIPT_DIR"
exec "$SCRIPT_DIR/install.sh"
