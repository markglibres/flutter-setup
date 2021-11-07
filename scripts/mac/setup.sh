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
installAndroid $PLATFORM_VERSION $BUILD_TOOLS_VERSION
installFlutter

install pod 'sudo gem install cocoapods'


