#!/usr/bin/env python3
"""
App Store Connect API CLI für HomeDash.

Auth: ES256-JWT, signiert mit dem lokalen .p8-Private-Key.
Der Private Key verlässt NIE die Maschine; es wird nur ein kurzlebiges
(10-Min-)JWT generiert und im Authorization-Header mitgeschickt.

Konfiguration (in dieser Reihenfolge):
  1. Umgebungsvariablen ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
  2. ~/.appstoreconnect/config.json  {"key_id":..., "issuer_id":..., "key_path":...}
  3. Defaults: key in ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8

Befehle:
  status                      Übersicht: App, Versionen + States, Builds
  prepare-version <version>   Neue appStoreVersion anlegen (falls erlaubt)
  set-whatsnew <version>      "What's New"-Text (DE+EN) aus whatsnew/ setzen
  attach-build <version> <buildNumber>   Build einer Version zuordnen
  raw <GET-path>              Beliebiger GET-Call (debug), z.B. raw /v1/apps
"""
import sys, os, json, time, glob, warnings
warnings.filterwarnings("ignore")  # LibreSSL/urllib3-Noise unterdrücken
import jwt  # PyJWT
import requests

BUNDLE_ID = "de.marcel.homedash"
API = "https://api.appstoreconnect.apple.com"


def load_config():
    cfg = {}
    cfg_file = os.path.expanduser("~/.appstoreconnect/config.json")
    if os.path.exists(cfg_file):
        with open(cfg_file) as f:
            cfg.update(json.load(f))
    cfg["key_id"] = os.environ.get("ASC_KEY_ID", cfg.get("key_id"))
    cfg["issuer_id"] = os.environ.get("ASC_ISSUER_ID", cfg.get("issuer_id"))
    cfg["key_path"] = os.environ.get("ASC_KEY_PATH", cfg.get("key_path"))

    # Key-Pfad automatisch finden, falls nicht gesetzt
    if not cfg.get("key_path"):
        if cfg.get("key_id"):
            guess = os.path.expanduser(
                f"~/.appstoreconnect/private_keys/AuthKey_{cfg['key_id']}.p8")
            if os.path.exists(guess):
                cfg["key_path"] = guess
        else:
            found = glob.glob(os.path.expanduser(
                "~/.appstoreconnect/private_keys/AuthKey_*.p8"))
            if len(found) == 1:
                cfg["key_path"] = found[0]
                # Key-ID aus Dateiname ableiten
                base = os.path.basename(found[0])
                cfg["key_id"] = base[len("AuthKey_"):-len(".p8")]

    missing = [k for k in ("key_id", "issuer_id", "key_path") if not cfg.get(k)]
    if missing:
        sys.exit(
            "FEHLT: " + ", ".join(missing) + "\n"
            "Setze ASC_ISSUER_ID (und ggf. ASC_KEY_ID/ASC_KEY_PATH) als Env-Var\n"
            "oder lege ~/.appstoreconnect/config.json an.")
    if not os.path.exists(cfg["key_path"]):
        sys.exit(f"Key-Datei nicht gefunden: {cfg['key_path']}")
    return cfg


