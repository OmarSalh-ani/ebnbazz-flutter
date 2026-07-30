# Strips QCF page fonts from pubspec.yaml before a web build so ~100MB of
# Quran fonts are not bundled. Restores the original pubspec afterward.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('strip', 'restore')]
    [string]$Action
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$backupPath = Join-Path $projectRoot 'pubspec.yaml.web-build-backup'

if ($Action -eq 'strip') {
    if (-not (Test-Path $pubspecPath)) {
        throw "pubspec.yaml not found at $pubspecPath"
    }

    Copy-Item $pubspecPath $backupPath -Force
    $content = Get-Content $pubspecPath -Raw
    $pattern = '(?ms)^    - family: QCF_P\d+\r?\n      fonts:\r?\n        - asset: assets/fonts/v2woff/p\d+\.woff\r?\n\r?\n'
    $stripped = [regex]::Replace($content, $pattern, '')
    $removed = ([regex]::Matches($content, $pattern)).Count
    [System.IO.File]::WriteAllText($pubspecPath, $stripped)
    Write-Host "Stripped $removed QCF font families from pubspec.yaml for web build."
    exit 0
}

if (-not (Test-Path $backupPath)) {
    Write-Warning "No pubspec backup found — skipping restore."
    exit 0
}

Move-Item $backupPath $pubspecPath -Force
Write-Host 'Restored pubspec.yaml after web build.'
