#!/bin/bash

# Determine the correct Homebrew path based on architecture
set_homebrew_path() {
    if [ -d "/opt/homebrew/bin" ]; then
        HOMEBREW_PATH="/opt/homebrew/bin"
    elif [ -d "/usr/local/bin" ]; then
        HOMEBREW_PATH="/usr/local/bin"
    else
        echo "Homebrew installation not found in expected locations."
        exit 1
    fi
}

# Add a command to the appropriate shell configuration file and source it
addToPath() {
    LINE=$1
    SHELL_CONFIG_FILE=$(get_shell_config_file)

    # Create the configuration file if it doesn't exist
    [ ! -f "$SHELL_CONFIG_FILE" ] && touch "$SHELL_CONFIG_FILE"

    # Add the line to the configuration file if it's not already present
    grep -qxF "$LINE" "$SHELL_CONFIG_FILE" || echo "$LINE" >> "$SHELL_CONFIG_FILE"

    # Source the configuration file to apply the changes
    source "$SHELL_CONFIG_FILE"
}

# Determine the appropriate shell configuration file
get_shell_config_file() {
    if [[ $SHELL == *zsh* ]]; then
        echo ~/.zshrc
    elif [[ $SHELL == *bash* ]]; then
        echo ~/.bashrc
    else
        echo ~/.profile
    fi
}

# Source the environment variables
sourceEnv() {
    SHELL_CONFIG_FILE=$(get_shell_config_file)
    
    # Create the configuration file if it doesn't exist
    [ ! -f "$SHELL_CONFIG_FILE" ] && touch "$SHELL_CONFIG_FILE"

    # Source the shell configuration file to apply changes immediately
    echo "Sourcing $SHELL_CONFIG_FILE to apply changes..."
    source "$SHELL_CONFIG_FILE"

    echo "Path and environment variables refreshed in the current terminal session."
}

# Function to install Homebrew if not already installed
installBrew() {
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew is already installed"
        add_brew_to_path
    else
        echo "Homebrew is not installed, installing now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        add_brew_to_path
        echo "Homebrew installation complete"
    fi

    sourceEnv

    # Verify Homebrew installation
    if command -v brew >/dev/null 2>&1; then
        echo "Homebrew was successfully installed!"
        brew --version
    else
        echo "Homebrew installation failed or not found in PATH"
    fi

    sourceEnv
}

# Add Homebrew to the PATH if not already present
add_brew_to_path() {
    SHELL_CONFIG_FILE=$(get_shell_config_file)
    if ! grep -q "eval \"\$($HOMEBREW_PATH/brew shellenv)\"" "$SHELL_CONFIG_FILE"; then
        echo "Adding Homebrew to the PATH in $SHELL_CONFIG_FILE"
        echo "eval \"\$($HOMEBREW_PATH/brew shellenv)\"" >> "$SHELL_CONFIG_FILE"
        eval "$($HOMEBREW_PATH/brew shellenv)"
    else
        echo "Homebrew is already in the PATH."
        eval "$($HOMEBREW_PATH/brew shellenv)"
    fi
}

# Function to install CocoaPods if not already installed
installCocoaPods() {
    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods is already installed."
        addToPath "$(get_cocoapods_path)"
    else
        echo "CocoaPods is not installed. Installing now..."
        sudo gem install cocoapods
        addToPath "$(get_cocoapods_path)"
        echo "CocoaPods installation complete."
    fi
    
    sourceEnv

    # Verify CocoaPods installation
    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods was successfully installed!"
        pod --version
    else
        echo "CocoaPods installation failed."
    fi
}

get_cocoapods_path() {
    gem environment | grep -E 'EXECUTABLE DIRECTORY' | awk '{print $3}'
}

# Function to install rbenv and Ruby
installRuby() {
    install_rbenv
    RUBY_VERSION="3.1.0"

    if ! rbenv versions | grep -q "$RUBY_VERSION"; then
        echo "Installing Ruby version $RUBY_VERSION..."
        rbenv install "$RUBY_VERSION"
    else
        echo "Ruby version $RUBY_VERSION is already installed."
    fi

    echo "Setting Ruby version $RUBY_VERSION as the global version..."
    rbenv global "$RUBY_VERSION"
    rbenv rehash

    # Verify the installed Ruby version
    if [[ "$(ruby -v)" == *"$RUBY_VERSION"* ]]; then
        echo "Ruby version $RUBY_VERSION was successfully set as the global version!"
        ruby -v
    else
        echo "Failed to set Ruby version $RUBY_VERSION as the global version."
    fi
}

# Function to install rbenv if not already installed
install_rbenv() {
    if command -v rbenv >/dev/null 2>&1; then
        echo "rbenv is already installed."
        addToPath "$(get_rbenv_path)"
    else
        echo "rbenv is not installed. Installing now..."
        brew install rbenv
        addToPath "$(get_rbenv_path)"
        echo "rbenv installation complete."
    fi

    sourceEnv
}