def make_token(cfg):
    with open(cfg["key_path"]) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": cfg["issuer_id"],
        "iat": now,
        "exp": now + 600,          # 10 Minuten
        "aud": "appstoreconnect-v1",
    }
    headers = {"alg": "ES256", "kid": cfg["key_id"], "typ": "JWT"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def api(cfg, method, path, **kwargs):
    token = make_token(cfg)
    url = path if path.startswith("http") else API + path
    headers = kwargs.pop("headers", {})
    headers["Authorization"] = f"Bearer {token}"
    headers.setdefault("Content-Type", "application/json")
    r = requests.request(method, url, headers=headers, **kwargs)
    if r.status_code >= 400:
        print(f"--- HTTP {r.status_code} {method} {path} ---", file=sys.stderr)
        try:
            print(json.dumps(r.json(), indent=2), file=sys.stderr)
        except Exception:
            print(r.text, file=sys.stderr)
        r.raise_for_status()
    return r.json() if r.text else {}


def get_app(cfg):
    data = api(cfg, "GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    if not data.get("data"):
        sys.exit(f"Keine App mit Bundle-ID {BUNDLE_ID} gefunden.")
    return data["data"][0]


def cmd_status(cfg):
    app = get_app(cfg)
    app_id = app["id"]
    attr = app["attributes"]
    print(f"App: {attr.get('name')}  ({BUNDLE_ID})")
    print(f"  app id: {app_id}")
    print(f"  SKU:    {attr.get('sku')}")
    print(f"  primaryLocale: {attr.get('primaryLocale')}")
    print()

    versions = api(cfg, "GET",
                   f"/v1/apps/{app_id}/appStoreVersions?limit=10")
    print("App Store Versionen:")
    for v in versions.get("data", []):
        va = v["attributes"]
        print(f"  • {va.get('versionString'):8} "
              f"[{va.get('appStoreState')}]  "
              f"platform={va.get('platform')}  "
              f"release={va.get('releaseType')}  "
              f"id={v['id']}")
    print()

    builds = api(cfg, "GET",
                 f"/v1/builds?filter[app]={app_id}&limit=10"
                 f"&sort=-uploadedDate")
    print("Builds (neueste zuerst):")
    for b in builds.get("data", []):
        ba = b["attributes"]
        print(f"  • Build {ba.get('version'):4} "
              f"[{ba.get('processingState')}]  "
              f"expired={ba.get('expired')}  "
              f"uploaded={ba.get('uploadedDate')}  "
              f"id={b['id']}")
    if not builds.get("data"):
        print("  (keine Builds hochgeladen)")
    return app_id


def cmd_prepare_version(cfg, version):
    app = get_app(cfg)
    app_id = app["id"]
    # Existiert die Version schon?
    versions = api(cfg, "GET",
                   f"/v1/apps/{app_id}/appStoreVersions?limit=20")
    for v in versions.get("data", []):
        if v["attributes"].get("versionString") == version:
            print(f"Version {version} existiert bereits "
                  f"[{v['attributes'].get('appStoreState')}] id={v['id']}")
            return v["id"]
    # Neu anlegen
    body = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "platform": "TV_OS",
                "versionString": version,
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}}
            },
        }
    }
    res = api(cfg, "POST", "/v1/appStoreVersions", data=json.dumps(body))
    vid = res["data"]["id"]
    print(f"✅ Version {version} angelegt. id={vid}")
    return vid


