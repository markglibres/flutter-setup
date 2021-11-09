#!/bin/bash

addToPath() {
    grep -qxF "$1" ~/.bash_profile || echo "$1" >> ~/.bash_profile
}

install() {
    source ~/.bash_profile
    which -s $1
    if [[ $? != 0 ]] ; then
        echo "$1 not found... installing...."
        $2
    else
        echo "$1 found.. skipping... "
    fi
}

installApp() {
    source ~/.bash_profile
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
    install java 'brew install --cask adoptopenjdk8'

    COMMAND_LINE_TOOL_VERSION=$1
    PLATFORM_VERSION=$2
    BUILD_TOOLS_VERSION=$3

    which -s sdkmanager
    if [[ $? != 0 ]] ; then
        COMMAND_LINE_TOOL_FILE=commandlinetools-mac-${COMMAND_LINE_TOOL_VERSION}_latest.zip
        PLATFORM_VERSION=$2
        BUILD_TOOLS_VERSION=$3

        echo "versions ${PLATFORM_VERSION} ${BUILD_TOOLS_VERSION}"
        
        cd $HOME
        ANDROID_HOME=$HOME/Library/Android/sdk
        COMMAND_LINE_TOOL_PATH=$ANDROID_HOME/cmdline-tools

        mkdir -p $COMMAND_LINE_TOOL_PATH
        cd $COMMAND_LINE_TOOL_PATH

        curl -O https://dl.google.com/android/repository/${COMMAND_LINE_TOOL_FILE}
        unzip ${COMMAND_LINE_TOOL_FILE}
        mv cmdline-tools tools

        addToPath 'export ANDROID_HOME=$HOME/Library/Android/sdk'
        addToPath 'export PATH=$ANDROID_HOME/cmdline-tools/tools/bin/:$PATH'
        addToPath 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin/:$PATH'
        addToPath 'export PATH=$ANDROID_HOME/emulator/:$PATH'
        addToPath 'export PATH=$ANDROID_HOME/platform-tools/:$PATH'
        
        cd tools/bin
    else
        echo "Android already setup...skipping"
    fi

    installAndroidPackage "platform-tools"
    installAndroidPackage "platforms;android-${PLATFORM_VERSION}"
    installAndroidPackage "build-tools;${BUILD_TOOLS_VERSION}"
    installAndroidPackage "cmdline-tools;latest"
    installAndroidPackage "system-images;android-${PLATFORM_VERSION};google_apis;x86_64"
}

installAndroidPackage() {
    source ~/.bash_profile
    which -s sdkmanager
    if [[ $? == 0 ]] ; then
        INSTALLED_PACKAGES=$(sdkmanager --list_installed)
        if [[ ! $INSTALLED_PACKAGES == *"$1"* ]]; then
            echo  "package $1 not found.. installing"
            sdkmanager --install "$1"
        else
            echo  "package $1 already installed.. skipping"
        fi
    else
        echo "sdkmanager not found.. skipping package install $1"
    fi
}

installFlutter() {
    source ~/.bash_profile
    which -s flutter
    if [[ $? != 0 ]] ; then
        install flutter 'brew --cask flutter'

        addToPath 'export PATH="`pwd`/flutter/bin:$PATH"'
        
        flutter config --android-sdk $ANDROID_HOME
        flutter doctor --android-licenses
        flutter doctor
    else
        echo "xcode found.. skipping... "
    fi
}

installVSCode() {
    source ~/.bash_profile
    installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'
    addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
}

installVSCodeExtension() {
    source ~/.bash_profile
    which -s code
    if [[ $? == 0 ]] ; then
        INSTALLED_EXTENSIONS=$(code --list-extensions)
        if [[ ! $INSTALLED_EXTENSIONS == *$1* ]]; then
            echo "VS Code extension $1 not found.. installing"
            code --install-extension $1
        else
            echo "VS Code extension $1 already installed.. skipping"
        fi
    else
        echo "Visual Studio Code not found.. skipping"
    fi
}