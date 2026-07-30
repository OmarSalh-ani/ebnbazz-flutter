# Builds ParentApp for web with Quran fonts excluded from the bundle.

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    & "$PSScriptRoot\prepare_web_pubspec.ps1" -Action strip
    try {
        flutter build web --release --pwa-strategy=none
        if ($LASTEXITCODE -ne 0) {
            throw 'flutter build web failed for ParentApp'
        }
        & "$PSScriptRoot\optimize_web_build.ps1"
    }
    finally {
        & "$PSScriptRoot\prepare_web_pubspec.ps1" -Action restore
    }
}
finally {
    Pop-Location
}
