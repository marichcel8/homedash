#!/bin/sh
# Startet die HomeDash Test-Bridge (Homebridge + Testsensoren + Testbild-Kamera).
# Einmalig: Ordner ~/homebridge-test anlegen, siehe docs/homekit-testgeraete.md.
set -e
DIR="${HOMEDASH_BRIDGE_DIR:-$HOME/homebridge-test}"
cd "$DIR"
exec ./node_modules/.bin/homebridge -U ./storage -P ./node_modules -I
