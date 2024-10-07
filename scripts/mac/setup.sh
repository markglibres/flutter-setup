#!/bin/bash

# Function to create a user group and add the current user to the group
createBrewGroup() {
    GROUP_NAME="brew_users"
    
    if dscl . -list /Groups | grep -q "^$GROUP_NAME$"; then
        echo "Group $GROUP_NAME already exists."
    else
        echo "Creating group $GROUP_NAME..."
        sudo dscl . -create /Groups/$GROUP_NAME
        if [ $? -eq 0 ]; then
            echo "Group $GROUP_NAME created successfully."
        else
            echo "Failed to create group $GROUP_NAME. Exiting."
            exit 1
        fi
    fi

    CURRENT_USER=$(whoami)
    if id -nG "$CURRENT_USER" | grep -qw "$GROUP_NAME"; then
        echo "User $CURRENT_USER is already in group $GROUP_NAME."
    else
        echo "Adding user $CURRENT_USER to group $GROUP_NAME..."
        sudo dscl . -append /Groups/$GROUP_NAME GroupMembership $CURRENT_USER
        if [ $? -eq 0 ]; then
            echo "User $CURRENT_USER added to group $GROUP_NAME successfully."
        else
            echo "Failed to add user $CURRENT_USER to group $GROUP_NAME. Exiting."
            exit 1
        fi
    fi

    echo "Flushing directory service cache..."
    sudo dscacheutil -flushcache
    echo "Directory service cache flushed."

    GROUP_GID=$(dscl . -read /Groups/$GROUP_NAME | grep PrimaryGroupID | awk '{print $2}')

    if [ -d "/opt/homebrew" ]; then
        echo "Setting permissions for /opt/homebrew using GID $GROUP_GID..."
        sudo chown -R :$GROUP_GID /opt/homebrew
        if [ $? -eq 0 ]; then
            sudo chmod -R g+w /opt/homebrew
            sudo find /opt/homebrew -type d -exec chmod g+s {} \;
            echo "Permissions have been updated successfully for /opt/homebrew."
        else
            echo "Failed to change ownership to group $GROUP_NAME (GID: $GROUP_GID). Exiting."
            exit 1
        fi
    else
        echo "/opt/homebrew directory not found. Skipping permissions adjustment."
    fi
}

install() {
    COMMAND=$1
    INSTALL_CMD=$2

    if ! command -v "$COMMAND" >/dev/null 2>&1; then
        echo "$COMMAND not found... installing globally..."
        eval "$INSTALL_CMD"
    else
        echo "$COMMAND found... checking if it's globally installed..."

        GLOBAL_PATHS=("/usr/local/bin" "/opt/homebrew/bin")
        INSTALLED_PATH=$(command -v "$COMMAND")
        GLOBAL=false

        for PATH in "${GLOBAL_PATHS[@]}"; do
            if [[ "$INSTALLED_PATH" == "$PATH"* ]]; then
                GLOBAL=true
                break
            fi
        done

        if [ "$GLOBAL" = false ]; then
            echo "$COMMAND is not installed globally. Reinstalling globally..."
            eval "$INSTALL_CMD"
        else
            echo "$COMMAND is installed globally. Skipping installation."
        fi
    fi
}

installCocoaPods() {
    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods is already installed."
        COCOAPODS_PATH=$(get_cocoapods_path)
        addToPath "export PATH=\$PATH:$COCOAPODS_PATH"
    else
        echo "CocoaPods is not installed. Installing via gem..."
        gem install cocoapods
        COCOAPODS_PATH=$(get_cocoapods_path)
        addToPath "export PATH=\$PATH:$COCOAPODS_PATH"
        echo "CocoaPods installation complete."
    fi

    sourceEnv

    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods was successfully installed!"
        pod --version
    else
        echo "CocoaPods installation failed."
    fi
}

installFastlane() {
    installRuby

    if gem list -i "^fastlane$" >/dev/null 2>&1; then
        echo "Fastlane installed via gem. Uninstalling gem version to avoid conflicts..."
        sudo gem uninstall fastlane
    fi

    if ! command -v fastlane >/dev/null 2>&1; then
        echo "Installing Fastlane via gem..."
        gem install fastlane
        echo "Fastlane installation complete."
    else
        echo "Fastlane is already installed."
    fi

    FASTLANE_EXECUTABLE=$(gem environment | grep 'EXECUTABLE DIRECTORY' | awk -F': ' '{print $2}')/fastlane
    addToPath "export PATH=\$PATH:$(dirname "$FASTLANE_EXECUTABLE")"

    sourceEnv

    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane was successfully installed!"
        fastlane --version
    else
        echo "Fastlane installation failed."
    fi
}

# Install Ruby via rbenv and set the correct version globally
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

    if [[ "$(ruby -v)" == *"$RUBY_VERSION"* ]]; then
        echo "Ruby version $RUBY_VERSION was successfully set as the global version!"
        ruby -v
    else
        echo "Failed to set Ruby version $RUBY_VERSION as the global version."
    fi
}

# Install rbenv if not already installed
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

