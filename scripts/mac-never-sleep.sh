#!/bin/bash
# Arnold booth / office Macs — never sleep, never blank the display.
# Run once in Terminal on the Mac (admin password when prompted):
#   curl -fsSL https://raw.githubusercontent.com/BadBraddA1/host-scripts/main/scripts/mac-never-sleep.sh | bash
# Or copy this file over and:  bash mac-never-sleep.sh

set -euo pipefail

echo "==> Energy settings (AC + battery): no system/display/disk sleep"
sudo pmset -a \
  sleep 0 \
  displaysleep 0 \
  disksleep 0 \
  hibernatemode 0 \
  standby 0 \
  autopoweroff 0 \
  tcpkeepalive 1 \
  powernap 0 \
  womp 1

# Belt-and-suspenders: LaunchAgent runs caffeinate at login
AGENT_DIR="${HOME}/Library/LaunchAgents"
AGENT_LABEL="org.arnoldcoc.keepawake"
AGENT_PLIST="${AGENT_DIR}/${AGENT_LABEL}.plist"
mkdir -p "${AGENT_DIR}"

cat > "${AGENT_PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${AGENT_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/caffeinate</string>
    <string>-dims</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${AGENT_PLIST}"
launchctl enable "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
launchctl kickstart -k "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || launchctl load "${AGENT_PLIST}" 2>/dev/null || true

echo
echo "==> pmset now:"
pmset -g custom | sed 's/^/  /'
echo
echo "==> caffeinate agent: ${AGENT_PLIST}"
if pgrep -x caffeinate >/dev/null; then
  echo "  caffeinate is running"
else
  echo "  (caffeinate starts at next login if not visible yet — log out/in or reboot once)"
fi
echo
echo "Done. Display and Mac should stay awake on power."
