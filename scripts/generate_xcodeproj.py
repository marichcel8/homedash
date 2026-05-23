#!/usr/bin/env python3
"""
Erzeugt project.pbxproj für HomeDash (tvOS, SwiftUI, HomeKit) deterministisch.
UUIDs werden aus stabilen Pfaden gehasht, damit der Build reproduzierbar bleibt.
"""
import os
import hashlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_DIR = os.path.join(ROOT, "HomeDash.xcodeproj")
APP_DIR = "HomeDash"


def uid(seed: str) -> str:
    h = hashlib.sha1(seed.encode("utf-8")).hexdigest().upper()
    return h[:24]


SWIFT_FILES = [
    "HomeDashApp.swift",
    "Models/HomeStore.swift",
    "Models/AccessoryKind.swift",
    "Models/FavoritesStore.swift",
    "Extensions/HMAccessory+Kind.swift",
    "Extensions/HMAccessory+State.swift",
    "Extensions/HMService+Helpers.swift",
    "DesignSystem/DesignTokens.swift",
    "DesignSystem/AccessoryPalette.swift",
    "DesignSystem/TileStyle.swift",
    "DesignSystem/TVSliderControl.swift",
    "DesignSystem/FocusOutline.swift",
    "DesignSystem/FocusableTap.swift",
    "Views/ContentView.swift",
    "Views/PermissionView.swift",
    "Views/EmptyStateView.swift",
    "Views/FavoritesSection.swift",
    "Views/HomeDashboardView.swift",
    "Views/HomePickerView.swift",
    "Views/RoomSection.swift",
    "Views/ScenesSection.swift",
    "Views/Tiles/AccessoryTile.swift",
    "Views/Tiles/SceneTile.swift",
    "Views/Detail/AccessoryDetailSheet.swift",
    "Views/Detail/ColorPickerGrid.swift",
    "Views/Detail/DetailCards.swift",
]

RESOURCE_FILES = [
    "Assets.xcassets",
    "PrivacyInfo.xcprivacy",
    "Preview Content/Preview Assets.xcassets",
]

LOCALES = ["de", "en"]
LOCALIZED_FILE = "Localizable.strings"
INFO_PLIST = "Info.plist"
ENTITLEMENTS = "HomeDash.entitlements"

# ---- IDs ----
PROJECT_ID = uid("project.HomeDash")
MAIN_GROUP_ID = uid("group.main")
PRODUCTS_GROUP_ID = uid("group.products")
APP_GROUP_ID = uid("group.app")
MODELS_GROUP_ID = uid("group.models")
VIEWS_GROUP_ID = uid("group.views")
VIEWS_TILES_GROUP_ID = uid("group.views.tiles")
VIEWS_DETAIL_GROUP_ID = uid("group.views.detail")
EXTENSIONS_GROUP_ID = uid("group.extensions")
DESIGN_GROUP_ID = uid("group.design")
RESOURCES_GROUP_ID = uid("group.resources")
PREVIEW_GROUP_ID = uid("group.preview")
LOCALIZATION_GROUP_ID = uid("group.localization")

TARGET_ID = uid("target.HomeDash")
APP_PRODUCT_ID = uid("product.HomeDash.app")
BUILD_CONFIG_LIST_TARGET_ID = uid("buildconfiglist.target")
BUILD_CONFIG_LIST_PROJECT_ID = uid("buildconfiglist.project")
BUILD_CONFIG_DEBUG_TARGET_ID = uid("buildconfig.debug.target")
BUILD_CONFIG_RELEASE_TARGET_ID = uid("buildconfig.release.target")
BUILD_CONFIG_DEBUG_PROJECT_ID = uid("buildconfig.debug.project")
BUILD_CONFIG_RELEASE_PROJECT_ID = uid("buildconfig.release.project")
SOURCES_PHASE_ID = uid("phase.sources")
RESOURCES_PHASE_ID = uid("phase.resources")
FRAMEWORKS_PHASE_ID = uid("phase.frameworks")

LOC_VARIANT_GROUP_ID = uid("variant.localizable")


def file_ref_id(path: str) -> str:
    return uid(f"fileref.{path}")


def build_file_id(path: str, phase: str) -> str:
    return uid(f"buildfile.{phase}.{path}")


