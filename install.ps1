# =============================================================================
# Yargı & UYAP Mevzuat MCP - Windows PowerShell Tek Satırlık Kurulum Betiği
# Kullanım (PowerShell'e yapıştırıp Enter'a basmanız yeterlidir):
#   irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
# =============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   Yargı & UYAP Mevzuat MCP - Tek Satırlık Kurulum (Windows)    " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$TargetDir = Join-Path $env:USERPROFILE "yargi-mcp"

# 1. ADIM: Deponun İndirilmesi veya Güncellenmesi
Write-Host "[1/5] MCP kaynak dosyaları hazırlanıyor ($TargetDir)..." -ForegroundColor Yellow

if (Test-Path (Join-Path $TargetDir ".git")) {
    Write-Host "      -> Mevcut kurulum tespit edildi, güncelleniyor..." -ForegroundColor Cyan
    try {
        git -C $TargetDir pull --ff-only 2>$null
    } catch {
        # git pull hatası kurulumu engellemesin
    }
} elseif ((Test-Path $TargetDir) -and (Test-Path (Join-Path $TargetDir "mcp_server_main.py"))) {
    Write-Host "      -> Yerel dosyalar mevcut." -ForegroundColor Green
} else {
    $hasGit = $false
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) { $hasGit = $true }
    } catch { }

    if ($hasGit) {
        Write-Host "      -> GitHub üzerinden klonlanıyor..." -ForegroundColor Cyan
        git clone https://github.com/ailurophile99/yargi-mcp.git $TargetDir
    } else {
        Write-Host "      -> Git bulunamadı, arşiv indirilip açılıyor..." -ForegroundColor Cyan
        $ZipPath = Join-Path $env:TEMP "yargi-mcp-$([System.Guid]::NewGuid().ToString()).zip"
        $ExtractDir = Join-Path $env:TEMP "yargi-extracted-$([System.Guid]::NewGuid().ToString())"
        Invoke-WebRequest -Uri "https://api.github.com/repos/ailurophile99/yargi-mcp/zipball/master" -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force
        $FirstFolder = Get-ChildItem -Path $ExtractDir | Select-Object -First 1
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        Move-Item -Path $FirstFolder.FullName -Destination $TargetDir
        Remove-Item -Recurse -Force $ExtractDir, $ZipPath -ErrorAction SilentlyContinue
    }
}
Write-Host "      -> OK: Kaynak dosyalar hazır." -ForegroundColor Green

# 2. ADIM: uv Paket Yöneticisi Kontrolü ve Kurulumu
Write-Host "[2/5] 'uv' paket yöneticisi kontrol ediliyor..." -ForegroundColor Yellow

$UvExe = $null
$PossibleUvPaths = @(
    (Get-Command uv -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    "$env:USERPROFILE\.local\bin\uv.exe",
    "$env:USERPROFILE\.cargo\bin\uv.exe",
    "$env:LOCALAPPDATA\uv\uv.exe"
)

foreach ($p in $PossibleUvPaths) {
    if ($p -and (Test-Path $p)) {
        $UvExe = $p
        break
    }
}

if (-not $UvExe) {
    Write-Host "      -> 'uv' bulunamadı. Resmi kaynaktan (https://astral.sh/uv) kuruluyor..." -ForegroundColor Cyan
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:LOCALAPPDATA\uv;$env:Path"
    if (Test-Path "$env:USERPROFILE\.local\bin\uv.exe") {
        $UvExe = "$env:USERPROFILE\.local\bin\uv.exe"
    } else {
        throw "'uv' kurulumu başarısız oldu. Lütfen internet bağlantınızı kontrol edin."
    }
}
Write-Host "      -> OK: $UvExe ($(& $UvExe --version))" -ForegroundColor Green

# 3. ADIM: Python 3.12 Çalışma Ortamı
Write-Host "[3/5] Python 3.12 çalışma ortamı kontrol ediliyor..." -ForegroundColor Yellow
& $UvExe python install 3.12
Write-Host "      -> OK: Python 3.12 hazır." -ForegroundColor Green

# 4. ADIM: Sanal Ortam (.venv) ve Bağımlılıklar
Write-Host "[4/5] Python sanal ortamı (.venv) ve bağımlılıklar senkronize ediliyor..." -ForegroundColor Yellow

$VenvPython = Join-Path $TargetDir ".venv\Scripts\python.exe"
if (Test-Path (Join-Path $TargetDir ".venv")) {
    $needRebuild = $false
    if (-not (Test-Path $VenvPython)) {
        $needRebuild = $true
    } else {
        try {
            $ver = & $VenvPython --version 2>&1
            if ($LASTEXITCODE -ne 0) { $needRebuild = $true }
        } catch {
            $needRebuild = $true
        }
    }
    if ($needRebuild) {
        Write-Host "      -> Farklı sistemden kalan '.venv' temizlenip yeniden oluşturuluyor..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force (Join-Path $TargetDir ".venv")
    }
}

Push-Location $TargetDir
try {
    & $UvExe sync --python 3.12
} finally {
    Pop-Location
}

if (-not (Test-Path $VenvPython)) {
    throw "Sanal ortam oluşturulamadı: $VenvPython bulunamadı."
}
Write-Host "      -> OK: Tüm bağımlılıklar kuruldu." -ForegroundColor Green

# 5. ADIM: Tüm Yapay Zekâ Asistanları ve Canlı Doğrulama
Write-Host "[5/5] Tüm Yapay Zekâ Asistanları (Claude, Gemini, ChatGPT/Codex, OpenCode, Cline, Kimi, Hermes) otomatik yapılandırılıyor ve canlı UYAP testi yapılıyor..." -ForegroundColor Yellow
$HelperScript = Join-Path $TargetDir "setup_helper.py"
$env:PYTHONIOENCODING = "utf-8"
& $VenvPython $HelperScript $TargetDir $VenvPython

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " ✔ KURULUM BAŞARIYLA TAMAMLANDI!                               " -ForegroundColor Green
Write-Host "   Kullandığınız yapay zekâ asistanını (Claude Desktop,        " -ForegroundColor Green
Write-Host "   Gemini Antigravity, ChatGPT Codex, OpenCode, Cline, Kimi,   " -ForegroundColor Green
Write-Host "   Hermes Agent veya Cursor) yeniden başlatıp hemen kullanın.  " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
