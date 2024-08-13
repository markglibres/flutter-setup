#!/bin/bash

# Determine the correct Homebrew path based on architecture
if [ -d "/opt/homebrew/bin" ]; then
    HOMEBREW_PATH="/opt/homebrew/bin"
elif [ -d "/usr/local/bin" ]; then
    HOMEBREW_PATH="/usr/local/bin"
else
    echo "Homebrew installation not found in expected locations."
    exit 1
fi

# Add Homebrew to the PATH if not already present
add_brew_to_path() {
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        # Default to ~/.profile if the shell is not recognized
        SHELL_CONFIG_FILE=~/.profile
    fi

    if ! grep -q "eval \"\$($HOMEBREW_PATH/brew shellenv)\"" "$SHELL_CONFIG_FILE"; then
        echo "Adding Homebrew to the PATH in $SHELL_CONFIG_FILE"
        echo "eval \"\$($HOMEBREW_PATH/brew shellenv)\"" >> "$SHELL_CONFIG_FILE"
        eval "$($HOMEBREW_PATH/brew shellenv)"
    else
        echo "Homebrew is already in the PATH."
        eval "$($HOMEBREW_PATH/brew shellenv)"
    fi
}


installBrew() {
   
    # Check for Homebrew installation
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is already installed"
        add_brew_to_path
    else
        echo "Homebrew is not installed, installing now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to the PATH after installation
        add_brew_to_path
    
        echo "Homebrew installation complete"
    fi
    
    # Verify Homebrew installation
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew was successfully installed!"
        brew --version
    else
        echo "Homebrew installation failed or not found in PATH"
    fi

    sourceEnv

}

install() {
    sourceEnv
    which -s $1
    if [[ $? != 0 ]] ; then
        echo "$1 not found... installing...."
        $2
    else
        echo "$1 found.. skipping... "
    fi
}

installTools() {
    sudo gem uninstall cocoapods
    sudo gem install cocoapods
    
}

installFastlane() {
    brew install rbenv
    echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
    echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
    sourceEnv
    rbenv install 3.1.0
    rbenv global 3.1.0
    sudo gem uninstall fastlane
    sudo gem install fastlane
}

installApp() {
    sourceEnv
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
    else
        echo "xcode found.. skipping... "
    fi

    sourceEnv
    
    # Install Command Line Tools if not already installed
    echo "Checking for Xcode Command Line Tools..."
    if ! xcode-select --install 2>&1 | grep -q "already installed"; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
    else
        echo "Xcode Command Line Tools are already installed."
    fi
    
    # Set the active developer directory to Xcode
    echo "Setting the active developer directory to Xcode..."
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    
    # Accept the Xcode license agreement
    echo "Accepting the Xcode license agreement..."
    sudo xcodebuild -license accept
    
    echo "Xcode license has been accepted and the developer directory is set correctly."

    
    echo "All done! You can now use Xcode and command line tools without issues."
    

}

installiOSSimulator() {
    xcodebuild -downloadPlatform iOS
}

installAndroidSdkOnly() {
    sourceEnv
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
    sourceEnv
    which -s sdkmanager
    if [[ $? == 0 ]] ; then
        #INSTALLED_PACKAGES=$(sdkmanager --list_installed)
        #if [[ ! $INSTALLED_PACKAGES == *"$1"* ]]; then
        #    echo  "package $1 not found.. installing"
        #    sdkmanager --install "$1"
        #else
        #    echo  "package $1 already installed.. skipping"
        #fi
        sdkmanager --install "$1"
    else
        echo "sdkmanager not found.. skipping package install $1"
    fi
}

installFlutter() {
    sourceEnv
    which -s flutter
    if [[ $? != 0 ]] ; then
        install flutter 'brew --cask flutter'

        addToPath 'export PATH="`pwd`/flutter/bin:$PATH"'
        
        flutter config --android-sdk $ANDROID_HOME
        flutter doctor --android-licenses
        flutter doctor
    else
       echo "flutter found.. skipping... "
    fi
}

installVSCode() {
    sourceEnv
    installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'
    addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
}

installVSCodeExtension() {
    sourceEnv
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

sourceEnv() {
    ENVFILE=~/.bashrc
    if [[ $SHELL == *zsh* ]]; then
        ENVFILE=~/.zshrc
    fi

    # Check if the file exists; if not, create it
    if [ ! -f "$ENVFILE" ]; then
        echo "$ENVFILE does not exist. Creating it now..."
        touch "$ENVFILE"
        echo "$ENVFILE has been created."
    fi
    
    # Source the file
    source $ENVFILE
    echo "Sourced $ENVFILE successfully."
}

addToPath() {
    if [ -f ~/.bashrc ]; then
        touch ~/.bashrc
    fi
    if [ -f ~/.zshrc ]; then
        touch ~/.zshrc
    fi

    grep -qxF "$1" ~/.bashrc || echo "$1" >> ~/.bashrc
    grep -qxF "$1" ~/.zshrc || echo "$1" >> ~/.zshrc
}
