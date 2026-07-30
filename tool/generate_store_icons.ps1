<#
.SYNOPSIS
  Generate Flutter launcher icons (Android + iOS) from a customer logo.

.PARAMETER LogoPath
  Path to a square PNG logo (ideally 1024x1024).

.PARAMETER BackgroundColor
  Adaptive icon background hex (default #071B3A).

.EXAMPLE
  .\generate_store_icons.ps1 -LogoPath C:\logos\customer.png
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$LogoPath,

  [string]$BackgroundColor = "#071B3A"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $LogoPath)) {
  throw "Logo not found: $LogoPath"
}

$assetsDir = Join-Path $root "assets\images"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

$appIcon = Join-Path $assetsDir "app_icon.png"
$foreground = Join-Path $assetsDir "app_icon_foreground.png"
Copy-Item -Force $LogoPath $appIcon
Copy-Item -Force $LogoPath $foreground

Write-Host "Copied logo to:"
Write-Host "  $appIcon"
Write-Host "  $foreground"
Write-Host "Adaptive background: $BackgroundColor"

$pubspec = Join-Path $root "pubspec.yaml"
$content = Get-Content $pubspec -Raw
$content = [regex]::Replace(
  $content,
  '(?m)^(\s*adaptive_icon_background:\s*).*$',
  "`${1}`"$BackgroundColor`""
)
Set-Content -Path $pubspec -Value $content -NoNewline

Write-Host "Running dart run flutter_launcher_icons..."
flutter pub get
dart run flutter_launcher_icons

Write-Host ""
Write-Host "Done. Also prepare store listing assets:"
Write-Host "  See google-play/templates/icon-assets.md"
