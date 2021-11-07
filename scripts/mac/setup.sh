#!/bin/bash
set -e

FILEPATH=$(dirname "$0")
source $FILEPATH/setup-helpers.sh

PLATFORM_VERSION=31
BUILD_TOOLS_VERSION=31.0.0

while test $# -gt 0
do
    case "$1"
    in
        --platform)
            shift
            if test $# -gt 0
            then
                PLATFORM_VERSION=$1
            fi
            shift
            ;;
        --build-tools)
            shift
            if test $# -gt 0
            then
                BUILD_TOOLS_VERSION=$1
            fi
            shift
            ;;
        *)
            shift
            break;;
    esac
done

installXCode
installAndroidSdkOnly $PLATFORM_VERSION $BUILD_TOOLS_VERSION
installFlutter

installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'

addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
source ~/.bash_profile
code --install-extension Dart-Code.flutter
flutter doctor

install pod 'sudo gem install cocoapods'


