# =============================================================================
# Yargi & UYAP Mevzuat MCP - Windows PowerShell baslaticisi
# Sag tik > "PowerShell ile calistir" veya: powershell -ExecutionPolicy Bypass -File kurulum_windows.ps1
# =============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
try {
    $script = (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1')
    . ([ScriptBlock]::Create($script))
} catch {
    $local = Join-Path $PSScriptRoot 'install.ps1'
    if (Test-Path $local) { . $local } else { Write-Host "Kurulum betigi indirilemedi: $($_.Exception.Message)" -ForegroundColor Red }
}
Write-Host ""
Read-Host "Kapatmak icin Enter'a basin" | Out-Null
