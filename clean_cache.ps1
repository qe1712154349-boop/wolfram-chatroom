# clean_cache.ps1 - Dart/Flutter Cache Cleanup Script
Write-Host "Starting Dart/Flutter cache cleanup..." -ForegroundColor Cyan

# 1. Clean user-level cache
Write-Host "Cleaning user-level cache..." -ForegroundColor Yellow
$paths = @(
    "$env:APPDATA\Dart-Code",
    "$env:APPDATA\Code",
    "$env:USERPROFILE\.dartServer",
    "$env:USERPROFILE\.flutter"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "  Cleaned: $path" -ForegroundColor Green
    } else {
        Write-Host "  Not found: $path" -ForegroundColor Gray
    }
}

# 2. Clean project-level cache
Write-Host "`nCleaning project-level cache..." -ForegroundColor Yellow
Set-Location $PSScriptRoot

$projectPaths = @(
    ".dart_tool",
    "build",
    ".packages",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".dartServer"
)

foreach ($path in $projectPaths) {
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
        Write-Host "  Cleaned: $path" -ForegroundColor Green
    }
}

# 3. Run Flutter clean
Write-Host "`nRunning Flutter clean..." -ForegroundColor Yellow
flutter clean

# 4. Re-fetch dependencies
Write-Host "`nRe-fetching dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n[SUCCESS] Cache cleanup completed!" -ForegroundColor Green
Write-Host "Suggestion: Restart VS Code to ensure all changes take effect" -ForegroundColor Cyan