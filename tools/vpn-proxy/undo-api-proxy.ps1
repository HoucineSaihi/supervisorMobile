<#
.SYNOPSIS
    Removes everything start-api-proxy.ps1 created.

.DESCRIPTION
    Deletes the TCP port forward and the inbound firewall rule, returning the
    PC to its original state. Safe to run twice, or when nothing is set up.

.NOTES
    Requires Administrator (self-elevates).
#>

[CmdletBinding()]
param(
    [int]$Port = 7070,

    # Defaults to the Windows Mobile Hotspot address.
    [string]$ListenAddress = '192.168.137.1'
)

$ErrorActionPreference = 'Stop'
$FirewallRuleName = "ShopConnect APK test proxy $Port"

# --- Self-elevate -----------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator rights required - re-launching elevated..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-NoExit'
            '-File',"`"$PSCommandPath`""
            '-Port',$Port
            '-ListenAddress',$ListenAddress
        ) | Out-Null
    } catch {
        Write-Host "Elevation was refused." -ForegroundColor Red
        exit 1
    }
    exit 0
}

function Write-Ok($text)   { Write-Host "    OK   $text" -ForegroundColor Green }
function Write-Info($text) { Write-Host "    ---  $text" -ForegroundColor DarkGray }

Write-Host "=========================================================" -ForegroundColor White
Write-Host " Removing the ShopConnect API test proxy"                  -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor White

$removed = $false

# --- 1. Port forward --------------------------------------------------------
Write-Host "`n[1] Removing the port forward" -ForegroundColor Cyan

$existing = netsh interface portproxy show v4tov4 | Out-String
if ($existing -match [regex]::Escape($ListenAddress)) {
    netsh interface portproxy delete v4tov4 `
          listenport=$Port listenaddress=$ListenAddress 2>&1 | Out-Null
    Write-Ok "Removed ${ListenAddress}:$Port"
    $removed = $true
} else {
    Write-Info "No port forward on ${ListenAddress}:$Port"
}

# Catch a rule left on a different hotspot address.
$leftovers = netsh interface portproxy show v4tov4 | Out-String
if ($leftovers -match "\s$Port\s") {
    Write-Info "Note: another forward on port $Port still exists:"
    Write-Host $leftovers -ForegroundColor DarkGray
}

# --- 2. Firewall ------------------------------------------------------------
Write-Host "`n[2] Removing the firewall rule" -ForegroundColor Cyan

$rule = Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue
if ($rule) {
    $rule | Remove-NetFirewallRule
    Write-Ok "Removed '$FirewallRuleName'"
    $removed = $true
} else {
    Write-Info "No firewall rule named '$FirewallRuleName'"
}

# --- Done -------------------------------------------------------------------
Write-Host "`n=========================================================" -ForegroundColor Green
if ($removed) {
    Write-Host " CLEANED UP - the PC is back to its original state"     -ForegroundColor Green
} else {
    Write-Host " NOTHING TO DO - no proxy was configured"               -ForegroundColor Green
}
Write-Host "=========================================================" -ForegroundColor Green

Write-Host "`n  Remember to point the APK back at the normal URL" -ForegroundColor Yellow
Write-Host "  before building a production release.`n"
Read-Host "Press Enter to close"