# ---- Build Settings als Dicts (Werte sind entweder strings, listen, oder bool-Strings) ----
_BARE_WORD_OK = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")

def fmt_value(v):
    """Formatiere einen pbxproj-Wert. Strings werden ggf. quotiert.
    Bare-word ist nur erlaubt für [a-zA-Z0-9_.]; alles andere quoten."""
    if isinstance(v, list):
        inner = "\n".join(f'\t\t\t\t\t"{item}",' for item in v)
        return "(\n" + inner + "\n\t\t\t\t)"
    if isinstance(v, str):
        if v == "" or any(c not in _BARE_WORD_OK for c in v):
            escaped = v.replace('\\', '\\\\').replace('"', '\\"')
            return f'"{escaped}"'
        return v
    return str(v)


def render_settings(settings: dict) -> str:
    lines = []
    for k in sorted(settings.keys()):
        v = settings[k]
        lines.append(f"\t\t\t\t{k} = {fmt_value(v)};")
    return "\n".join(lines)


# Target-Settings (gleich für Debug + Release)
target_common = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "Brand Assets",
    "CODE_SIGN_ENTITLEMENTS": "HomeDash/HomeDash.entitlements",
    "CODE_SIGN_STYLE": "Automatic",
    "CURRENT_PROJECT_VERSION": "1",
    # Inner quotes sind PFLICHT, weil Xcode den Wert sonst am Leerzeichen splittet.
    "DEVELOPMENT_ASSET_PATHS": '"HomeDash/Preview Content"',
    "DEVELOPMENT_TEAM": "JRKK5F6HH6",
    "ENABLE_PREVIEWS": "YES",
    "GENERATE_INFOPLIST_FILE": "NO",
    "INFOPLIST_FILE": "HomeDash/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName": "HomeDash",
    "INFOPLIST_KEY_UIUserInterfaceStyle": "Dark",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    "MARKETING_VERSION": "1.0.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "de.marcel.homedash",
    "PRODUCT_NAME": "$(TARGET_NAME)",
    "SDKROOT": "appletvos",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "3",
    "TVOS_DEPLOYMENT_TARGET": "17.0",
}

# Projekt-Settings Debug
project_debug = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "MTL_FAST_MATH": "YES",
    "ONLY_ACTIVE_ARCH": "YES",
    "SDKROOT": "appletvos",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG $(inherited)",
    "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    "SWIFT_STRICT_CONCURRENCY": "targeted",
    "TVOS_DEPLOYMENT_TARGET": "17.0",
}

# Projekt-Settings Release (basiert auf Debug, ohne dev-spezifische Schalter)
project_release = {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
    "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "CLANG_ENABLE_OBJC_WEAK": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
    "ENABLE_NS_ASSERTIONS": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "GCC_C_LANGUAGE_STANDARD": "gnu17",
    "GCC_NO_COMMON_BLOCKS": "YES",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "MTL_FAST_MATH": "YES",
    "SDKROOT": "appletvos",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_STRICT_CONCURRENCY": "targeted",
    "TVOS_DEPLOYMENT_TARGET": "17.0",
    "VALIDATE_PRODUCT": "YES",
}


# ---- pbxproj bauen ----
out = []
out.append("// !$*UTF8*$!")
out.append("{")
out.append("\tarchiveVersion = 1;")
out.append("\tclasses = {")
out.append("\t};")
out.append("\tobjectVersion = 56;")
out.append("\tobjects = {")

# PBXBuildFile section
out.append("")
out.append("/* Begin PBXBuildFile section */")
for s in SWIFT_FILES:
    bf_id = build_file_id(s, "sources")
    fr_id = file_ref_id(s)
    name = os.path.basename(s)
    out.append(f"\t\t{bf_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr_id} /* {name} */; }};")

for r in RESOURCE_FILES:
    bf_id = build_file_id(r, "resources")
    fr_id = file_ref_id(r)
    name = os.path.basename(r)
    out.append(f"\t\t{bf_id} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {fr_id} /* {name} */; }};")

bf_loc_id = build_file_id(LOCALIZED_FILE, "resources.localizable")
out.append(f"\t\t{bf_loc_id} /* Localizable.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {LOC_VARIANT_GROUP_ID} /* Localizable.strings */; }};")
out.append("/* End PBXBuildFile section */")

