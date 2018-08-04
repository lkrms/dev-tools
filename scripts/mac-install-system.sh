#!/bin/bash

if [ "$(uname -s)" != "Darwin" ]; then

    echo "Error: $(basename "$0") is not supported on this platform."
    exit 1

fi

if [ "$#" -ne "1" ]; then

    echo "Usage: $(basename "$0") </path/to/downloads/folder>"
    exit 1

fi

if [ ! -d "$1" ]; then

    echo "Error: $1 doesn't exist or isn't a folder."
    exit 2

fi

LOCAL_PATH="$HOME/Downloads/_install"
DOWNLOADS_PATH="$1"

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

mkdir -p "$LOCAL_PATH" || exit 3

echo -e "Copying everything you might need...\n"

function package_get {

    IS_PKG="$3"

    if [ -z "$IS_PKG" ]; then

        IS_PKG=0

    fi

    IS_INSTALLED=0

    if [ "$IS_PKG" -ne "0" ]; then

        pkgutil --pkgs="$2" >/dev/null && IS_INSTALLED=1

    else

        [ -e "$2" ] && IS_INSTALLED=1

    fi

    # don't do anything if the application is already installed
    if [ "$IS_INSTALLED" -eq "0" ]; then

        # identify the most recent file matching the provided spec
        PACKAGE_PATH="$(find "$DOWNLOADS_PATH" -type f -name "$1" -print0 | xargs -0 stat -f '%m :%N' | sort -nr | cut -d: -f2- | head -n1)"

        if [ -z "$PACKAGE_PATH" ]; then

            echo "Unable to find a package file matching: $1"

        else

            cp -pvn "$PACKAGE_PATH" "$LOCAL_PATH"

        fi

    else

        echo "Already installed: $2"

        find "$LOCAL_PATH" -maxdepth 1 -type f -name "$1" -delete

    fi

}

package_get "Acorn*.zip" "/Applications/Acorn.app"
package_get "anyconnect-macosx*.dmg" "com.cisco.pkg.anyconnect.vpn" 1
package_get "AnyList*.zip" "/Applications/AnyList.app"
package_get "Brother_PrinterDrivers_ColorLaser*.dmg" "com.Brother.Brotherdriver.Brother_PrinterDrivers_ColorLaser" 1
package_get "Brother_PrinterDrivers_MonochromeLaser*.dmg" "com.Brother.Brotherdriver.Brother_PrinterDrivers_MonochromeLaser" 1
package_get "Caffeine*.zip" "/Applications/Caffeine.app"
package_get "dbeaver-ce*.dmg" "/Applications/DBeaver.app"
package_get "FileZilla*.tar.bz2" "/Applications/FileZilla.app"
package_get "Firefox*.dmg" "/Applications/Firefox.app"
package_get "Flycut*.zip" "/Applications/Flycut.app"
package_get "Geekbench-4*.dmg" "/Applications/Geekbench 4.app"
package_get "googlechrome*.dmg" "/Applications/Google Chrome.app"
package_get "HandBrake*.dmg" "/Applications/HandBrake.app"
package_get "Hex_Fiend*.dmg" "/Applications/Hex Fiend.app"
package_get "ImageOptim*.tbz2" "/Applications/ImageOptim.app"
package_get "iTerm2*.zip" "/Applications/iTerm.app"
package_get "jdk-*.dmg" "com.oracle.jdk.*" 1
package_get "Karabiner-Elements*.dmg" "org.pqrs.Karabiner-Elements" 1
package_get "KeePassXC*.dmg" "/Applications/KeePassXC.app"
package_get "LibreOffice*.dmg" "/Applications/LibreOffice.app"
package_get "LingonX*.zip" "/Applications/Lingon X.app"
package_get "MacFR4SS*.dmg" "com.abbyy.FineReaderForScanSnap.*" 1
package_get "MacOnlineUpdate*.dmg" "com.fujitsu.pfu.ScanSnap.OnlineUpdate.*" 1
package_get "MacS1300iManager*.dmg" "jp.co.pfu.ScanSnap.*" 1
package_get "MasterPDFEditor*.dmg" "/Applications/Master PDF Editor.app"
package_get "moom*.dmg" "/Applications/Moom.app"
package_get "ownCloud*.pkg" "com.ownCloud.client" 1
package_get "Pencil*.dmg" "/Applications/Pencil.app"
package_get "PhoneView*.zip" "/Applications/PhoneView.app"
package_get "scribus-*.dmg" "/Applications/Scribus.app"
package_get "Scrivener*.dmg" "/Applications/Scrivener 2.app"
package_get "sequel-pro*.dmg" "/Applications/Sequel Pro.app"
package_get "Skype*.dmg" "/Applications/Skype.app"
package_get "SonosDesktopController*.dmg" "/Applications/Sonos.app"
package_get "Sourcetree*.zip" "/Applications/Sourcetree.app"
package_get "Subler*.zip" "/Applications/Subler.app"
package_get "Sublime Text*.dmg" "/Applications/Sublime Text.app"
package_get "SwiftPublisher*.dmg" "/Applications/Swift Publisher 4.app"
package_get "Teams_osx*.dmg" "/Applications/Microsoft Teams.app"
package_get "TextExpander*.zip" "/Applications/TextExpander.app"
package_get "Transmission*.dmg" "/Applications/Transmission.app"
package_get "Typora*.dmg" "/Applications/Typora.app"
package_get "vlc*.dmg" "/Applications/VLC.app"
package_get "VSCode-darwin-stable*.zip" "/Applications/Visual Studio Code.app"

echo -e "Installing downloaded packages...\n"

"$SCRIPT_DIR/mac-install-apps.sh" "$LOCAL_PATH"

echo -e "\n\nDone. Please install Adobe Lightroom, DisplayCAL, Synergy if needed."