# Function to add a path to shell configuration file
addToPath() {
    LINE=$1
    SHELL_CONFIG_FILE=$(get_shell_config_file)

    [ ! -f "$SHELL_CONFIG_FILE" ] && touch "$SHELL_CONFIG_FILE"

    if ! grep -qxF "$LINE" "$SHELL_CONFIG_FILE"; then
        echo "$LINE" >> "$SHELL_CONFIG_FILE"
    fi

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

# Source environment variables
sourceEnv() {
    SHELL_CONFIG_FILE=$(get_shell_config_file)
    
    [ ! -f "$SHELL_CONFIG_FILE" ] && touch "$SHELL_CONFIG_FILE"

    echo "Sourcing $SHELL_CONFIG_FILE to apply changes..."
    source "$SHELL_CONFIG_FILE"

    echo "Path and environment variables refreshed in the current terminal session."
}

# Install Android Studio and SDK
installAndroidStudioAndSdk() {
    sourceEnv

    replaceAdoptOpenJDKWithTemurin

    if ! brew list --cask | grep -q "^android-studio$"; then
        echo "Installing Android Studio..."
        brew install --cask android-studio
        echo "Android Studio installation complete."
    else
        echo "Android Studio is already installed."
    fi

    sourceEnv

    COMMAND_LINE_TOOL_VERSION=$(curl -s https://dl.google.com/android/repository/repository2-1.xml \
    | grep -oE 'commandlinetools-mac-[0-9]+' \
    | grep -oE '[0-9]+' \
    | sort -V | tail -1)

    COMMAND_LINE_TOOL_FILE="commandlinetools-mac-${COMMAND_LINE_TOOL_VERSION}_latest.zip"
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

    installAndroidPackage "platform-tools"

    PLATFORM_VERSION=$(sdkmanager --list | grep "platforms;android-" | grep -oE '[0-9]+' | sort -nr | head -n 1)
    BUILD_TOOLS_VERSION=$(sdkmanager --list | grep "build-tools;" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -nr | head -n 1)

    echo "Installing platform version: ${PLATFORM_VERSION}, build tools version: ${BUILD_TOOLS_VERSION}"

    installAndroidPackage "platforms;android-${PLATFORM_VERSION}"
    installAndroidPackage "build-tools;${BUILD_TOOLS_VERSION}"
    installAndroidPackage "cmdline-tools;latest"
    installAndroidPackage "system-images;android-${PLATFORM_VERSION};google_apis;x86_64"

    sourceEnv

    yes | sdkmanager --licenses
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

    echo "Updating Homebrew..."
    brew update

    LATEST_FLUTTER_VERSION=$(brew info --cask flutter | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

    if command -v flutter &> /dev/null; then
        INSTALLED_FLUTTER_VERSION=$(flutter --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

        if [ "$INSTALLED_FLUTTER_VERSION" == "$LATEST_FLUTTER_VERSION" ]; then
            echo "Flutter is already at the latest version ($INSTALLED_FLUTTER_VERSION). Skipping installation..."
        else
            echo "Updating Flutter from version $INSTALLED_FLUTTER_VERSION to $LATEST_FLUTTER_VERSION..."
            brew reinstall --cask flutter
        fi
    else
        echo "Installing Flutter..."
        brew install --cask flutter
    fi

    FLUTTER_DIR="/opt/homebrew/Caskroom/flutter/$LATEST_FLUTTER_VERSION/flutter"
    
    if [ -d "$FLUTTER_DIR" ]; then
        echo "Changing permissions for Flutter directory: $FLUTTER_DIR"
        sudo chmod -R 777 "$FLUTTER_DIR"
    else
        echo "Error: Flutter directory not found at $FLUTTER_DIR."
    fi

    addToPath 'export PATH="`pwd`/flutter/bin:$PATH"'

    git config --global --add safe.directory $FLUTTER_DIR
    
    flutter config --android-sdk $ANDROID_HOME
    flutter doctor --android-licenses
    flutter doctor
}

installVSCode() {
    sourceEnv
    installApp 'Visual Studio Code' 'brew install --cask visual-studio-code'
    addToPath 'export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/:$PATH"'
}

installVSCodeExtension() {
    EXTENSION_NAME=$1
    EXTENSION_INSTALLED=false
    INSTALLED_VERSION=""
    LATEST_VERSION=""
    
    if command -v code >/dev/null 2>&1; then
        INSTALLED_VERSION=$(code --list-extensions --show-versions | grep "^$EXTENSION_NAME@" | cut -d'@' -f2)
        
        if [ -n "$INSTALLED_VERSION" ]; then
            echo "VS Code extension $EXTENSION_NAME is already installed with version $INSTALLED_VERSION."
            EXTENSION_INSTALLED=true
        fi
    else
        echo "Visual Studio Code is not installed. Please install it first."
        return
    fi
    
    LATEST_VERSION=$(code --install-extension $EXTENSION_NAME --force --dry-run 2>&1 | grep "Installing extension '$EXTENSION_NAME'" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "Failed to retrieve the latest version of the extension $EXTENSION_NAME."
        return
    fi
    
    if [ "$EXTENSION_INSTALLED" = true ]; then
        if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
            echo "Upgrading $EXTENSION_NAME from version $INSTALLED_VERSION to $LATEST_VERSION..."
            code --install-extension $EXTENSION_NAME --force
        else
            echo "VS Code extension $EXTENSION_NAME is up-to-date with version $INSTALLED_VERSION."
        fi
    else
        echo "Installing VS Code extension $EXTENSION_NAME..."
        code --install-extension $EXTENSION_NAME
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

