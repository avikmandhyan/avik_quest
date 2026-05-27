#!/bin/bash
# AvikQuest — macOS App Installer
# Paste this entire script into Terminal and press Enter.
# Takes ~2 minutes. Creates AvikQuest.app in your Applications folder.

set -e

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BOLD}⚔  AvikQuest — macOS App Installer${NC}"
echo -e "${BLUE}────────────────────────────────────${NC}"
echo ""

# ── Step 1: Check Python ──────────────────────────────────────────────────────
echo -e "${YELLOW}[1/5]${NC} Checking Python..."
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}✗ Python 3 not found.${NC}"
    echo "  Install it from https://www.python.org/downloads/ then re-run this script."
    exit 1
fi
PY=$(python3 --version)
echo -e "${GREEN}✓${NC} Found $PY"

# ── Step 2: Install dependencies ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/5]${NC} Installing dependencies (pywebview + pyinstaller)..."
pip3 install pywebview pyinstaller --quiet --break-system-packages 2>/dev/null \
    || pip3 install pywebview pyinstaller --quiet
echo -e "${GREEN}✓${NC} Dependencies ready"

# ── Step 3: Set up build directory ───────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/5]${NC} Preparing build files..."
BUILD_DIR="$HOME/.avikquest_build"
mkdir -p "$BUILD_DIR"

# Write main.py
cat > "$BUILD_DIR/main.py" << 'PYEOF'
import webview
import os
import sys

def resource(rel):
    if getattr(sys, 'frozen', False):
        base = sys._MEIPASS
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base, rel)

if __name__ == '__main__':
    window = webview.create_window(
        title='AvikQuest',
        url=f'file://{resource("app.html")}',
        width=1200,
        height=820,
        min_size=(960, 660),
        background_color='#08080f',
        text_select=False,
    )
    webview.start(gui='cocoa')
PYEOF

# Write the spec file
cat > "$BUILD_DIR/AvikQuest.spec" << 'SPECEOF'
# -*- mode: python ; coding: utf-8 -*-
block_cipher = None
a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('app.html', '.')],
    hiddenimports=['webview','webview.platforms.cocoa'],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
exe = EXE(pyz, a.scripts, [], exclude_binaries=True, name='AvikQuest',
    debug=False, strip=False, upx=True, console=False)
coll = COLLECT(exe, a.binaries, a.zipfiles, a.datas,
    strip=False, upx=True, upx_exclude=[], name='AvikQuest')
app = BUNDLE(coll, name='AvikQuest.app', icon=None,
    bundle_identifier='com.avik.avikquest',
    info_plist={
        'CFBundleName': 'AvikQuest',
        'CFBundleDisplayName': 'AvikQuest',
        'CFBundleVersion': '1.0.0',
        'NSHighResolutionCapable': True,
        'NSRequiresAquaSystemAppearance': False,
    })
SPECEOF

echo -e "${GREEN}✓${NC} Build files ready"

# ── Step 4: Copy app.html ─────────────────────────────────────────────────────
# app.html should be next to this install script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/app.html" ]; then
    cp "$SCRIPT_DIR/app.html" "$BUILD_DIR/app.html"
    echo -e "${GREEN}✓${NC} Game files copied"
else
    echo -e "${RED}✗ Cannot find app.html${NC}"
    echo "  Make sure app.html is in the same folder as this install script."
    exit 1
fi

# ── Step 5: Build the .app ────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/5]${NC} Building AvikQuest.app (this takes ~1-2 minutes)..."
cd "$BUILD_DIR"
python3 -m PyInstaller AvikQuest.spec \
    --distpath "$BUILD_DIR/dist" \
    --workpath "$BUILD_DIR/work" \
    --noconfirm \
    --log-level WARN 2>/dev/null
echo -e "${GREEN}✓${NC} App built successfully"

# ── Step 6: Install to Applications ──────────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/5]${NC} Installing to /Applications..."
if [ -d "/Applications/AvikQuest.app" ]; then
    rm -rf "/Applications/AvikQuest.app"
fi
cp -R "$BUILD_DIR/dist/AvikQuest.app" "/Applications/AvikQuest.app"

# Clean up build artifacts
rm -rf "$BUILD_DIR"

echo -e "${GREEN}✓${NC} Installed to /Applications/AvikQuest.app"

echo ""
echo -e "${BOLD}${GREEN}✅  Done! AvikQuest is installed.${NC}"
echo ""
echo -e "  ${BOLD}To open:${NC} Go to Applications → double-click AvikQuest"
echo -e "  ${BOLD}Or run:${NC}  open /Applications/AvikQuest.app"
echo ""
echo -e "${BLUE}  If macOS shows a security warning:${NC}"
echo -e "  System Settings → Privacy & Security → click 'Open Anyway'"
echo ""

# ── Apply icon to the .app ───────────────────────────────────────────────────
if [ -f "$SCRIPT_DIR/AvikQuest.icns" ]; then
    RESOURCES="/Applications/AvikQuest.app/Contents/Resources"
    mkdir -p "$RESOURCES"
    cp "$SCRIPT_DIR/AvikQuest.icns" "$RESOURCES/AvikQuest.icns"
    # Patch Info.plist to reference the icon
    PLIST="/Applications/AvikQuest.app/Contents/Info.plist"
    if [ -f "$PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AvikQuest" "$PLIST" 2>/dev/null || true
    fi
    # Force Finder to refresh icon cache
    touch "/Applications/AvikQuest.app"
    echo -e "${GREEN}✓${NC} Custom icon applied"
fi
