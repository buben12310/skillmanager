# SkillManager Release Build Script
# 用法: 在项目根目录执行 .\release.ps1
# 功能: 构建 Go core + Flutter Windows 发行版,打包到 release/ 目录
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$releaseDir = Join-Path $root "release"

Write-Host "=== SkillManager Release Build ===" -ForegroundColor Cyan
Write-Host "Root: $root"
Write-Host "Release: $releaseDir"
Write-Host ""

# 0. 终止可能占用文件的旧进程 + 清除本地缓存 (从零开始测试)
Write-Host "[0/5] Stopping running instances & clearing cache..." -ForegroundColor Yellow
Get-Process -Name "skillmanager", "skillmanager-core" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  Stopping $($_.Name) (PID $($_.Id))" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 500

# 清除本地缓存: APPDATA/skillmanager (数据库 + 日志)
$appData = $env:APPDATA
if (-not $appData) { $appData = [Environment]::GetFolderPath("ApplicationData") }
$cacheDir = Join-Path $appData "skillmanager"
if (Test-Path $cacheDir) {
    Write-Host "  Removing cache: $cacheDir" -ForegroundColor Gray
    Remove-Item -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 清除 shared_preferences.json (Flutter 持久化的设置: 主题/强调色等)
$prefsPath = Join-Path $appData "com.skillmanager\skillmanager\shared_preferences.json"
if (Test-Path $prefsPath) {
    Write-Host "  Removing prefs: $prefsPath" -ForegroundColor Gray
    Remove-Item -Path $prefsPath -Force -ErrorAction SilentlyContinue
}
# 兼容路径: 某些环境下 company 直接是 skillmanager
$prefsPath2 = Join-Path $appData "skillmanager\skillmanager\shared_preferences.json"
if (Test-Path $prefsPath2) {
    Remove-Item -Path $prefsPath2 -Force -ErrorAction SilentlyContinue
}

Write-Host "  OK" -ForegroundColor Green

# 1. 构建 Go core
Write-Host "[1/5] Building Go core..." -ForegroundColor Yellow
$coreDir = Join-Path $root "skillmanager-core"
Push-Location $coreDir
try {
    go build -ldflags "-s -w" -o skillmanager-core.exe ./cmd/server
    if ($LASTEXITCODE -ne 0) { throw "Go build failed" }
    Write-Host "  OK: skillmanager-core.exe" -ForegroundColor Green
} finally {
    Pop-Location
}

# 2. 构建 Flutter Windows 发行版
Write-Host "[2/5] Building Flutter Windows release..." -ForegroundColor Yellow
$appDir = Join-Path $root "app"
Push-Location $appDir
try {
    # Flutter 将 banner 输出到 stderr,需临时关闭 Stop 模式
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & flutter build windows --release 2>&1
    $ErrorActionPreference = $prevPref
    if ($LASTEXITCODE -ne 0) {
        $output | ForEach-Object { Write-Host $_ }
        throw "Flutter build failed"
    }
    Write-Host "  OK: skillmanager.exe" -ForegroundColor Green
} finally {
    Pop-Location
}

# 3. 准备 release 目录
Write-Host "[3/5] Packaging release..." -ForegroundColor Yellow
if (Test-Path $releaseDir) {
    Remove-Item -Path $releaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null

# 复制 Flutter 构建产物
$flutterBuild = Join-Path $appDir "build\windows\x64\runner\Release"
if (Test-Path $flutterBuild) {
    Copy-Item -Path "$flutterBuild\*" -Destination $releaseDir -Recurse -Force
    Write-Host "  Copied Flutter build" -ForegroundColor Green
} else {
    throw "Flutter build not found: $flutterBuild"
}

# 复制 Go core 到 release 根目录 (与 exe 同级)
$coreExe = Join-Path $coreDir "skillmanager-core.exe"
if (Test-Path $coreExe) {
    Copy-Item -Path $coreExe -Destination $releaseDir -Force
    Write-Host "  Copied skillmanager-core.exe" -ForegroundColor Green
} else {
    throw "Go core build not found: $coreExe"
}

# 4. 验证
Write-Host "[4/5] Verifying..." -ForegroundColor Yellow
$finalExe = Join-Path $releaseDir "skillmanager.exe"
$finalCore = Join-Path $releaseDir "skillmanager-core.exe"
if ((Test-Path $finalExe) -and (Test-Path $finalCore)) {
    $exeSize = (Get-Item $finalExe).Length / 1MB
    $coreSize = (Get-Item $finalCore).Length / 1MB
    Write-Host "  skillmanager.exe: $([math]::Round($exeSize, 2)) MB" -ForegroundColor Green
    Write-Host "  skillmanager-core.exe: $([math]::Round($coreSize, 2)) MB" -ForegroundColor Green
} else {
    throw "Release verification failed"
}

Write-Host ""
Write-Host "=== Release Build Complete ===" -ForegroundColor Cyan
Write-Host "Output: $releaseDir"
Write-Host "Run: $finalExe"
Write-Host ""
Write-Host "Note: Local cache has been cleared (fresh start)." -ForegroundColor Yellow
Write-Host "  - $cacheDir (database + logs)" -ForegroundColor Gray
