# =============================================================================
# Yargi & UYAP Mevzuat MCP - Windows PowerShell baslaticisi
# Sag tik > "PowerShell ile calistir" veya: powershell -ExecutionPolicy Bypass -File kurulum_windows.ps1
# =============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
$tmp = Join-Path $env:TEMP ("yargi_install_" + [guid]::NewGuid().ToString() + ".ps1")
try {
    $wc = New-Object Net.WebClient
    $wc.Encoding = [System.Text.Encoding]::UTF8
    $wc.DownloadFile('https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1', $tmp)
    & $tmp
} catch {
    $local = Join-Path $PSScriptRoot 'install.ps1'
    if (Test-Path $local) { & $local } else { Write-Host "Kurulum betigi indirilemedi: $($_.Exception.Message)" -ForegroundColor Red }
} finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
Write-Host ""
Read-Host "Kapatmak icin Enter'a basin" | Out-Null
