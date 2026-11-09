# =============================================================================
# Yargı & UYAP Mevzuat MCP - Windows PowerShell Başlatıcısı
# =============================================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }
$LocalInstall = Join-Path $ScriptDir "install.ps1"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

if (Test-Path $LocalInstall) {
    & $LocalInstall
} else {
    irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
}
