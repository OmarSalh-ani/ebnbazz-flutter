# Post-processes ParentApp web build output for faster loads:
# - Removes QCF fonts from FontManifest.json
# - Deletes bundled v2woff font files (~100MB)
# - Removes Quran-only assets not used on web

$ErrorActionPreference = 'Stop'

$webRoot = Join-Path $PSScriptRoot '..\build\web'
$assetsRoot = Join-Path $webRoot 'assets'

if (-not (Test-Path $webRoot)) {
    Write-Warning "Web build output not found at $webRoot — skipping."
    exit 0
}

# Families removed from disk below — must also be dropped from FontManifest or the
# engine will request missing assets (IIS may return index.html → NetworkError).
$quranOnlyFamilies = @(
    'AmiriQuran',
    'Taha',
    'me',
    'UthmanicHafs13',
    'qaloon',
    'pdsm',
    'noor ehuda',
    'hafs-nastaleeq-ver10-org',
    'hafs-smart-07',
    'jomhuria-regular-full-org',
    'mada-regular-full',
    'markazi-text-regular-full-org',
    'noto-kufi-arabic-regular-full',
    'qumbul-v7-full',
    'qur-std',
    'shorooq-full-org',
    'arsura',
    'KFGQPC Uthmanic Script HAFS Regular'
)

function Write-FontManifestJson {
    param(
        [string]$Path,
        [array]$Entries
    )
    $json = $Entries | ConvertTo-Json -Depth 10 -Compress
    if ($Entries.Count -eq 1) {
        $json = "[$json]"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
}

$manifestPath = Join-Path $assetsRoot 'FontManifest.json'
if (Test-Path $manifestPath) {
    $raw = @(Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    $filtered = @(
        $raw | Where-Object {
            $_.family -notmatch '^QCF_P\d+$' -and
            $quranOnlyFamilies -notcontains $_.family
        }
    )
    Write-FontManifestJson -Path $manifestPath -Entries $filtered
    $removed = $raw.Count - $filtered.Count
    Write-Host "FontManifest: kept $($filtered.Count) families, removed $removed (QCF + Quran-only)."
}

$woffDir = Join-Path $assetsRoot 'assets\fonts\v2woff'
if (Test-Path $woffDir) {
    $sizeMb = [math]::Round(((Get-ChildItem $woffDir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
    Remove-Item $woffDir -Recurse -Force
    Write-Host "Removed v2woff fonts from web build ($sizeMb MB)."
}

$quranOnlyFonts = @(
    'AmiriQuran-Regular.ttf',
    'me_quran.ttf',
    'UthmanicHafs1Ver13.otf',
    'qaloon.ttf',
    'pdms.otf',
    'noorehuda-org.ttf',
    'hafs-nastaleeq-ver10-org.otf',
    'hafs-smart-07.woff',
    'jomhuria-regular-full-org.ttf',
    'mada-regular-full.ttf',
    'markazi-text-regular-full-org.ttf',
    'noto-kufi-arabic-regular-full.ttf',
    'qumbul-v7-full.ttf',
    'qur-std.ttf',
    'shorooq-full-org.ttf',
    'arsura.ttf',
    'KFGQPCUthmanicScriptHAFSRegular.otf',
    'taha.ttf'
)

$fontsDir = Join-Path $assetsRoot 'assets\fonts'
$removedFontMb = 0.0
foreach ($fileName in $quranOnlyFonts) {
    $path = Join-Path $fontsDir $fileName
    if (Test-Path $path) {
        $removedFontMb += (Get-Item $path).Length / 1MB
        Remove-Item $path -Force
    }
}
if ($removedFontMb -gt 0) {
    Write-Host ("Removed Quran-only UI fonts from web build ({0:N2} MB)." -f $removedFontMb)
}

$quranJsonDir = Join-Path $assetsRoot 'assets\json'
foreach ($jsonFile in @('surahs.json', 'quarters.json')) {
    $path = Join-Path $quranJsonDir $jsonFile
    if (Test-Path $path) {
        Remove-Item $path -Force
    }
}

$quranImage = Join-Path $assetsRoot 'assets\images\quran.jpg'
if (Test-Path $quranImage) {
    Remove-Item $quranImage -Force
}

# PWA is disabled; ship a one-shot SW that clears legacy caches for returning users.
$swSource = Join-Path $PSScriptRoot '..\web\flutter_service_worker.js'
$swDest = Join-Path $webRoot 'flutter_service_worker.js'
if (Test-Path $swSource) {
    Copy-Item $swSource $swDest -Force
    Write-Host 'Deployed cache-cleanup flutter_service_worker.js.'
}

$totalMb = [math]::Round(((Get-ChildItem $webRoot -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
Write-Host "Web build size after optimization: $totalMb MB."
