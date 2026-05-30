#!/bin/bash
# Watcher: prüft alle 30 Minuten, ob HomeDash in der App-Store-Suche
# auftaucht (DE oder US). GARANTIERT EINMALIG:
#   - State-File verhindert Re-Trigger (auch nach Mac-Neustart)
#   - launchd-Job entlädt sich selbst nach erstem Hit
#   - Beide Mechanismen unabhängig: einer reicht
#
# Manuell stoppen:
#   launchctl unload ~/Library/LaunchAgents/de.marcel.homedash.searchwatch.plist
#
# Manuell zurücksetzen (für Test):
#   rm ~/.homedash-watcher-fired

set -euo pipefail

APP_ID="6772391873"
SEARCH_TERM="HomeDash"
LOG="$HOME/Library/Logs/homedash-searchwatch.log"
STATE_FILE="$HOME/.homedash-watcher-fired"
RECIPIENT="marsoen@outlook.de"
PLIST="$HOME/Library/LaunchAgents/de.marcel.homedash.searchwatch.plist"

ts() { date "+%Y-%m-%d %H:%M:%S"; }
log() { echo "[$(ts)] $*" >> "$LOG"; }

# 🛡️ Sicherheit 1: wenn schon gefeuert, sofort raus
if [ -f "$STATE_FILE" ]; then
    log "Bereits gefeuert (State-File existiert) – stoppe Job zur Sicherheit."
    launchctl unload "$PLIST" 2>/dev/null || true
    exit 0
fi

found=0
hit_country=""
hit_url=""

# Test in DE und US
for country in de us; do
    result=$(curl -s --max-time 15 \
        "https://itunes.apple.com/search?term=${SEARCH_TERM}&country=${country}&entity=tvSoftware&limit=10" \
        2>/dev/null || echo '{"results":[]}')

    if echo "$result" | grep -q "\"trackId\":${APP_ID}"; then
        found=1
        hit_country="$country"
        hit_url=$(echo "$result" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for r in d.get('results', []):
        if r.get('trackId') == ${APP_ID}:
            print(r.get('trackViewUrl', ''))
            break
except: pass
" 2>/dev/null || echo "https://apps.apple.com/${country}/app/id${APP_ID}")
        break
    fi
done

if [ "$found" = "1" ]; then
    # 🛡️ Sicherheit 2: State sofort schreiben, BEVOR irgendwas anderes
    # passiert. Selbst wenn die Notification/Mail-Schritte fehlschlagen,
    # wird der nächste Run sofort sehen "schon gefeuert" und stoppen.
    echo "$(ts) | $hit_country | $hit_url" > "$STATE_FILE"
    log "✅ TREFFER in $hit_country: $hit_url"
    log "State-File geschrieben: $STATE_FILE"

    # macOS-Notification
    osascript -e "display notification \"HomeDash ist jetzt im App Store ($hit_country) auffindbar! $hit_url\" with title \"🎉 HomeDash in App-Store-Suche\" sound name \"Glass\"" 2>/dev/null || true

    # Mail an dich selbst
    osascript <<EOF 2>/dev/null || true
tell application "Mail"
    set newMsg to make new outgoing message with properties {subject:"🎉 HomeDash ist in App-Store-Suche aufgetaucht ($hit_country)", content:"Glückwunsch! Deine App ist jetzt über die Suche nach \"HomeDash\" im ${hit_country}-Store auffindbar.

Direkt-Link: $hit_url

Der Watcher hat sich automatisch beendet — keine weiteren Mails.", visible:false}
    tell newMsg
        make new to recipient at end of to recipients with properties {address:"$RECIPIENT"}
    end tell
    send newMsg
end tell
EOF
    log "Mail an $RECIPIENT abgeschickt"

    # 🛡️ Sicherheit 3: Watcher entladen
    if [ -f "$PLIST" ]; then
        launchctl unload "$PLIST" 2>/dev/null || true
        log "Watcher entladen, Mission complete."
    fi
else
    log "Noch kein Treffer (DE+US geprüft)."
fi
