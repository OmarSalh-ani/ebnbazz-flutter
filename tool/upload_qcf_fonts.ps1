# Upload QCF page fonts to AdminAPI static folder (local sync).
# For production deploy, use publish-all.ps1 which copies fonts into AdminAPI publish output.
#
# Usage:
#   .\tool\upload_qcf_fonts.ps1
#   .\tool\upload_qcf_fonts.ps1 -DestinationRoot "..\..\AdminAPI\static\qcf-fonts"

param(
    [string]$SourceDir = (Join-Path $PSScriptRoot '..\assets\fonts\v2woff'),
    [string]$DestinationRoot = (Join-Path $PSScriptRoot '..\..\AdminAPI\static\qcf-fonts')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $SourceDir)) {
    Write-Error "Font source not found: $SourceDir"
}

New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
& robocopy $SourceDir $DestinationRoot '*.woff' /MIR /NFL /NDL /NJH /NJS /NC /NS | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy failed (exit $LASTEXITCODE)"
}

$count = (Get-ChildItem $DestinationRoot -Filter '*.woff' -File).Count
Write-Host "Synced $count QCF fonts to $DestinationRoot"
Write-Host "Served at: /static/qcf-fonts/p{N}.woff (AdminAPI QcfFontStorage)"
