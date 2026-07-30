# Builds a signed, obfuscated Android App Bundle and Google Play deploy artifacts.
# Usage: .\tool\play_deploy.ps1 [-OutputDir ..\..\publish\google-play]
#
# Prerequisites:
#   - Flutter in PATH
#   - android/key.properties + android/upload-keystore.jks (run tool/setup_android_signing.ps1 once)

param(
    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'publish\google-play'),
    [string]$PrivacyPolicyUrl = 'https://ebnbazz.com/privacy-policy',
    [string]$QcfFontBaseUrl = 'https://admin-api.ebnbazz.com/static/qcf-fonts'
)

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path $PSScriptRoot -Parent
$AndroidDir = Join-Path $ProjectDir 'android'
$KeyProps = Join-Path $AndroidDir 'key.properties'
$Keystore = Join-Path $AndroidDir 'upload-keystore.jks'
$SymbolsDir = Join-Path $ProjectDir 'build\app\outputs\symbols'
$AabSource = Join-Path $ProjectDir 'build\app\outputs\bundle\release\app-release.aab'
$TemplatesDir = Join-Path (Split-Path $ProjectDir -Parent) 'google-play\templates'

function Write-Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-AppVersion {
    $pubspec = Join-Path $ProjectDir 'pubspec.yaml'
    $content = Get-Content $pubspec -Raw
    if ($content -match 'version:\s*([\d.]+)\+(\d+)') {
        return @{
            Name = $Matches[1]
            Code = [int]$Matches[2]
        }
    }
    throw 'Could not parse version from pubspec.yaml'
}

function Find-Keytool {
    if ($env:JAVA_HOME) {
        $fromJavaHome = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        if (Test-Path $fromJavaHome) { return $fromJavaHome }
    }
    $studio = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
    if (Test-Path $studio) { return $studio }
    throw 'keytool not found (install Android Studio or JDK)'
}

if (-not (Test-Path $KeyProps)) {
    throw "Missing $KeyProps - run: .\tool\setup_android_signing.ps1"
}

Write-Step 'Building release App Bundle (obfuscated)'
Push-Location $ProjectDir
try {
    flutter build appbundle --release `
        --obfuscate `
        --split-debug-info=$SymbolsDir `
        --dart-define=PRIVACY_POLICY_URL=$PrivacyPolicyUrl `
        --dart-define=QCF_FONT_BASE_URL=$QcfFontBaseUrl
    if ($LASTEXITCODE -ne 0) { throw 'flutter build appbundle failed' }
}
finally {
    Pop-Location
}

if (-not (Test-Path $AabSource)) {
    throw "AAB not found: $AabSource"
}

$version = Get-AppVersion
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$aabName = "masged-parent-app-v$($version.Name)+$($version.Code).aab"
$aabDest = Join-Path $OutputDir $aabName
Copy-Item $AabSource $aabDest -Force

Write-Step 'Exporting Play upload certificate (PEM)'
$keytool = Find-Keytool
$props = @{}
Get-Content $KeyProps | ForEach-Object {
    if ($_ -match '^\s*([^#=]+)=(.+)$') { $props[$Matches[1].Trim()] = $Matches[2].Trim() }
}
$storePass = $props['storePassword']
$alias = $props['keyAlias']
$certPath = Join-Path $OutputDir 'upload_certificate.pem'
& $keytool -export -rfc `
    -keystore $Keystore `
    -alias $alias `
    -storepass $storePass `
    -file $certPath
if ($LASTEXITCODE -ne 0) { throw 'keytool export failed' }

Write-Step 'Copying Play Console templates'
if (Test-Path $TemplatesDir) {
    Copy-Item (Join-Path $TemplatesDir '*') $OutputDir -Recurse -Force
}

$manifest = @{
    appName            = 'حلقات مسجد مبارك الصباح'
    packageName        = 'com.mubarakmasged.com'
    versionName        = $version.Name
    versionCode        = $version.Code
    aabFile            = $aabName
    aabSizeMb          = [math]::Round((Get-Item $aabDest).Length / 1MB, 2)
    privacyPolicyUrl   = $PrivacyPolicyUrl
    qcfFontBaseUrl     = $QcfFontBaseUrl
    builtAt            = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    obfuscationSymbols = $SymbolsDir
} | ConvertTo-Json -Depth 3

$manifest | Set-Content (Join-Path $OutputDir 'build-manifest.json') -Encoding UTF8

Write-Host ''
Write-Host 'Google Play build ready.' -ForegroundColor Green
Write-Host "Output: $OutputDir"
Get-ChildItem $OutputDir | ForEach-Object {
    $mb = if ($_.PSIsContainer) { '' } else { " ($([math]::Round($_.Length / 1MB, 2)) MB)" }
    Write-Host "  $($_.Name)$mb"
}
