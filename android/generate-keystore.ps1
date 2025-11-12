# Generate Android Keystore for DocuMate
$ErrorActionPreference = "Stop"

Write-Host "Generating DocuMate Release Keystore..." -ForegroundColor Green

# Find Java keytool from Android Studio
$possiblePaths = @(
    "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe",
    "C:\Program Files\Java\jdk*\bin\keytool.exe",
    "C:\Program Files\Eclipse Adoptium\*\bin\keytool.exe"
)

$keytool = $null
foreach ($pattern in $possiblePaths) {
    $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytool = $found.FullName
        break
    }
}

if (-not $keytool) {
    Write-Host "Error: Java keytool not found. Please install Java or Android Studio." -ForegroundColor Red
    exit 1
}

Write-Host "Using keytool: $keytool" -ForegroundColor Cyan

# Generate keystore
$keystorePath = Join-Path $PSScriptRoot "documate-release-key.jks"

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists. Removing old one..." -ForegroundColor Yellow
    Remove-Item $keystorePath -Force
}

& $keytool -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias documate -storepass documate123 -keypass documate123 -dname "CN=DocuMate, OU=Mobile, O=DocuMate, L=City, S=State, C=US"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: Keystore generated at: $keystorePath" -ForegroundColor Green
    Write-Host "IMPORTANT: Keep this keystore file safe!" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: Failed to generate keystore" -ForegroundColor Red
    exit 1
}
