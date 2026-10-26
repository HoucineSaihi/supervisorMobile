<#
.SYNOPSIS
    Exposes the ShopConnect API (reachable only through the FortiClient VPN)
    to an Android test device connected to this PC's Mobile Hotspot.

.DESCRIPTION
    The APK targets http://shopconnect.exoticgroup.net:7070, which resolves to
    a public IP that is NOT reachable (blocked on every port). The API is only
    reachable at a private address routed by the FortiClient split tunnel.

    This script forwards  <hotspot-ip>:7070  ->  <vpn-api-ip>:7070  at the TCP
    level, so WebSockets (SignalR notifications) and multipart file uploads
    pass through untouched.

    Run undo-api-proxy.ps1 when testing is finished.

.NOTES
    Requires Administrator (self-elevates).
    Test use only. Confirm with the client's IT/security team that forwarding
    VPN traffic to a test device is permitted.
#>

[CmdletBinding()]
param(
    # API port on both sides.
    [int]$Port = 7070,

    # Private API address behind the VPN. Auto-detected when omitted.
    [string]$ApiAddress,

    # Hotspot address the phone connects to. Auto-detected when omitted.
    [string]$ListenAddress,

    # Skip the upstream reachability check.
    [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
$FirewallRuleName = "ShopConnect APK test proxy $Port"

# --- Self-elevate -----------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator rights required - re-launching elevated..." -ForegroundColor Yellow
    $argList = @(
        '-NoProfile'
        '-ExecutionPolicy','Bypass'
        '-NoExit'
        '-File',"`"$PSCommandPath`""
        '-Port',$Port
    )
    if ($ApiAddress)    { $argList += @('-ApiAddress',$ApiAddress) }
    if ($ListenAddress) { $argList += @('-ListenAddress',$ListenAddress) }
    if ($SkipChecks)    { $argList += '-SkipChecks' }
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList $argList | Out-Null
    } catch {
        Write-Host "Elevation was refused. Right-click the script and pick 'Run with PowerShell' as admin." -ForegroundColor Red
        exit 1
    }
    exit 0
}

function Write-Step($n, $text) { Write-Host "`n[$n] $text" -ForegroundColor Cyan }
function Write-Ok($text)       { Write-Host "    OK   $text" -ForegroundColor Green }
function Write-Fail($text)     { Write-Host "    FAIL $text" -ForegroundColor Red }
function Write-Info($text)     { Write-Host "    ---  $text" -ForegroundColor DarkGray }

Write-Host "=========================================================" -ForegroundColor White
Write-Host " ShopConnect API proxy for Android testing over the VPN"  -ForegroundColor White
Write-Host "=========================================================" -ForegroundColor White

# --- 1. VPN present? --------------------------------------------------------
Write-Step 1 "Checking the FortiClient VPN connection"

$vpnAdapter = Get-NetAdapter |
    Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -match 'Fortinet' } |
    Select-Object -First 1

if (-not $vpnAdapter) {
    Write-Fail "No active Fortinet adapter found."
    Write-Host "`n    Connect FortiClient first, then run this script again." -ForegroundColor Yellow
    Read-Host "`nPress Enter to close"
    exit 1
}
Write-Ok "VPN adapter up: $($vpnAdapter.Name)"

# --- 2. Find the API behind the VPN ----------------------------------------
Write-Step 2 "Locating the API behind the VPN"

if (-not $ApiAddress) {
    # The split tunnel publishes host routes (/32) for the internal servers.
    # Any /32 that is not our own tunnel IP is a candidate upstream.
    $ownIps = (Get-NetIPAddress -InterfaceIndex $vpnAdapter.InterfaceIndex `
                                -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

    $candidates = Get-NetRoute -InterfaceIndex $vpnAdapter.InterfaceIndex `
                               -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DestinationPrefix -match '/32$' -and
            $_.DestinationPrefix -notmatch '^(224\.|255\.)' -and
            ($_.DestinationPrefix -replace '/32$','') -notin $ownIps
        } |
        ForEach-Object { $_.DestinationPrefix -replace '/32$','' } |
        Select-Object -Unique

    if (-not $candidates) {
        Write-Fail "No internal host route found on the VPN adapter."
        Write-Info "Pass the address explicitly:  .\start-api-proxy.ps1 -ApiAddress <ip>"
        Read-Host "`nPress Enter to close"
        exit 1
    }

    Write-Info "Candidate(s) routed by the VPN: $($candidates -join ', ')"
    foreach ($c in $candidates) {
        $t = Test-NetConnection $c -Port $Port -WarningAction SilentlyContinue
        if ($t.TcpTestSucceeded) { $ApiAddress = $c; break }
    }

    if (-not $ApiAddress) {
        Write-Fail "No VPN-routed host is listening on port $Port."
        Write-Info "The VPN may have assigned a different server this session."
        Read-Host "`nPress Enter to close"
        exit 1
    }
}
Write-Ok "API found at ${ApiAddress}:$Port"

# --- 3. Verify it really answers -------------------------------------------
if (-not $SkipChecks) {
    Write-Step 3 "Verifying the API responds"
    $tcp = Test-NetConnection $ApiAddress -Port $Port -WarningAction SilentlyContinue
    if (-not $tcp.TcpTestSucceeded) {
        Write-Fail "Cannot open a TCP connection to ${ApiAddress}:$Port."
        Read-Host "`nPress Enter to close"
        exit 1
    }
    Write-Ok "TCP connection established"

    # Any HTTP status (including 404) proves a web server is answering.
    try {
        $r = Invoke-WebRequest "http://${ApiAddress}:$Port/api" -TimeoutSec 15 `
                               -UseBasicParsing -ErrorAction Stop
        Write-Ok "HTTP $($r.StatusCode) - server is responding"
    } catch {
        if ($_.Exception.Response) {
            Write-Ok "HTTP $([int]$_.Exception.Response.StatusCode) - server is responding"
        } else {
            Write-Info "No HTTP reply, but the TCP port is open - continuing."
        }
    }
} else {
    Write-Step 3 "Skipping upstream checks (-SkipChecks)"
}

# --- 4. Hotspot -------------------------------------------------------------
Write-Step 4 "Checking the Mobile Hotspot"

if (-not $ListenAddress) {
    # Windows Mobile Hotspot always uses 192.168.137.1.
    $hotspot = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object { $_.IPAddress -eq '192.168.137.1' } | Select-Object -First 1
    if ($hotspot) {
        $ListenAddress = $hotspot.IPAddress
    } else {
        Write-Fail "Mobile Hotspot is not running."
        Write-Host ""
        Write-Host "    How to turn it on:" -ForegroundColor Yellow
        Write-Host "      1. Press the Windows key and type: mobile hotspot"
        Write-Host "      2. Open 'Mobile hotspot settings'"
        Write-Host "      3. Switch it ON"
        Write-Host "      4. Connect the test phone to that Wi-Fi network"
        Write-Host "      5. Run this script again"
        Read-Host "`nPress Enter to close"
        exit 1
    }
}
Write-Ok "Hotspot address: $ListenAddress"

# Is the phone actually connected to the hotspot?
$subnet = ($ListenAddress -replace '\.\d+$', '')
$phones = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -like "$subnet.*" -and
                         $_.IPAddress -ne $ListenAddress -and
                         $_.IPAddress -notlike '*.255' -and          # broadcast
                         $_.IPAddress -notlike '224.*' -and          # multicast
                         $_.State -in @('Reachable','Stale','Permanent') }
if ($phones) {
    Write-Ok "Device connected to the hotspot: $(($phones.IPAddress | Select-Object -Unique) -join ', ')"
} else {
    Write-Info "No device detected on the hotspot yet - connect the phone's Wi-Fi to it."
}

# --- 5. Port forward --------------------------------------------------------
Write-Step 5 "Creating the port forward"

# Remove a stale rule from a previous session (the VPN IP can change).
netsh interface portproxy delete v4tov4 `
      listenport=$Port listenaddress=$ListenAddress 2>&1 | Out-Null

netsh interface portproxy add v4tov4 `
      listenport=$Port listenaddress=$ListenAddress `
      connectport=$Port connectaddress=$ApiAddress | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Fail "netsh could not create the port forward."
    Read-Host "`nPress Enter to close"
    exit 1
}
Write-Ok "${ListenAddress}:$Port  ->  ${ApiAddress}:$Port"

