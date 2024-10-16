set -e

FILEPATH=$(dirname "$0")
source $FILEPATH/setup-helpers.sh

ANDROID_PLATFORM_VERSION=35
ANDROID_BUILD_TOOLS_VERSION=35.0.0
ANDROID_COMMAND_LINE_TOOLS_VERSION=11076708

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

sudo softwareupdate --install-rosetta --agree-to-license

# installBrew
# installXCode
# installiOSSimulator
# installTools
# installFastlane
# installAndroidSdkOnly $ANDROID_COMMAND_LINE_TOOLS_VERSION $ANDROID_PLATFORM_VERSION $ANDROID_BUILD_TOOLS_VERSION
# installAndroidStudio
# installAndroidStudioAndSdk
# installFlutter
# installVSCode


# Main Execution
#createBrewGroup
#set_homebrew_path
installBrew
installRuby
installXCode
installiOSSimulator
installCocoaPods
installFastlane
# installAndroidStudioAndSdk
check_android_studio
installFlutter
installVSCode
installVSCodeExtension Dart-Code.flutter
# OR
installCursorIDE
