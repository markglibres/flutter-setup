#!/bin/bash

install() {
    which -s $1
    if [[ $? != 0 ]] ; then
        echo "$1 not found... installing...."
        $2
    else
        echo "$1 found.. skipping... "
    fi
}

installApp() {
    APP="/Applications/$1.app"
    if [ -d "$APP" ]; then
        echo "$APP found... skipping...."
    else 
        echo "$APP not found... installing..."
        $2
    fi
}

installXCode() {
    which g++
    if [[ $? != 0 ]] ; then
        echo "xcode not found... installing...."
        xcode-select --install
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer/
        sudo xcodebuild -runFirstLaunch
        sudo xcodebuild -license
    else
        echo "xcode found.. skipping... "
    fi
}

installAndroidSdkOnly() {
    source ~/.bash_profile
    install java 'brew install --cask oracle-jdk'
    if [ -z "${ANDROID_HOME}" ]
    then
        echo 'test'
        PLATFORM_VERSION=$1
        BUILD_TOOLS_VERSION=$2
        echo "versions ${PLATFORM_VERSION} ${BUILD_TOOLS_VERSION}"
        
        brew install --cask android-commandlinetools
        sdkmanager

        mkdir -p $HOME/android
        cd $HOME/android

        grep -qxF '## ## START ANDROID SDK ## ##' ~/.bash_profile || echo '\n## ## START ANDROID SDK ## ##' >> ~/.bash_profile
        grep -qxF 'export ANDROID_HOME=/usr/local/share/android-commandlinetools' ~/.bash_profile || echo 'export ANDROID_HOME=/usr/local/share/android-commandlinetools' >> ~/.bash_profile
        grep -qxF 'export PATH=$ANDROID_HOME/cmdline-tools/tools/bin/:$PATH' ~/.bash_profile || echo 'export PATH=$ANDROID_HOME/cmdline-tools/tools/bin/:$PATH' >> ~/.bash_profile
        grep -qxF 'export PATH=$ANDROID_HOME/emulator/:$PATH' ~/.bash_profile || echo 'export PATH=$ANDROID_HOME/emulator/:$PATH' >> ~/.bash_profile
        grep -qxF 'export PATH=$ANDROID_HOME/platform-tools/:$PATH' ~/.bash_profile || echo 'export PATH=$ANDROID_HOME/platform-tools/:$PATH' >> ~/.bash_profile
        grep -qxF '## ## END ANDROID SDK ## ##' ~/.bash_profile || echo '## ## END ANDROID SDK ## ##\n' >> ~/.bash_profile
        source ~/.bash_profile
        
        sdkmanager --install "platform-tools" "platforms;android-${PLATFORM_VERSION}" "build-tools;${BUILD_TOOLS_VERSION}" "cmdline-tools;latest"
    else
        echo "Android already setup...skipping"
    fi
}

installFlutter() {
    source ~/.bash_profile
    which -s flutter
    if [[ $? != 0 ]] ; then
        install flutter 'brew --cask flutter'

        grep -qxF '## ## START FLUTTER ## ##' ~/.bash_profile || echo '\n## ## START FLUTTER ## ##' >> ~/.bash_profile
        grep -qxF 'export PATH="`pwd`/flutter/bin:$PATH"' ~/.bash_profile || echo 'export PATH="`pwd`/flutter/bin:$PATH"' >> ~/.bash_profile
        grep -qxF '## ## END FLUTTER ## ##' ~/.bash_profile || echo '## ## END FLUTTER ## ##\n' >> ~/.bash_profile
        
        flutter config --android-sdk $ANDROID_HOME
        flutter doctor --android-licenses
        flutter doctor
    else
        echo "xcode found.. skipping... "
    fi
}

addPath() {
    grep -qxF "$1" ~/.bash_profile || echo "$1" >> ~/.bash_profile
}