def cmd_set_whatsnew(cfg, version):
    app = get_app(cfg)
    app_id = app["id"]
    # Version-ID holen
    versions = api(cfg, "GET",
                   f"/v1/apps/{app_id}/appStoreVersions?limit=20")
    vid = None
    for v in versions.get("data", []):
        if v["attributes"].get("versionString") == version:
            vid = v["id"]
            break
    if not vid:
        sys.exit(f"Version {version} nicht gefunden. Erst prepare-version.")

    # whatsNew-Texte laden
    here = os.path.dirname(os.path.abspath(__file__))
    texts = {}
    for loc, fname in (("de-DE", "whatsnew_de.txt"), ("en-US", "whatsnew_en.txt")):
        p = os.path.join(here, "whatsnew", fname)
        if os.path.exists(p):
            with open(p) as f:
                texts[loc] = f.read().strip()
    if not texts:
        sys.exit("Keine whatsnew_*.txt in scripts/whatsnew/ gefunden.")

    # Bestehende Localizations holen
    locs = api(cfg, "GET",
               f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")
    existing = {l["attributes"]["locale"]: l["id"] for l in locs.get("data", [])}

    for locale, whatsnew in texts.items():
        if locale in existing:
            body = {"data": {"type": "appStoreVersionLocalizations",
                             "id": existing[locale],
                             "attributes": {"whatsNew": whatsnew}}}
            api(cfg, "PATCH",
                f"/v1/appStoreVersionLocalizations/{existing[locale]}",
                data=json.dumps(body))
            print(f"✅ {locale}: whatsNew aktualisiert")
        else:
            body = {"data": {"type": "appStoreVersionLocalizations",
                             "attributes": {"locale": locale,
                                            "whatsNew": whatsnew},
                             "relationships": {"appStoreVersion": {
                                 "data": {"type": "appStoreVersions",
                                          "id": vid}}}}}
            api(cfg, "POST", "/v1/appStoreVersionLocalizations",
                data=json.dumps(body))
            print(f"✅ {locale}: whatsNew neu angelegt")


def cmd_set_compliance(cfg, build_number, uses_encryption):
    """Setzt usesNonExemptEncryption auf dem Build (Export-Compliance)."""
    app = get_app(cfg)
    app_id = app["id"]
    builds = api(cfg, "GET",
                 f"/v1/builds?filter[app]={app_id}"
                 f"&filter[version]={build_number}&limit=1")
    if not builds.get("data"):
        sys.exit(f"Build {build_number} nicht gefunden.")
    bid = builds["data"][0]["id"]
    val = (str(uses_encryption).lower() == "true")
    body = {"data": {"type": "builds", "id": bid,
                     "attributes": {"usesNonExemptEncryption": val}}}
    api(cfg, "PATCH", f"/v1/builds/{bid}", data=json.dumps(body))
    print(f"✅ Build {build_number}: usesNonExemptEncryption = {val}")


def cmd_submit(cfg, version):
    """Reicht eine appStoreVersion zur Prüfung ein (moderne reviewSubmissions-API)."""
    app = get_app(cfg)
    app_id = app["id"]
    versions = api(cfg, "GET",
                   f"/v1/apps/{app_id}/appStoreVersions?limit=20")
    vid = None
    for v in versions.get("data", []):
        if v["attributes"].get("versionString") == version:
            vid = v["id"]
            break
    if not vid:
        sys.exit(f"Version {version} nicht gefunden.")

    # 1) reviewSubmission anlegen
    body = {"data": {"type": "reviewSubmissions",
                     "attributes": {"platform": "TV_OS"},
                     "relationships": {"app": {"data": {"type": "apps",
                                                        "id": app_id}}}}}
    sub = api(cfg, "POST", "/v1/reviewSubmissions", data=json.dumps(body))
    sub_id = sub["data"]["id"]
    print(f"  reviewSubmission angelegt: {sub_id}")

    # 2) Version als Item hinzufügen
    body = {"data": {"type": "reviewSubmissionItems",
                     "relationships": {
                         "reviewSubmission": {"data": {"type": "reviewSubmissions",
                                                       "id": sub_id}},
                         "appStoreVersion": {"data": {"type": "appStoreVersions",
                                                      "id": vid}}}}}
    api(cfg, "POST", "/v1/reviewSubmissionItems", data=json.dumps(body))
    print(f"  Version {version} als Item hinzugefügt")

    # 3) Submission abschicken
    body = {"data": {"type": "reviewSubmissions", "id": sub_id,
                     "attributes": {"submitted": True}}}
    api(cfg, "PATCH", f"/v1/reviewSubmissions/{sub_id}", data=json.dumps(body))
    print(f"✅ Version {version} zur Prüfung eingereicht (submission {sub_id}).")


def cmd_attach_build(cfg, version, build_number):
    app = get_app(cfg)
    app_id = app["id"]
    versions = api(cfg, "GET",
                   f"/v1/apps/{app_id}/appStoreVersions?limit=20")
    vid = None
    for v in versions.get("data", []):
        if v["attributes"].get("versionString") == version:
            vid = v["id"]
            break
    if not vid:
        sys.exit(f"Version {version} nicht gefunden.")
    builds = api(cfg, "GET",
                 f"/v1/builds?filter[app]={app_id}"
                 f"&filter[version]={build_number}&limit=1")
    if not builds.get("data"):
        sys.exit(f"Build {build_number} nicht gefunden (schon hochgeladen + processed?).")
    bid = builds["data"][0]["id"]
    body = {"data": {"type": "builds", "id": bid}}
    api(cfg, "PATCH", f"/v1/appStoreVersions/{vid}/relationships/build",
        data=json.dumps(body))
    print(f"✅ Build {build_number} (id={bid}) an Version {version} gebunden.")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cfg = load_config()
    cmd = sys.argv[1]
    if cmd == "status":
        cmd_status(cfg)
    elif cmd == "prepare-version":
        cmd_prepare_version(cfg, sys.argv[2])
    elif cmd == "set-whatsnew":
        cmd_set_whatsnew(cfg, sys.argv[2])
    elif cmd == "attach-build":
        cmd_attach_build(cfg, sys.argv[2], sys.argv[3])
    elif cmd == "set-compliance":
        cmd_set_compliance(cfg, sys.argv[2], sys.argv[3])
    elif cmd == "submit":
        cmd_submit(cfg, sys.argv[2])
    elif cmd == "raw":
        print(json.dumps(api(cfg, "GET", sys.argv[2]), indent=2))
    else:
        sys.exit(f"Unbekannter Befehl: {cmd}")


if __name__ == "__main__":
    main()
