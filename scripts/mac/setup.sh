#!/bin/bash
set -e

FILEPATH=$(dirname "$0")
source $FILEPATH/setup-helpers.sh

ANDROID_PLATFORM_VERSION=31
ANDROID_BUILD_TOOLS_VERSION=31.0.0
ANDROID_COMMAND_LINE_TOOLS_VERSION=7583922

while test $# -gt 0
do
    case "$1"
    in
        --android-platform)
            shift
            if test $# -gt 0
            then
                ANDROID_PLATFORM_VERSION=$1
            fi
            shift
            ;;
        --android-build-tools)
            shift
            if test $# -gt 0
            then
                ANDROID_BUILD_TOOLS_VERSION=$1
            fi
            shift
            ;;
        --android-cmdline-tools)
            shift
            if test $# -gt 0
            then
                ANDROID_COMMAND_LINE_TOOLS_VERSION=$1
            fi
            shift
            ;;
        *)
            shift
            break;;
    esac
done

installXCode
installAndroidSdkOnly $ANDROID_COMMAND_LINE_TOOLS_VERSION $ANDROID_PLATFORM_VERSION $ANDROID_BUILD_TOOLS_VERSION
installFlutter

installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'

addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
source ~/.bash_profile
code --install-extension Dart-Code.flutter
flutter doctor

install pod 'sudo gem install cocoapods'