# PBXFileReference section
out.append("")
out.append("/* Begin PBXFileReference section */")
out.append(f"\t\t{APP_PRODUCT_ID} /* HomeDash.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = HomeDash.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
out.append(f"\t\t{file_ref_id(INFO_PLIST)} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = {INFO_PLIST}; sourceTree = \"<group>\"; }};")
out.append(f"\t\t{file_ref_id(ENTITLEMENTS)} /* HomeDash.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = {ENTITLEMENTS}; sourceTree = \"<group>\"; }};")

for s in SWIFT_FILES:
    fr_id = file_ref_id(s)
    name = os.path.basename(s)
    out.append(f"\t\t{fr_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{name}\"; sourceTree = \"<group>\"; }};")

ref_map = {
    "Assets.xcassets": ("folder.assetcatalog", "Assets.xcassets"),
    "PrivacyInfo.xcprivacy": ("text.xml", "PrivacyInfo.xcprivacy"),
    "Preview Content/Preview Assets.xcassets": ("folder.assetcatalog", "Preview Assets.xcassets"),
}
for r, (ft, fname) in ref_map.items():
    fr_id = file_ref_id(r)
    out.append(f"\t\t{fr_id} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = \"{fname}\"; sourceTree = \"<group>\"; }};")

for loc in LOCALES:
    fr_id = uid(f"fileref.localizable.{loc}")
    out.append(f"\t\t{fr_id} /* {loc} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {loc}; path = {loc}.lproj/{LOCALIZED_FILE}; sourceTree = \"<group>\"; }};")

out.append("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
out.append("")
out.append("/* Begin PBXFrameworksBuildPhase section */")
out.append(f"\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */ = {{")
out.append("\t\t\tisa = PBXFrameworksBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXFrameworksBuildPhase section */")

# PBXVariantGroup
out.append("")
out.append("/* Begin PBXVariantGroup section */")
out.append(f"\t\t{LOC_VARIANT_GROUP_ID} /* Localizable.strings */ = {{")
out.append("\t\t\tisa = PBXVariantGroup;")
out.append("\t\t\tchildren = (")
for loc in LOCALES:
    fr = uid(f"fileref.localizable.{loc}")
    out.append(f"\t\t\t\t{fr} /* {loc} */,")
out.append("\t\t\t);")
out.append("\t\t\tname = Localizable.strings;")
out.append("\t\t\tsourceTree = \"<group>\";")
out.append("\t\t};")
out.append("/* End PBXVariantGroup section */")

# PBXGroup
out.append("")
out.append("/* Begin PBXGroup section */")

def group_block(group_id, name, children_ids, path=None):
    res = [f"\t\t{group_id} /* {name} */ = {{",
           "\t\t\tisa = PBXGroup;",
           "\t\t\tchildren = ("]
    for c in children_ids:
        res.append(f"\t\t\t\t{c[0]} /* {c[1]} */,")
    res.append("\t\t\t);")
    if path:
        res.append(f"\t\t\tpath = \"{path}\";")
    else:
        res.append(f"\t\t\tname = \"{name}\";")
    res.append("\t\t\tsourceTree = \"<group>\";")
    res.append("\t\t};")
    return res

# Models
out.extend(group_block(MODELS_GROUP_ID, "Models", [
    (file_ref_id("Models/HomeStore.swift"), "HomeStore.swift"),
    (file_ref_id("Models/AccessoryKind.swift"), "AccessoryKind.swift"),
    (file_ref_id("Models/FavoritesStore.swift"), "FavoritesStore.swift"),
], path="Models"))

# Extensions
out.extend(group_block(EXTENSIONS_GROUP_ID, "Extensions", [
    (file_ref_id("Extensions/HMAccessory+Kind.swift"), "HMAccessory+Kind.swift"),
    (file_ref_id("Extensions/HMAccessory+State.swift"), "HMAccessory+State.swift"),
    (file_ref_id("Extensions/HMService+Helpers.swift"), "HMService+Helpers.swift"),
], path="Extensions"))

# DesignSystem
out.extend(group_block(DESIGN_GROUP_ID, "DesignSystem", [
    (file_ref_id("DesignSystem/DesignTokens.swift"), "DesignTokens.swift"),
    (file_ref_id("DesignSystem/AccessoryPalette.swift"), "AccessoryPalette.swift"),
    (file_ref_id("DesignSystem/TileStyle.swift"), "TileStyle.swift"),
    (file_ref_id("DesignSystem/TVSliderControl.swift"), "TVSliderControl.swift"),
    (file_ref_id("DesignSystem/FocusOutline.swift"), "FocusOutline.swift"),
    (file_ref_id("DesignSystem/FocusableTap.swift"), "FocusableTap.swift"),
], path="DesignSystem"))

# Views/Tiles
out.extend(group_block(VIEWS_TILES_GROUP_ID, "Tiles", [
    (file_ref_id("Views/Tiles/AccessoryTile.swift"), "AccessoryTile.swift"),
    (file_ref_id("Views/Tiles/SceneTile.swift"), "SceneTile.swift"),
], path="Tiles"))

# Views/Detail
out.extend(group_block(VIEWS_DETAIL_GROUP_ID, "Detail", [
    (file_ref_id("Views/Detail/AccessoryDetailSheet.swift"), "AccessoryDetailSheet.swift"),
    (file_ref_id("Views/Detail/ColorPickerGrid.swift"), "ColorPickerGrid.swift"),
    (file_ref_id("Views/Detail/DetailCards.swift"), "DetailCards.swift"),
], path="Detail"))

# Views
out.extend(group_block(VIEWS_GROUP_ID, "Views", [
    (file_ref_id("Views/ContentView.swift"), "ContentView.swift"),
    (file_ref_id("Views/PermissionView.swift"), "PermissionView.swift"),
    (file_ref_id("Views/EmptyStateView.swift"), "EmptyStateView.swift"),
    (file_ref_id("Views/FavoritesSection.swift"), "FavoritesSection.swift"),
    (file_ref_id("Views/HomeDashboardView.swift"), "HomeDashboardView.swift"),
    (file_ref_id("Views/HomePickerView.swift"), "HomePickerView.swift"),
    (file_ref_id("Views/RoomSection.swift"), "RoomSection.swift"),
    (file_ref_id("Views/ScenesSection.swift"), "ScenesSection.swift"),
    (VIEWS_TILES_GROUP_ID, "Tiles"),
    (VIEWS_DETAIL_GROUP_ID, "Detail"),
], path="Views"))

# Resources (Storyboard für tvOS entfällt – LaunchImage übernimmt das)
out.extend(group_block(RESOURCES_GROUP_ID, "Resources", [], path="Resources"))

# Localization
out.extend(group_block(LOCALIZATION_GROUP_ID, "Localization", [
    (LOC_VARIANT_GROUP_ID, "Localizable.strings"),
], path="Localization"))

# Preview Content
out.extend(group_block(PREVIEW_GROUP_ID, "Preview Content", [
    (file_ref_id("Preview Content/Preview Assets.xcassets"), "Preview Assets.xcassets"),
], path="Preview Content"))

# App-Group (HomeDash/)
out.extend(group_block(APP_GROUP_ID, "HomeDash", [
    (file_ref_id("HomeDashApp.swift"), "HomeDashApp.swift"),
    (MODELS_GROUP_ID, "Models"),
    (EXTENSIONS_GROUP_ID, "Extensions"),
    (DESIGN_GROUP_ID, "DesignSystem"),
    (VIEWS_GROUP_ID, "Views"),
    (RESOURCES_GROUP_ID, "Resources"),
    (LOCALIZATION_GROUP_ID, "Localization"),
    (PREVIEW_GROUP_ID, "Preview Content"),
    (file_ref_id("Assets.xcassets"), "Assets.xcassets"),
    (file_ref_id(INFO_PLIST), "Info.plist"),
    (file_ref_id(ENTITLEMENTS), "HomeDash.entitlements"),
    (file_ref_id("PrivacyInfo.xcprivacy"), "PrivacyInfo.xcprivacy"),
], path="HomeDash"))

# Products
out.append(f"\t\t{PRODUCTS_GROUP_ID} /* Products */ = {{")
out.append("\t\t\tisa = PBXGroup;")
out.append("\t\t\tchildren = (")
out.append(f"\t\t\t\t{APP_PRODUCT_ID} /* HomeDash.app */,")
out.append("\t\t\t);")
out.append("\t\t\tname = Products;")
out.append("\t\t\tsourceTree = \"<group>\";")
out.append("\t\t};")

# Main
out.append(f"\t\t{MAIN_GROUP_ID} = {{")
out.append("\t\t\tisa = PBXGroup;")
out.append("\t\t\tchildren = (")
out.append(f"\t\t\t\t{APP_GROUP_ID} /* HomeDash */,")
out.append(f"\t\t\t\t{PRODUCTS_GROUP_ID} /* Products */,")
out.append("\t\t\t);")
out.append("\t\t\tsourceTree = \"<group>\";")
out.append("\t\t};")
out.append("/* End PBXGroup section */")

# PBXNativeTarget
out.append("")
out.append("/* Begin PBXNativeTarget section */")
out.append(f"\t\t{TARGET_ID} /* HomeDash */ = {{")
out.append("\t\t\tisa = PBXNativeTarget;")
out.append(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_TARGET_ID} /* Build configuration list for PBXNativeTarget \"HomeDash\" */;")
out.append("\t\t\tbuildPhases = (")
out.append(f"\t\t\t\t{SOURCES_PHASE_ID} /* Sources */,")
out.append(f"\t\t\t\t{FRAMEWORKS_PHASE_ID} /* Frameworks */,")
out.append(f"\t\t\t\t{RESOURCES_PHASE_ID} /* Resources */,")
out.append("\t\t\t);")
out.append("\t\t\tbuildRules = (")
out.append("\t\t\t);")
out.append("\t\t\tdependencies = (")
out.append("\t\t\t);")
out.append("\t\t\tname = HomeDash;")
out.append("\t\t\tproductName = HomeDash;")
out.append(f"\t\t\tproductReference = {APP_PRODUCT_ID} /* HomeDash.app */;")
out.append("\t\t\tproductType = \"com.apple.product-type.application\";")
out.append("\t\t};")
out.append("/* End PBXNativeTarget section */")

# PBXProject
out.append("")
out.append("/* Begin PBXProject section */")
out.append(f"\t\t{PROJECT_ID} /* Project object */ = {{")
out.append("\t\t\tisa = PBXProject;")
out.append("\t\t\tattributes = {")
out.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
out.append("\t\t\t\tLastSwiftUpdateCheck = 1620;")
out.append("\t\t\t\tLastUpgradeCheck = 1620;")
out.append("\t\t\t\tTargetAttributes = {")
out.append(f"\t\t\t\t\t{TARGET_ID} = {{")
out.append("\t\t\t\t\t\tCreatedOnToolsVersion = 26.0;")
out.append("\t\t\t\t\t\tSystemCapabilities = {")
out.append("\t\t\t\t\t\t\t\"com.apple.HomeKit\" = {")
out.append("\t\t\t\t\t\t\t\tenabled = 1;")
out.append("\t\t\t\t\t\t\t};")
out.append("\t\t\t\t\t\t};")
out.append("\t\t\t\t\t};")
out.append("\t\t\t\t};")
out.append("\t\t\t};")
out.append(f"\t\t\tbuildConfigurationList = {BUILD_CONFIG_LIST_PROJECT_ID} /* Build configuration list for PBXProject \"HomeDash\" */;")
out.append("\t\t\tcompatibilityVersion = \"Xcode 15.0\";")
out.append("\t\t\tdevelopmentRegion = de;")
out.append("\t\t\thasScannedForEncodings = 0;")
out.append("\t\t\tknownRegions = (")
out.append("\t\t\t\tde,")
out.append("\t\t\t\ten,")
out.append("\t\t\t\tBase,")
out.append("\t\t\t);")
out.append(f"\t\t\tmainGroup = {MAIN_GROUP_ID};")
out.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP_ID} /* Products */;")
out.append("\t\t\tprojectDirPath = \"\";")
out.append("\t\t\tprojectRoot = \"\";")
out.append("\t\t\ttargets = (")
out.append(f"\t\t\t\t{TARGET_ID} /* HomeDash */,")
out.append("\t\t\t);")
out.append("\t\t};")
out.append("/* End PBXProject section */")

# PBXResourcesBuildPhase
out.append("")
out.append("/* Begin PBXResourcesBuildPhase section */")
out.append(f"\t\t{RESOURCES_PHASE_ID} /* Resources */ = {{")
out.append("\t\t\tisa = PBXResourcesBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
for r in RESOURCE_FILES:
    bf_id = build_file_id(r, "resources")
    out.append(f"\t\t\t\t{bf_id} /* {os.path.basename(r)} in Resources */,")
out.append(f"\t\t\t\t{bf_loc_id} /* Localizable.strings in Resources */,")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
out.append("")
out.append("/* Begin PBXSourcesBuildPhase section */")
out.append(f"\t\t{SOURCES_PHASE_ID} /* Sources */ = {{")
out.append("\t\t\tisa = PBXSourcesBuildPhase;")
out.append("\t\t\tbuildActionMask = 2147483647;")
out.append("\t\t\tfiles = (")
for s in SWIFT_FILES:
    bf_id = build_file_id(s, "sources")
    out.append(f"\t\t\t\t{bf_id} /* {os.path.basename(s)} in Sources */,")
out.append("\t\t\t);")
out.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
out.append("\t\t};")
out.append("/* End PBXSourcesBuildPhase section */")

# XCBuildConfiguration
out.append("")
out.append("/* Begin XCBuildConfiguration section */")

def emit_config(cid, name, settings):
    out.append(f"\t\t{cid} /* {name} */ = {{")
    out.append("\t\t\tisa = XCBuildConfiguration;")
    out.append("\t\t\tbuildSettings = {")
    out.append(render_settings(settings))
    out.append("\t\t\t};")
    out.append(f"\t\t\tname = {name};")
    out.append("\t\t};")

emit_config(BUILD_CONFIG_DEBUG_TARGET_ID, "Debug", target_common)
emit_config(BUILD_CONFIG_RELEASE_TARGET_ID, "Release", target_common)
emit_config(BUILD_CONFIG_DEBUG_PROJECT_ID, "Debug", project_debug)
emit_config(BUILD_CONFIG_RELEASE_PROJECT_ID, "Release", project_release)

out.append("/* End XCBuildConfiguration section */")

# XCConfigurationList
out.append("")
out.append("/* Begin XCConfigurationList section */")
out.append(f"\t\t{BUILD_CONFIG_LIST_PROJECT_ID} /* Build configuration list for PBXProject \"HomeDash\" */ = {{")
out.append("\t\t\tisa = XCConfigurationList;")
out.append("\t\t\tbuildConfigurations = (")
out.append(f"\t\t\t\t{BUILD_CONFIG_DEBUG_PROJECT_ID} /* Debug */,")
out.append(f"\t\t\t\t{BUILD_CONFIG_RELEASE_PROJECT_ID} /* Release */,")
out.append("\t\t\t);")
out.append("\t\t\tdefaultConfigurationIsVisible = 0;")
out.append("\t\t\tdefaultConfigurationName = Release;")
out.append("\t\t};")

out.append(f"\t\t{BUILD_CONFIG_LIST_TARGET_ID} /* Build configuration list for PBXNativeTarget \"HomeDash\" */ = {{")
out.append("\t\t\tisa = XCConfigurationList;")
out.append("\t\t\tbuildConfigurations = (")
out.append(f"\t\t\t\t{BUILD_CONFIG_DEBUG_TARGET_ID} /* Debug */,")
out.append(f"\t\t\t\t{BUILD_CONFIG_RELEASE_TARGET_ID} /* Release */,")
out.append("\t\t\t);")
out.append("\t\t\tdefaultConfigurationIsVisible = 0;")
out.append("\t\t\tdefaultConfigurationName = Release;")
out.append("\t\t};")
out.append("/* End XCConfigurationList section */")

out.append("\t};")
out.append(f"\trootObject = {PROJECT_ID} /* Project object */;")
out.append("}")

pbx_path = os.path.join(PROJECT_DIR, "project.pbxproj")
with open(pbx_path, "w") as f:
    f.write("\n".join(out) + "\n")

print(f"Wrote {pbx_path}")
print(f"Sources: {len(SWIFT_FILES)} swift files")
print(f"Target ID: {TARGET_ID}")
