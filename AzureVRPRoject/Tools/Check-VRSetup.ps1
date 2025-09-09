# VR Setup Checker for Azure VR Project
Write-Host "=== Azure VR Project Setup Checker ===" -ForegroundColor Cyan
Write-Host ""

# Check if Unity is running
$unityProcesses = Get-Process -Name "Unity" -ErrorAction SilentlyContinue
if ($unityProcesses) {
    Write-Host "✅ Unity is running" -ForegroundColor Green
} else {
    Write-Host "❌ Unity is not running - Please open Unity with your AzureVRPRoject" -ForegroundColor Red
}

# Check for OpenXR runtime
$openXRPath = "$env:LOCALAPPDATA\OpenXR"
if (Test-Path $openXRPath) {
    Write-Host "✅ OpenXR folder found" -ForegroundColor Green
} else {
    Write-Host "⚠️  OpenXR folder not found - Make sure you have a VR runtime installed" -ForegroundColor Yellow
}

# Check for SteamVR
$steamVRPath = "${env:ProgramFiles(x86)}\Steam\steamapps\common\SteamVR"
if (Test-Path $steamVRPath) {
    Write-Host "✅ SteamVR found" -ForegroundColor Green
} else {
    Write-Host "ℹ️  SteamVR not found (OK if using Oculus or WMR)" -ForegroundColor Blue
}

# Check for Oculus software
$oculusPath = "${env:ProgramFiles}\Oculus"
if (Test-Path $oculusPath) {
    Write-Host "✅ Oculus software found" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Oculus software not found (OK if using SteamVR or WMR)" -ForegroundColor Blue
}

# Check USB devices for VR headsets
Write-Host ""
Write-Host "Checking USB devices for VR headsets..." -ForegroundColor Yellow
$usbDevices = Get-WmiObject -Class Win32_USBHub | Where-Object { 
    $_.Name -like "*Oculus*" -or 
    $_.Name -like "*HTC*" -or 
    $_.Name -like "*Valve*" -or
    $_.Name -like "*Mixed Reality*" -or
    $_.Name -like "*WMR*"
}

if ($usbDevices) {
    foreach ($device in $usbDevices) {
        Write-Host "✅ Found VR device: $($device.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  No VR headsets detected via USB" -ForegroundColor Yellow
    Write-Host "   Make sure your headset is connected and powered on" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Open Unity with your AzureVRPRoject"
Write-Host "2. Go to Tools > AzureVR > Generate Sample Scene"
Write-Host "3. Set your Azure AD Client ID in the Auth GameObject"
Write-Host "4. Put on your headset and click Play!"
Write-Host ""
Write-Host "Need help? Check the QUICKSTART.md file for detailed instructions." -ForegroundColor Gray
