# Complete Build and Run Script - All Steps
param([string]$Port = "8080")

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$SolutionFile = "GadgetsOnlineWebForms.sln"
$WebAppPath = Join-Path $ProjectRoot "GadgetsOnlineWebForms"
$IISExpressPath = "C:\Program Files\IIS Express\iisexpress.exe"
$URL = "http://localhost:$Port"

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Error($msg) { Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "ℹ️  $msg" -ForegroundColor Blue }

Write-Step "GadgetsOnline Complete Build and Run Script"
Write-Info "URL: $URL | Port: $Port"

# Step 1: Prerequisites
Write-Step "Step 1: Checking Prerequisites"
if (!(Test-Path $SolutionFile)) { 
    Write-Error "Solution file not found"
    exit 1
}
Write-Success "Solution file found"

# Step 2: Install IIS Express if needed
Write-Step "Step 2: Installing IIS Express"
if (!(Test-Path $IISExpressPath)) {
    Write-Info "Downloading IIS Express..."
    $url = "https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C2F35/iisexpress_amd64_en-US.msi"
    Invoke-WebRequest -Uri $url -OutFile "iisexpress.msi" -UseBasicParsing
    Write-Info "Installing..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "iisexpress.msi", "/quiet" -Wait
    Remove-Item "iisexpress.msi" -Force
    Write-Success "IIS Express installed"
} else { 
    Write-Success "IIS Express found" 
}

# Step 3: Stop existing processes
Write-Step "Step 3: Cleanup Existing Processes"
Get-Process -Name "iisexpress" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Success "Cleanup completed"

# Step 4: Restore packages
Write-Step "Step 4: Restoring NuGet Packages"
dotnet restore $SolutionFile
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Package restore failed"
    exit 1
}
Write-Success "Packages restored"

# Step 5: Build solution
Write-Step "Step 5: Building Solution"
dotnet build $SolutionFile --configuration Debug --no-restore
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Build failed"
    exit 1
}
Write-Success "Build completed"
# Step 6: Verify build
Write-Step "Step 6: Verifying Build Output"
$buildOutput = Join-Path $WebAppPath "bin\GadgetsOnlineWebForms.dll"
if (!(Test-Path $buildOutput)) { 
    Write-Error "Build output not found"
    exit 1
}
Write-Success "Build verified"

# Step 7: Start server
Write-Step "Step 7: Starting IIS Express"
Write-Info "Starting server on $URL..."
$process = Start-Process -FilePath $IISExpressPath -ArgumentList "/path:`"$WebAppPath`"", "/port:$Port" -PassThru
Start-Sleep -Seconds 4

# Step 8: Test connection
Write-Step "Step 8: Testing Connection"
try {
    $response = Invoke-WebRequest -Uri $URL -UseBasicParsing -TimeoutSec 10
    Write-Success "Server responding (HTTP $($response.StatusCode))"
} catch {
    Write-Error "Server test failed: $($_.Exception.Message)"
    if ($process -and !$process.HasExited) {
        $process.Kill()
    }
    exit 1
}

# Step 9: Open browser
Write-Step "Step 9: Opening Browser"
Start-Process $URL
Write-Success "Browser opened"

# Step 10: Final status
Write-Step "🎉 APPLICATION READY!"
Write-Host @"

┌─────────────────────────────────────────┐
│           SUCCESS!                      │
├─────────────────────────────────────────┤
│ URL: $URL                    │
│ Process ID: $($process.Id)                        │
│ Status: Running                         │
└─────────────────────────────────────────┘

"@ -ForegroundColor Green

Write-Info "Press Ctrl+C to stop the server..."

# Monitor process
try {
    while (!$process.HasExited) { 
        Start-Sleep 1 
    }
    Write-Info "Server process ended"
} catch {
    Write-Info "Stopping server..."
    if ($process -and !$process.HasExited) {
        $process.Kill()
    }
}