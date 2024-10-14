#!/bin/bash

# Function to install Homebrew if it's not already installed
installBrew() {
    # Check if brew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."

        # Run the Homebrew installation script
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ $? -ne 0 ]; then
            echo "Failed to install Homebrew. Exiting."
            exit 1
        else
            echo "Homebrew installed successfully."
        fi
    else
        echo "Homebrew is already installed."
    fi

    # Call the function to set Homebrew ownership to the current user
    setBrewOwnership

    # Add Homebrew to the PATH
    addToPath 'export PATH="/opt/homebrew/bin:$PATH"'

    # Source environment variables to update the session
    sourceEnv
}

# Function to set ownership of /opt/homebrew to the current user
setBrewOwnership() {
    CURRENT_USER=$(whoami)
    
    if [ -d "/opt/homebrew" ]; then
        echo "Setting ownership of /opt/homebrew to $CURRENT_USER..."
        sudo chown -R $CURRENT_USER /opt/homebrew
        if [ $? -eq 0 ]; then
            sudo chmod -R u+w /opt/homebrew
            sudo find /opt/homebrew -type d -exec chmod u+s {} \;
            echo "Ownership has been updated successfully for /opt/homebrew."
        else
            echo "Failed to change ownership to user $CURRENT_USER. Exiting."
            exit 1
        fi
    else
        echo "/opt/homebrew directory not found. Skipping ownership adjustment."
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

# Function to detect Android Studio installation and set JAVA_HOME
check_android_studio() {
    ANDROID_STUDIO_PATH="/Applications/Android Studio.app"
    JAVA_HOME_PATH="$ANDROID_STUDIO_PATH/Contents/jbr/Contents/Home"

    # Check if Android Studio is installed
    if [ ! -d "$ANDROID_STUDIO_PATH" ]; then
        echo "Android Studio is not installed."
        echo "Please download and install Android Studio from:"
        echo "https://developer.android.com/studio"
        echo ""
        echo "Press Enter once the installation is complete to continue..."
        
        # Wait for user to press Enter
        read -p ""
        
        # Check if Android Studio was installed after user hit Enter
        if [ ! -d "$ANDROID_STUDIO_PATH" ]; then
            echo "Android Studio installation not detected. Please make sure it's installed."
            exit 1
        fi
    fi

    # Check if JAVA_HOME is already set to Android Studio's JDK
    if [[ "$JAVA_HOME" != "$JAVA_HOME_PATH" ]]; then
        echo "Setting JAVA_HOME to Android Studio's JDK..."
        export JAVA_HOME="$JAVA_HOME_PATH"

        # Add JAVA_HOME to the shell configuration file for persistence
        SHELL_CONFIG_FILE=$(get_shell_config_file)
        echo "export JAVA_HOME=\"$JAVA_HOME_PATH\"" >> "$SHELL_CONFIG_FILE"
        
        # Source the configuration file to apply changes immediately
        source "$SHELL_CONFIG_FILE"
        
        echo "JAVA_HOME has been updated to: $JAVA_HOME_PATH"
    else
        echo "JAVA_HOME is already set correctly."
    fi
}

# Function to install Cursor IDE
installCursorIDE() {
    sourceEnv

    # Check if Cursor IDE is already installed
    if [ -d "/Applications/Cursor.app" ]; then
        echo "Cursor IDE is already installed."
    else
        echo "Cursor IDE is not installed. Installing..."

        # Use Homebrew to install Cursor IDE via cask
        brew install --cask cursor

        if [ $? -eq 0 ]; then
            echo "Cursor IDE installation complete."
        else
            echo "Cursor IDE installation failed."
            exit 1
        fi
    fi

    # Add Cursor IDE to the PATH
    addToPath 'export PATH="/Applications/Cursor.app/Contents/Resources/app/bin/:$PATH"'

    # Source environment variables to update the session
    sourceEnv
}