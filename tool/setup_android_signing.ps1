# Creates an Android upload keystore for Play Console (run once).
# Output: android/upload-keystore.jks + android/key.properties (gitignored)

$ErrorActionPreference = "Stop"
$androidDir = Join-Path $PSScriptRoot "..\android"
$keystore = Join-Path $androidDir "upload-keystore.jks"
$keyProps = Join-Path $androidDir "key.properties"

if (Test-Path $keystore) {
    Write-Host "Keystore already exists: $keystore"
    exit 0
}

$keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Test-Path $keytool)) {
    Write-Error "keytool not found at $keytool. Install Android Studio or JDK."
}

$storePass = "MasgedUpload2026!"
$keyPass = $storePass
$dname = "CN=Masged Parent App, OU=Mobile, O=Mosque Mubarak, L=Kuwait, C=KW"

& $keytool -genkeypair -v `
    -keystore $keystore `
    -storepass $storePass `
    -keypass $keyPass `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname $dname

@"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Set-Content -Path $keyProps -Encoding UTF8

Write-Host "Created $keystore and $keyProps"
Write-Host "IMPORTANT: Change passwords before production release and back up the keystore."
