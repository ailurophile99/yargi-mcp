# =============================================================================
# Yargi & UYAP Mevzuat MCP - Windows Kurulum Betigi
#
# Kullanim (PowerShell'e yapistirip Enter):
#   irm https://raw.githubusercontent.com/ailurophile99/yargi-mcp/master/install.ps1 | iex
#
# Not: Bu dosya bilerek yalnizca ASCII karakter icerir. Boylece Windows PowerShell 5.1
#      dosyayi hangi kodlamayla okursa okusun bozulmaz.
# =============================================================================

$global:YargiInstallOk = $false

function Install-YargiMcp {
    $ErrorActionPreference = 'Continue'   # Harici komutlarin (git/uv) stderr ciktilari hata sayilmasin
    $ProgressPreference = 'SilentlyContinue' # Invoke-WebRequest'i PowerShell 5.1'de 10 kat hizlandirir
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $Repo    = 'ailurophile99/yargi-mcp'
    $Branch  = 'master'
    $RepoUrl = "https://github.com/$Repo.git"
    $ZipUrl  = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"
    $TargetDir = if ($env:YARGI_DIR) { $env:YARGI_DIR } else { Join-Path $env:USERPROFILE 'yargi-mcp' }
    $env:UV_LINK_MODE = 'copy'            # OneDrive / farkli disk kaynakli hardlink uyarilarini onler
    $env:PYTHONIOENCODING = 'utf-8'
    $env:PYTHONUTF8 = '1'

    function Step($n, $text) { Write-Host ""; Write-Host "[$n/6] $text" -ForegroundColor Yellow }
    function Info($text)     { Write-Host "      -> $text" -ForegroundColor Cyan }
    function Ok($text)       { Write-Host "      -> OK: $text" -ForegroundColor Green }
    function Warn($text)     { Write-Host "      -> UYARI: $text" -ForegroundColor DarkYellow }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   Yargi & UYAP Mevzuat MCP - Otomatik Kurulum (Windows)         " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   Kurulum klasoru: $TargetDir"

    # ARM64 Windows: tum kutuphanelerin hazir paketleri x64 icin var; x64 Python (emulasyon) kullanilir.
    $arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    $PyRequest = if ($arch -eq 'ARM64') { 'cpython-3.12-windows-x86_64-none' } else { '3.12' }
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "32-bit Windows desteklenmiyor. 64-bit Windows 10/11 gereklidir."
    }

    # ------------------------------------------------------------------ 1
    Step 1 "MCP kaynak dosyalari hazirlaniyor"
    $hasGit  = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $mainPy  = Join-Path $TargetDir 'mcp_server_main.py'
    $gitDir  = Join-Path $TargetDir '.git'

    function Get-ZipSource {
        $zip = Join-Path $env:TEMP ("yargi-mcp-" + [guid]::NewGuid().ToString() + ".zip")
        $ext = Join-Path $env:TEMP ("yargi-mcp-" + [guid]::NewGuid().ToString())
        Info "GitHub'dan arsiv indiriliyor..."
        Invoke-WebRequest -Uri $ZipUrl -OutFile $zip -UseBasicParsing -ErrorAction Stop
        Info ("Indirildi: {0:N1} MB, aciliyor..." -f ((Get-Item $zip).Length / 1MB))
        Expand-Archive -Path $zip -DestinationPath $ext -Force -ErrorAction Stop
        $src = Get-ChildItem -Path $ext -Directory | Select-Object -First 1
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        Copy-Item -Path (Join-Path $src.FullName '*') -Destination $TargetDir -Recurse -Force -ErrorAction Stop
        Remove-Item -Recurse -Force $zip, $ext -ErrorAction SilentlyContinue
    }

    if ((Test-Path $TargetDir) -and -not (Test-Path $mainPy) -and -not (Test-Path $gitDir)) {
        $old = "$TargetDir.eski-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Warn "Yarim kalmis eski kurulum bulundu, '$old' olarak kenara aliniyor."
        Rename-Item -Path $TargetDir -NewName (Split-Path $old -Leaf) -ErrorAction Stop
    }

    if (Test-Path $gitDir) {
        if ($env:YARGI_SKIP_UPDATE -eq '1') {
            Info "Guncelleme atlandi (YARGI_SKIP_UPDATE=1)."
        } elseif ($hasGit) {
            Info "Mevcut kurulum en guncel surume getiriliyor..."
            git -C $TargetDir fetch origin $Branch
            if ($LASTEXITCODE -eq 0) {
                git -C $TargetDir reset --hard "origin/$Branch" | Out-Null
            } else {
                Warn "GitHub'a ulasilamadi, mevcut surumle devam ediliyor."
            }
        } else {
            Get-ZipSource
        }
    } elseif (Test-Path $mainPy) {
        if ($env:YARGI_SKIP_UPDATE -ne '1') {
            try { Get-ZipSource } catch { Warn "Guncelleme indirilemedi, mevcut dosyalarla devam ediliyor." }
        }
    } else {
        $cloned = $false
        if ($hasGit) {
            Info "GitHub'dan indiriliyor (git)..."
            git clone --depth 1 --branch $Branch $RepoUrl $TargetDir
            $cloned = ($LASTEXITCODE -eq 0) -and (Test-Path $mainPy)
            if (-not $cloned -and (Test-Path $TargetDir)) { Remove-Item -Recurse -Force $TargetDir -ErrorAction SilentlyContinue }
        }
        if (-not $cloned) { Get-ZipSource }
    }
    if (-not (Test-Path $mainPy)) { throw "Kaynak dosyalar indirilemedi. Internet baglantinizi kontrol edin." }
    Ok "Kaynak dosyalar hazir."

    # ------------------------------------------------------------------ 2
    Step 2 "'uv' paket yoneticisi kontrol ediliyor"
    function Find-Uv {
        $cands = @()
        $cmd = Get-Command uv -ErrorAction SilentlyContinue
        if ($cmd) { $cands += $cmd.Source }
        $cands += @("$env:USERPROFILE\.local\bin\uv.exe", "$env:USERPROFILE\.cargo\bin\uv.exe",
                    "$env:LOCALAPPDATA\uv\uv.exe", "$env:LOCALAPPDATA\Programs\uv\uv.exe")
        foreach ($p in $cands) { if ($p -and (Test-Path $p)) { return $p } }
        return $null
    }
    $UvExe = Find-Uv
    if (-not $UvExe) {
        Info "'uv' bulunamadi, resmi kaynaktan (astral.sh) kuruluyor..."
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        & $psExe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; irm https://astral.sh/uv/install.ps1 | iex"
        $UvExe = Find-Uv
    }
    if (-not $UvExe) {
        Info "Yedek yontem: uv dogrudan GitHub'dan indiriliyor..."
        $uvArch = if ($arch -eq 'ARM64') { 'aarch64' } else { 'x86_64' }
        $uvZip = Join-Path $env:TEMP "uv-$([guid]::NewGuid()).zip"
        $uvDir = "$env:USERPROFILE\.local\bin"
        Invoke-WebRequest -Uri "https://github.com/astral-sh/uv/releases/latest/download/uv-$uvArch-pc-windows-msvc.zip" -OutFile $uvZip -UseBasicParsing -ErrorAction Stop
        New-Item -ItemType Directory -Force -Path $uvDir | Out-Null
        Expand-Archive -Path $uvZip -DestinationPath $uvDir -Force -ErrorAction Stop
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue
        $UvExe = Find-Uv
    }
    if (-not $UvExe) { throw "'uv' kurulamadi. Internet baglantinizi veya kurumsal guvenlik ayarlarinizi kontrol edin." }
    Ok "$UvExe ($(& $UvExe --version))"

    # ------------------------------------------------------------------ 3
    Step 3 "Microsoft Visual C++ calisma zamani kontrol ediliyor"
    $vcVer = $null
    foreach ($k in 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64') {
        $v = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
        if ($v -and $v.Installed -eq 1) { $vcVer = [version]("{0}.{1}.{2}" -f $v.Major, $v.Minor, $v.Bld); break }
    }
    if ($vcVer -and $vcVer -ge [version]'14.40.0') {
        Ok "Visual C++ $vcVer yuklu."
    } else {
        if ($vcVer) { Info "Visual C++ $vcVer eski." } else { Info "Visual C++ calisma zamani bulunamadi." }
        Info "Guncel surum indiriliyor (Windows yonetici izni penceresi cikarsa 'Evet' deyin)..."
        try {
            $vcExe = Join-Path $env:TEMP 'vc_redist.x64.exe'
            Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vcExe -UseBasicParsing -ErrorAction Stop
            $p = Start-Process -FilePath $vcExe -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait -PassThru -ErrorAction Stop
            if ($p.ExitCode -in 0, 1638, 3010) { Ok "Visual C++ calisma zamani hazir." } else { Warn "Visual C++ kurulumu kod $($p.ExitCode) ile bitti." }
        } catch {
            Warn "Visual C++ kurulamadi veya izin verilmedi. Kurulum devam ediyor (cogu sistemde gerekmez)."
        }
    }

    # ------------------------------------------------------------------ 4
    Step 4 "Python 3.12 hazirlaniyor"
    & $UvExe python install $PyRequest
    if ($LASTEXITCODE -ne 0) { throw "Python 3.12 kurulamadi." }
    Ok "Python 3.12 hazir."

    # ------------------------------------------------------------------ 5
    Step 5 "Python kutuphaneleri kuruluyor (ilk kurulumda 1-3 dakika surebilir)"
    $VenvDir    = Join-Path $TargetDir '.venv'
    $VenvPython = Join-Path $VenvDir 'Scripts\python.exe'
    if (Test-Path $VenvDir) {
        $broken = -not (Test-Path $VenvPython)
        if (-not $broken) { & $VenvPython -c "import sys" 2>$null; $broken = ($LASTEXITCODE -ne 0) }
        if ($broken) {
            Info "Bozuk sanal ortam temizleniyor..."
            Remove-Item -Recurse -Force $VenvDir -ErrorAction SilentlyContinue
        }
    }
    Push-Location $TargetDir
    try {
        & $UvExe sync --frozen --python $PyRequest
        if ($LASTEXITCODE -ne 0) {
            Warn "Kilitli surumlerle kurulum basarisiz, cozumleme yeniden deneniyor..."
            & $UvExe sync --python $PyRequest
        }
    } finally { Pop-Location }
    if (($LASTEXITCODE -ne 0) -or -not (Test-Path $VenvPython)) { throw "Python kutuphaneleri kurulamadi." }
    Ok "Tum kutuphaneler kuruldu."

    # ------------------------------------------------------------------ 6
    Step 6 "Sunucu testi ve yapay zeka asistanlari yapilandirmasi"
    & $VenvPython (Join-Path $TargetDir 'setup_helper.py') $TargetDir $VenvPython
    $helperCode = $LASTEXITCODE

    Write-Host ""
    if ($helperCode -eq 0) {
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  KURULUM BASARIYLA TAMAMLANDI                                   " -ForegroundColor Green
        Write-Host "================================================================" -ForegroundColor Green
        Write-Host "  Simdi kullandiginiz yapay zeka uygulamasini TAMAMEN kapatip acin"
        Write-Host "  (Claude Desktop icin: saat yanindaki tepsi simgesine sag tik > Quit)."
        Write-Host "  Ardindan dogrudan sorun: 'Yargitay'da kira tespit kararlarini ara'"
        Write-Host "================================================================" -ForegroundColor Green
        $global:YargiInstallOk = $true
    } else {
        Write-Host "================================================================" -ForegroundColor Red
        Write-Host "  KURULUM TAMAMLANAMADI - yukaridaki [HATA] satirlarina bakin.    " -ForegroundColor Red
        Write-Host "  Kurulumu tekrar calistirmak guvenlidir; kaldigi yerden devam eder." -ForegroundColor Red
        Write-Host "================================================================" -ForegroundColor Red
    }
}

try {
    Install-YargiMcp
} catch {
    Write-Host ""
    Write-Host "HATA: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Kurulumu tekrar calistirmak guvenlidir. Sorun surerse bu ekranin fotografini gonderin." -ForegroundColor Red
}

if ($env:YARGI_FROM_BAT -eq '1') {
    if ($global:YargiInstallOk) { exit 0 } else { exit 1 }
}
