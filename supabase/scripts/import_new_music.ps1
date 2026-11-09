[CmdletBinding()]
param(
  [string]$MusicDirectory = (Join-Path $PSScriptRoot '..\..\..\music_data'),
  [string]$MetadataCsv = (Join-Path $PSScriptRoot '..\music_metadata_new.csv')
)

$ErrorActionPreference = 'Stop'
$projectUrl = 'https://whrcqwmovmhphfilckep.supabase.co'
$importer = Join-Path $PSScriptRoot 'import_tracks.mjs'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Node.js is required. Install Node.js, reopen PowerShell, and run this script again.'
}
if (-not (Test-Path -LiteralPath $MusicDirectory -PathType Container)) {
  throw "Music folder not found: $MusicDirectory"
}
if (-not (Test-Path -LiteralPath $MetadataCsv -PathType Leaf)) {
  throw "Metadata CSV not found: $MetadataCsv"
}

$musicPath = (Resolve-Path -LiteralPath $MusicDirectory).Path
$metadataPath = (Resolve-Path -LiteralPath $MetadataCsv).Path
$musicFiles = @(Get-ChildItem -LiteralPath $musicPath -File -Filter '*.mp3' | ForEach-Object Name)
$metadataRows = @(Import-Csv -LiteralPath $metadataPath)
if ($metadataRows.Count -eq 0) {
  throw "Metadata CSV has no data rows: $metadataPath"
}
if (-not ($metadataRows[0].PSObject.Properties.Name -contains 'filename')) {
  throw "Metadata CSV must contain a filename column: $metadataPath"
}

$duplicateNames = @($metadataRows | Group-Object filename | Where-Object Count -gt 1 | ForEach-Object Name)
$musicNameSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($name in $musicFiles) { [void]$musicNameSet.Add($name) }
$csvNameSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($row in $metadataRows) { [void]$csvNameSet.Add($row.filename) }
$missingRows = @($musicFiles | Where-Object { -not $csvNameSet.Contains($_) })
$unknownFiles = @($metadataRows | Where-Object { -not $musicNameSet.Contains($_.filename) } | ForEach-Object filename)
if ($duplicateNames.Count -or $missingRows.Count -or $unknownFiles.Count) {
  $problems = @()
  if ($duplicateNames.Count) { $problems += "duplicate CSV filenames: $($duplicateNames -join ', ')" }
  if ($missingRows.Count) { $problems += "MP3 files missing from CSV: $($missingRows -join ', ')" }
  if ($unknownFiles.Count) { $problems += "CSV filenames not found in music folder: $($unknownFiles -join ', ')" }
  throw "Music folder and metadata CSV do not match ($($problems -join '; ')). Check the selected batch and CSV."
}

$oldUrl = $env:SUPABASE_URL
$oldKey = $env:SUPABASE_SERVICE_ROLE_KEY
$secretPointer = [IntPtr]::Zero
$exitCode = 1

try {
  if ([string]::IsNullOrWhiteSpace($oldKey)) {
    $secureKey = Read-Host 'Paste the Supabase service role/Secret key' -AsSecureString
    $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $env:SUPABASE_SERVICE_ROLE_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
  }
  if ([string]::IsNullOrWhiteSpace($env:SUPABASE_SERVICE_ROLE_KEY)) {
    throw 'A Supabase service role/Secret key is required.'
  }

  $env:SUPABASE_URL = $projectUrl
  Write-Host "Importing MP3 files from: $musicPath"
  Write-Host "Using metadata: $metadataPath"
  & node $importer $musicPath $metadataPath
  $exitCode = $LASTEXITCODE
} finally {
  if ($secretPointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
  }
  if ($null -eq $oldKey) {
    Remove-Item Env:SUPABASE_SERVICE_ROLE_KEY -ErrorAction SilentlyContinue
  } else {
    $env:SUPABASE_SERVICE_ROLE_KEY = $oldKey
  }
  if ($null -eq $oldUrl) {
    Remove-Item Env:SUPABASE_URL -ErrorAction SilentlyContinue
  } else {
    $env:SUPABASE_URL = $oldUrl
  }
}

exit $exitCode