get_rbenv_path() {
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"'
    echo 'eval "$(rbenv init -)"'
}

# Function to install Fastlane if not already installed
installFastlane() {
    installRuby

    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane is already installed."
        addToPath "$(get_fastlane_path)"
    else
        echo "Fastlane is not installed. Installing now..."
        brew install fastlane
        addToPath "$(get_fastlane_path)"
        echo "Fastlane installation complete."
    fi

    sourceEnv

    # Verify Fastlane installation
    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane was successfully installed!"
        fastlane --version
    else
        echo "Fastlane installation failed."
    fi
}

get_fastlane_path() {
    echo 'export PATH="$HOME/.fastlane/bin:$PATH"'
}

# Function to install Android Studio and SDK
installAndroidStudioAndSdk() {
    sourceEnv
    install java 'brew install --cask adoptopenjdk8'

    # Install Android Studio using Homebrew
    if ! brew list --cask | grep -q "^android-studio$"; then
        echo "Installing Android Studio..."
        brew install --cask android-studio
        echo "Android Studio installation complete."
    else
        echo "Android Studio is already installed."
    fi

    sourceEnv

    # Automatically get the latest command-line tool version
    COMMAND_LINE_TOOL_VERSION=$(curl -s https://dl.google.com/android/repository/repository2-1.xml \
    | grep -oE 'commandlinetools-mac-[0-9]+' \
    | grep -oE '[0-9]+' \
    | sort -V | tail -1)

    # Set the filenames
    COMMAND_LINE_TOOL_FILE="commandlinetools-mac-${COMMAND_LINE_TOOL_VERSION}_latest.zip"

    # Set up paths
    ANDROID_HOME=$HOME/Library/Android/sdk
    COMMAND_LINE_TOOL_PATH=$ANDROID_HOME/cmdline-tools

    if ! command -v sdkmanager &> /dev/null; then
        echo "Setting up Android SDK..."

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
        echo "Android SDK already setup...skipping"
    fi

    sourceEnv

    # Install necessary Android packages
    installAndroidPackage "platform-tools"

    # Get the latest platform version
    PLATFORM_VERSION=$(sdkmanager --list | grep "platforms;android-" | grep -oE '[0-9]+' | sort -nr | head -n 1)
    
    # Get the latest build tools version
    BUILD_TOOLS_VERSION=$(sdkmanager --list | grep "build-tools;" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -nr | head -n 1)

    echo "Installing platform version: ${PLATFORM_VERSION}, build tools version: ${BUILD_TOOLS_VERSION}"

    installAndroidPackage "platforms;android-${PLATFORM_VERSION}"
    installAndroidPackage "build-tools;${BUILD_TOOLS_VERSION}"
    installAndroidPackage "cmdline-tools;latest"
    installAndroidPackage "system-images;android-${PLATFORM_VERSION};google_apis;x86_64"

    sourceEnv

    # Accept all Android SDK licenses
    yes | sdkmanager --licenses

    # Run flutter doctor to check the status
    echo "Running flutter doctor..."
    flutter doctor

    echo "Android Studio and SDK setup is complete."
}

installAndroidPackage() {
    if command -v sdkmanager &> /dev/null; then
        sdkmanager --install "$1"
    else
        echo "sdkmanager not found.. skipping package install $1"
    fi
}

installFlutter() {
    sourceEnv
    if ! command -v flutter &> /dev/null; then
        echo "Installing Flutter..."
        brew install --cask flutter
        addToPath 'export PATH="`pwd`/flutter/bin:$PATH"'
        flutter config --android-sdk $ANDROID_HOME
        flutter doctor --android-licenses
        flutter doctor
    else
        echo "Flutter found.. skipping..."
    fi
}

installVSCode() {
    sourceEnv
    installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'
    addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
}

installVSCodeExtension() {
    sourceEnv
    if command -v code &> /dev/null; then
        if ! code --list-extensions | grep -q "$1"; then
            echo "VS Code extension $1 not found.. installing"
            code --install-extension $1
        else
            echo "VS Code extension $1 already installed.. skipping"
        fi
    else
        echo "Visual Studio Code not found.. skipping"
    fi
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
    if ! command -v g++ &> /dev/null; then
        echo "xcode not found... installing...."
        xcode-select --install
        sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer/
        sudo xcodebuild -runFirstLaunch
    else
        echo "xcode found.. skipping..."
    fi

    sourceEnv

    if ! xcode-select --install 2>&1 | grep -q "already installed"; then
        echo "Installing Xcode Command Line Tools..."
        xcode-select --install
    else
        echo "Xcode Command Line Tools are already installed."
    fi
    
    echo "Setting the active developer directory to Xcode..."
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    
    echo "Accepting the Xcode license agreement..."
    sudo xcodebuild -license accept
    
    echo "Xcode license has been accepted and the developer directory is set correctly."
}

installiOSSimulator() {
    xcodebuild -downloadPlatform iOS
}

