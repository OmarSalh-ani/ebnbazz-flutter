# Builds a signed, obfuscated Android App Bundle and Google Play deploy artifacts
# for مركز ابن باز (com.alsalhani.ebnbazz).
#
# Usage:
#   .\tool\play_deploy.ps1
#   .\tool\play_deploy.ps1 -OutputDir ..\..\publish\google-play
#   .\tool\play_deploy.ps1 -SkipBuild   # re-package last AAB + cert + templates only
#
# Prerequisites:
#   - Flutter in PATH
#   - android/key.properties + android/upload-keystore.jks (run tool/setup_android_signing.ps1 once)

param(
    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) 'publish\google-play'),
    [string]$PrivacyPolicyUrl = 'https://ebnbazz.com/privacy-policy',
    [string]$QcfFontBaseUrl = 'https://admin-api.ebnbazz.com/static/qcf-fonts',
    [string]$MediaBaseUrl = 'https://admin-api.ebnbazz.com',
    [string]$ApiBaseUrl = 'https://teachermobileapi.ebnbazz.com',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path $PSScriptRoot -Parent
$AndroidDir = Join-Path $ProjectDir 'android'
$KeyProps = Join-Path $AndroidDir 'key.properties'
$Keystore = Join-Path $AndroidDir 'upload-keystore.jks'
$SymbolsDir = Join-Path $ProjectDir 'build\app\outputs\symbols'
$AabSource = Join-Path $ProjectDir 'build\app\outputs\bundle\release\app-release.aab'
$TemplatesDir = Join-Path (Split-Path $ProjectDir -Parent) 'google-play\templates'
$GradleFile = Join-Path $AndroidDir 'app\build.gradle.kts'

$AppDisplayName = 'مركز ابن باز'
$AppStoreName = 'مركز ابن باز'
$DefaultPackageName = 'com.alsalhani.ebnbazz'

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

function Get-ApplicationId {
    if (-not (Test-Path $GradleFile)) { return $DefaultPackageName }
    $gradle = Get-Content $GradleFile -Raw
    if ($gradle -match 'applicationId\s*=\s*"([^"]+)"') {
        return $Matches[1]
    }
    return $DefaultPackageName
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

function Assert-SigningReady {
    if (-not (Test-Path $KeyProps)) {
        throw "Missing $KeyProps - run: .\tool\setup_android_signing.ps1"
    }
    if (-not (Test-Path $Keystore)) {
        throw "Missing $Keystore - run: .\tool\setup_android_signing.ps1"
    }

    $props = @{}
    Get-Content $KeyProps | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.+)$') { $props[$Matches[1].Trim()] = $Matches[2].Trim() }
    }
    foreach ($required in @('storePassword', 'keyPassword', 'keyAlias', 'storeFile')) {
        if (-not $props.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($props[$required])) {
            throw "key.properties is missing required key: $required"
        }
    }
    return $props
}

function Compress-SymbolsArchive([string]$DestZip) {
    if (-not (Test-Path $SymbolsDir)) {
        Write-Host "  (no symbols dir yet: $SymbolsDir)" -ForegroundColor Yellow
        return $false
    }
    if (Test-Path $DestZip) { Remove-Item $DestZip -Force }
    Compress-Archive -Path (Join-Path $SymbolsDir '*') -DestinationPath $DestZip -Force
    return $true
}

Write-Step 'Checking release signing'
$props = Assert-SigningReady
$packageName = Get-ApplicationId
$version = Get-AppVersion

Write-Host "  App:     $AppDisplayName ($AppStoreName)"
Write-Host "  Package: $packageName"
Write-Host "  Version: $($version.Name)+$($version.Code)"

if (-not $SkipBuild) {
    Write-Step 'Building release App Bundle (obfuscated, tree-shaken)'
    Push-Location $ProjectDir
    try {
        flutter build appbundle --release `
            --obfuscate `
            --split-debug-info=$SymbolsDir `
            --tree-shake-icons `
            --dart-define=API_BASE_URL=$ApiBaseUrl `
            --dart-define=MEDIA_BASE_URL=$MediaBaseUrl `
            --dart-define=PRIVACY_POLICY_URL=$PrivacyPolicyUrl `
            --dart-define=QCF_FONT_BASE_URL=$QcfFontBaseUrl
        if ($LASTEXITCODE -ne 0) { throw 'flutter build appbundle failed' }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Step 'Skipping Flutter build (-SkipBuild)'
}

if (-not (Test-Path $AabSource)) {
    throw "AAB not found: $AabSource"
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$aabName = "ebnbazz-parent-app-v$($version.Name)+$($version.Code).aab"
$aabDest = Join-Path $OutputDir $aabName
Copy-Item $AabSource $aabDest -Force

Write-Step 'Exporting Play upload certificate (PEM)'
$keytool = Find-Keytool
$alias = $props['keyAlias']
$storePass = $props['storePassword']
$certPath = Join-Path $OutputDir 'upload_certificate.pem'
& $keytool -export -rfc `
    -keystore $Keystore `
    -alias $alias `
    -storepass $storePass `
    -file $certPath
if ($LASTEXITCODE -ne 0) { throw 'keytool export failed' }

Write-Step 'Archiving obfuscation symbols for Play Console'
$symbolsZipName = "native-debug-symbols-v$($version.Name)+$($version.Code).zip"
$symbolsZip = Join-Path $OutputDir $symbolsZipName
$symbolsPacked = Compress-SymbolsArchive $symbolsZip

Write-Step 'Copying Play Console templates'
if (Test-Path $TemplatesDir) {
    Copy-Item (Join-Path $TemplatesDir '*') $OutputDir -Recurse -Force
}
else {
    Write-Host "  (templates not found: $TemplatesDir)" -ForegroundColor Yellow
}

$manifest = [ordered]@{
    appName              = $AppDisplayName
    storeListingName     = $AppStoreName
    packageName          = $packageName
    versionName          = $version.Name
    versionCode          = $version.Code
    aabFile              = $aabName
    aabSizeMb            = [math]::Round((Get-Item $aabDest).Length / 1MB, 2)
    uploadCertificate    = 'upload_certificate.pem'
    nativeDebugSymbols   = $(if ($symbolsPacked) { $symbolsZipName } else { $null })
    privacyPolicyUrl     = $PrivacyPolicyUrl
    qcfFontBaseUrl       = $QcfFontBaseUrl
    mediaBaseUrl         = $MediaBaseUrl
    apiBaseUrl           = $ApiBaseUrl
    builtAt              = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    obfuscationSymbols   = $SymbolsDir
    skipBuild            = [bool]$SkipBuild
} | ConvertTo-Json -Depth 3

$manifest | Set-Content (Join-Path $OutputDir 'build-manifest.json') -Encoding UTF8

Write-Host ''
Write-Host 'Google Play build ready for مركز ابن باز.' -ForegroundColor Green
Write-Host "Package: $packageName"
Write-Host "Version: $($version.Name)+$($version.Code)"
Write-Host "Output:  $OutputDir"
Get-ChildItem $OutputDir | ForEach-Object {
    $mb = if ($_.PSIsContainer) { '' } else { " ($([math]::Round($_.Length / 1MB, 2)) MB)" }
    Write-Host "  $($_.Name)$mb"
}
Write-Host ''
Write-Host 'Next: upload the AAB in Play Console -> Production (or Internal testing first).' -ForegroundColor DarkGray
