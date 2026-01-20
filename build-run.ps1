# Complete Build and Run Script
param([string]$Port = "8080")

$ProjectRoot = $PSScriptRoot
$SolutionFile = "GadgetsOnlineWebForms.sln"
$WebAppPath = Join-Path $ProjectRoot "GadgetsOnlineWebForms"
$IISExpressPath = "C:\Program Files\IIS Express\iisexpress.exe"
$URL = "http://localhost:$Port"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Blue }

Write-Step "GadgetsOnline Complete Build and Run"
Write-Info "URL: $URL"

# Step 1: Check prerequisites
Write-Step "Step 1: Prerequisites"
if (!(Test-Path $SolutionFile)) { 
    Write-Error "Solution file not found"
    exit 1
}
Write-Success "Solution file found"

# Step 2: Install IIS Express
Write-Step "Step 2: IIS Express Setup"
if (!(Test-Path $IISExpressPath)) {
    Write-Info "Installing IIS Express..."
    $url = "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C2F35/iisexpress_amd64_en-US.msi"
    Invoke-WebRequest -Uri $url -OutFile "iisexpress.msi" -UseBasicParsing
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "iisexpress.msi", "/quiet" -Wait
    Remove-Item "iisexpress.msi" -Force
    Write-Success "IIS Express installed"
} else { 
    Write-Success "IIS Express ready"
}

# Step 3: Cleanup
Write-Step "Step 3: Cleanup"
Get-Process -Name "iisexpress" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Success "Cleanup done"

# Step 4: Restore packages
Write-Step "Step 4: Restore Packages"
dotnet restore $SolutionFile
Write-Success "Packages restored"

# Step 5: Build
Write-Step "Step 5: Build Solution"
dotnet build $SolutionFile --configuration Debug --no-restore
Write-Success "Build completed"

# Step 6: Start server
Write-Step "Step 6: Start Server"
$process = Start-Process -FilePath $IISExpressPath -ArgumentList "/path:`"$WebAppPath`"", "/port:$Port" -PassThru
Start-Sleep -Seconds 4

# Step 7: Test and open
Write-Step "Step 7: Launch Application"
$response = Invoke-WebRequest -Uri $URL -UseBasicParsing -TimeoutSec 10
Write-Success "Server running (HTTP $($response.StatusCode))"
Start-Process $URL
Write-Success "Browser opened"

Write-Host "`n=== APPLICATION READY ===" -ForegroundColor Green
Write-Host "URL: $URL" -ForegroundColor Green
Write-Host "Process ID: $($process.Id)" -ForegroundColor Green
Write-Host "`nPress Ctrl+C to stop..." -ForegroundColor Yellow

try {
    while (!$process.HasExited) { Start-Sleep 1 }
} catch {
    if ($process -and !$process.HasExited) { $process.Kill() }
}