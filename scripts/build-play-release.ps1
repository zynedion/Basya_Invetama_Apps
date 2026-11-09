param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2100000000)]
    [int]$BuildNumber,
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$BuildName = '1.0.0'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    if (!(Test-Path -LiteralPath 'android/key.properties')) {
        throw 'Isi android/key.properties terlebih dahulu. Lihat docs/release/google-play.md.'
    }
    $flutter = (Get-Command flutter -ErrorAction Stop).Source
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal.' }
    & $flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze belum lolos.' }
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test belum lolos.' }
    & $flutter build appbundle --release --build-name $BuildName --build-number $BuildNumber
    if ($LASTEXITCODE -ne 0) { throw 'Build AAB gagal.' }
    $bundle = Join-Path $projectRoot 'build/app/outputs/bundle/release/app-release.aab'
    if (!(Test-Path -LiteralPath $bundle)) { throw 'AAB tidak ditemukan.' }
    Get-Item -LiteralPath $bundle | Select-Object FullName, Length, LastWriteTime
    Get-FileHash -LiteralPath $bundle -Algorithm SHA256
    Write-Host 'AAB selesai. Uji melalui Internal testing sebelum mengajukan produksi.'
} finally {
    Pop-Location
}
