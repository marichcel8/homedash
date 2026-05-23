#!/bin/bash
# Baut ein Release-Archive von HomeDash für App-Store-Distribution.
# Voraussetzung: Signing-Team in Xcode konfiguriert, App-ID auf
# developer.apple.com mit HomeKit-Capability angelegt.
#
# Nutzung:
#   ./scripts/archive.sh

set -euo pipefail

cd "$(dirname "$0")/.."

ARCHIVE_PATH="${ARCHIVE_PATH:-build/HomeDash.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-build/Export}"

echo "→ Bereinige alten Build-Output…"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p build

echo "→ Baue Archive (Release, generic tvOS) …"
xcodebuild -scheme HomeDash \
  -configuration Release \
  -destination 'generic/platform=tvOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME=LaunchImage \
  archive

echo
echo "✅ Archive erfolgreich erstellt: $ARCHIVE_PATH"
echo
echo "Nächste Schritte:"
echo "  1. Xcode → Window → Organizer → Archive auswählen"
echo "  2. Distribute App → App Store Connect → Upload"
echo "  3. Warten bis Build in App Store Connect erscheint (~15 min)"
echo "  4. App Store Connect → TestFlight oder App Store Submission"
