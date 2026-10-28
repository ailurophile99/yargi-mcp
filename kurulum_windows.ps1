# =============================================================================
# Yargı & UYAP Mevzuat MCP - Windows Çift Tıklama Başlatıcısı
# =============================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
& (Join-Path $ScriptDir "install.ps1")