# --- 6. Firewall ------------------------------------------------------------
Write-Step 6 "Opening the firewall for the test device"

Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Scoped to the hotspot address only - not exposed on the normal Wi-Fi.
New-NetFirewallRule -DisplayName $FirewallRuleName `
                    -Direction Inbound -Action Allow -Protocol TCP `
                    -LocalPort $Port -LocalAddress $ListenAddress | Out-Null
Write-Ok "Inbound TCP $Port allowed on $ListenAddress only"

# --- 7. Prove the whole chain works ----------------------------------------
Write-Step 7 "Testing the proxy end to end"

$proxyWorks = $false
try {
    # Hits the proxy exactly as the phone will. Any HTTP status means the
    # request reached the API and came back.
    $r = Invoke-WebRequest "http://${ListenAddress}:$Port/api" -TimeoutSec 20 `
                           -UseBasicParsing -ErrorAction Stop
    Write-Ok "Proxy replied: HTTP $($r.StatusCode)"
    $proxyWorks = $true
} catch {
    if ($_.Exception.Response) {
        Write-Ok "Proxy replied: HTTP $([int]$_.Exception.Response.StatusCode) - working"
        $proxyWorks = $true
    } else {
        Write-Fail "The proxy did not answer: $($_.Exception.Message)"
    }
}

# --- Done -------------------------------------------------------------------
if ($proxyWorks) {
    Write-Host "`n=========================================================" -ForegroundColor Green
    Write-Host " READY - THE PROXY IS WORKING"                             -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
} else {
    Write-Host "`n=========================================================" -ForegroundColor Yellow
    Write-Host " SET UP, BUT THE TEST REQUEST FAILED"                      -ForegroundColor Yellow
    Write-Host "=========================================================" -ForegroundColor Yellow
    Write-Host " The rules were created but the API did not reply."        -ForegroundColor Yellow
    Write-Host " Check that FortiClient is still connected, then re-run."  -ForegroundColor Yellow
}
Write-Host "`n  The app must use this address:" -ForegroundColor White
Write-Host "      http://${ListenAddress}:$Port" -ForegroundColor Yellow
Write-Host "`n  While testing, keep ALL of this true:" -ForegroundColor White
Write-Host "      - FortiClient stays connected on this PC"
Write-Host "      - Mobile Hotspot stays on"
Write-Host "      - The phone stays connected to that hotspot"
Write-Host "      - The VPN is NOT connected on the phone" -ForegroundColor Yellow
Write-Host "`n  When you finish testing, double-click 'STOP PROXY.bat'." -ForegroundColor White
Write-Host "`n  Upstream: ${ApiAddress}:$Port (via $($vpnAdapter.Name))" -ForegroundColor DarkGray
Write-Host ""
Read-Host "Press Enter to close"
