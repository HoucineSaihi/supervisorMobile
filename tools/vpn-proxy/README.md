# Testing the APK against the ShopConnect API over the VPN

The app's API is on a private network reachable only through the FortiClient
VPN. An Android phone cannot reach it directly, and connecting the phone to the
PC's Mobile Hotspot is **not** enough on its own.

These scripts make the PC forward the API to the phone.

---

## For the tester — the short version

1. **Connect FortiClient** on this PC and sign in.
2. **Turn on Mobile Hotspot**
   (Settings → Network & Internet → Mobile hotspot).
3. **Connect the phone** to that hotspot.
4. **Double-click `START PROXY.bat`** and approve the Windows admin prompt.
5. The script prints a URL like `http://192.168.137.1:7070`.
   The test APK must be pointed at that URL.
6. Test the app.
7. **Double-click `STOP PROXY.bat`** when finished.

Leave FortiClient connected and the PC awake for the whole session.

---

## What the scripts do

`START PROXY.bat` → `start-api-proxy.ps1`

1. Checks that the FortiClient VPN is connected.
2. Finds the API server automatically by reading the VPN's routing table.
3. Verifies the server really answers on port 7070.
4. Finds the Mobile Hotspot address.
5. Creates a TCP port forward: `hotspot:7070` → `api-server:7070`.
6. Opens the Windows Firewall for port 7070 **on the hotspot address only**.

`STOP PROXY.bat` → `undo-api-proxy.ps1` removes items 5 and 6. It is safe to
run twice, or when nothing is set up.

Both scripts request Administrator rights automatically.

---

## Why a TCP forward and not an HTTP proxy

The forward works at the TCP level, so WebSocket traffic (the SignalR
notifications hub) and multipart file uploads pass through untouched. An
HTTP-level proxy has to handle connection-upgrade headers and streaming bodies
correctly or notifications break silently, with no obvious error.

It also needs no extra software: `netsh portproxy` is built into Windows.

---

## Background: why the hotspot alone does not work

The app targets `http://shopconnect.exoticgroup.net:7070`, which resolves to
the public address `197.227.58.162`. That address is **not reachable** — it was
tested and refuses connections on ports 7070, 4020, 80 and 443.

The FortiClient tunnel is a *split tunnel*: it publishes a route for one
internal host only. Everything else, including the public address above, goes
out over the normal internet connection, where it is blocked.

So the API has to be reached at its **private** address, which only this PC can
route. The scripts discover that address automatically each session.

---

## Do NOT connect the VPN on the phone

The VPN account allows **one connection at a time**. Connecting FortiClient on
the test phone with the same account **disconnects this PC**, which breaks the
proxy and makes the API unreachable for both devices.

Symptoms of this happening:

- The phone shows "VPN connected" but every request still times out.
- FortiClient on the PC silently drops to disconnected while still running.

The phone must reach the API **through the hotspot and this PC**, not over its
own VPN connection. Only the PC connects to the VPN.

(Connecting the phone directly to the VPN would also fail for a second reason:
the VPN does not publish an internal DNS server, so the phone resolves
`shopconnect.exoticgroup.net` to a public address that refuses connections.)

---

## Troubleshooting

**"No active Fortinet adapter found"**
FortiClient is not connected. Sign in and re-run.

If FortiClient is running but shows disconnected, check whether anyone has
connected the VPN on another device with the same account - that will have
dropped this session. Disconnect the other device, then reconnect here.

**"Mobile Hotspot is not running"**
Turn it on in Settings, then re-run.

**"No VPN-routed host is listening on port 7070"**
The VPN assigns the server address per session and it may have changed, or the
API is down. Check with the backend team, or pass the address by hand:

```powershell
.\start-api-proxy.ps1 -ApiAddress 10.x.x.x
```

**The app still cannot connect**
- Confirm the phone is on the PC's hotspot, not another Wi-Fi network.
- Confirm the APK is pointed at the URL the script printed.
- Check the forward exists: `netsh interface portproxy show v4tov4`

**The server address changed between sessions**
Just re-run `START PROXY.bat`. It replaces any stale rule automatically.

---

## Notes and limits

- **Test use only.** Confirm with the client's IT/security team that forwarding
  VPN traffic to a test device is permitted before using this on an engagement.
- The firewall rule is scoped to the hotspot address, so the API is not exposed
  on the normal office or home Wi-Fi. Still, run `STOP PROXY.bat` when done.
- Traffic between phone and PC is plain HTTP, readable by other devices on the
  hotspot. Keep the hotspot password-protected and avoid real production
  credentials.
- The private API address is a per-session VPN value. Do not hard-code it into
  a production build.
