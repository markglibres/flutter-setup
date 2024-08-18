#!/bin/bash

install() {
    COMMAND=$1
    INSTALL_CMD=$2

    # Check if the command is available
    if ! command -v "$COMMAND" >/dev/null 2>&1; then
        echo "$COMMAND not found... installing...."
        eval "$INSTALL_CMD"
    else
        echo "$COMMAND found... skipping..."
    fi
}

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
# Add to PATH and source configuration file
addToPath() {
    LINE=$1
    SHELL_CONFIG_FILE=$(get_shell_config_file)

    # Create the configuration file if it doesn't exist
    [ ! -f "$SHELL_CONFIG_FILE" ] && touch "$SHELL_CONFIG_FILE"

    # Add the line to the configuration file if it's not already present
    if ! grep -qxF "$LINE" "$SHELL_CONFIG_FILE"; then
        echo "$LINE" >> "$SHELL_CONFIG_FILE"
    fi

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

    # Fixing permissions for the entire Homebrew directory
    echo "Fixing Homebrew permissions..."
    sudo chown -R $(whoami) /opt/homebrew
    sudo chmod -R u+rw /opt/homebrew

    # Adding safe directories for Git
    echo "Adding Homebrew directories to Git safe directory list..."
    git config --global --add safe.directory /opt/homebrew/Library/Taps/homebrew/homebrew-core
    git config --global --add safe.directory /opt/homebrew/Library/Taps/homebrew/homebrew-cask
    echo "Permissions and safe directories have been updated."

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

# Function to add CocoaPods to the PATH
installCocoaPods() {
    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods is already installed."
        COCOAPODS_PATH=$(get_cocoapods_path)
        addToPath "export PATH=\$PATH:$COCOAPODS_PATH"
    else
        echo "CocoaPods is not installed. Installing now..."
        sudo gem install cocoapods
        COCOAPODS_PATH=$(get_cocoapods_path)
        addToPath "export PATH=\$PATH:$COCOAPODS_PATH"
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
    PODS_PATH=$(gem environment | grep -E 'EXECUTABLE DIRECTORY' | awk -F': ' '{print $2}')
    if [ -n "$PODS_PATH" ]; then
        echo "$PODS_PATH"
    else
        echo "Error: Unable to determine CocoaPods executable directory."
        exit 1
    fi
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

# Function to install or upgrade Fastlane
installFastlane() {
    installRuby

    # Disable Homebrew auto-update to avoid unnecessary delays
    export HOMEBREW_NO_AUTO_UPDATE=1
    export HOMEBREW_NO_ENV_HINTS=1

    # Check if Fastlane is installed
    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane is already installed."

        # Get the installed version
        INSTALLED_VERSION=$(fastlane --version | awk '{print $2}')

        # Get the latest version available via Homebrew using JSON output
        LATEST_VERSION=$(brew info --json=v1 fastlane | jq -r '.[0].versions.stable')

        # Compare installed version with the latest version
        if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
            echo "A new version of Fastlane is available. Upgrading from $INSTALLED_VERSION to $LATEST_VERSION..."
            brew upgrade fastlane
            echo "Fastlane upgraded to version $LATEST_VERSION."
        else
            echo "Fastlane is already at the latest version ($INSTALLED_VERSION)."
        fi
    else
        echo "Fastlane is not installed. Installing now..."
        brew install fastlane
        echo "Fastlane installation complete."
    fi

    # Add Fastlane to PATH
    FASTLANE_PATH=$(get_fastlane_path)

    if [ -d "$FASTLANE_PATH" ]; then
        addToPath "$FASTLANE_PATH"
    fi

    sourceEnv

    # Verify Fastlane installation
    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane was successfully installed or upgraded!"
        fastlane --version
    else
        echo "Fastlane installation failed."
    fi
}


get_fastlane_path() {
    # This function returns the path where Fastlane is installed
    echo "$(brew --prefix fastlane)/libexec/bin"
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

    # Force Homebrew to update
    echo "Updating Homebrew..."
    brew update

    # Fetch the latest version of Flutter
    LATEST_FLUTTER_VERSION=$(brew info --cask flutter | grep -Eo 'flutter@[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 | cut -d'@' -f2)

    # Check if Flutter is installed and get the installed version
    if command -v flutter &> /dev/null; then
        INSTALLED_FLUTTER_VERSION=$(flutter --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

        if [ "$INSTALLED_FLUTTER_VERSION" == "$LATEST_FLUTTER_VERSION" ]; then
            echo "Flutter is already at the latest version ($INSTALLED_FLUTTER_VERSION). Skipping installation..."
        else
            echo "Updating Flutter to the latest version ($LATEST_FLUTTER_VERSION)..."
            brew reinstall --cask flutter
        fi
    else
        echo "Installing Flutter..."
        brew install --cask flutter
        sudo chmod -R 777 "$FLUTTER_DIR"
    fi

    addToPath 'export PATH="`pwd`/flutter/bin:$PATH"'

    # Fix permissions issue
    FLUTTER_DIR="/opt/homebrew/Caskroom/flutter/$LATEST_FLUTTER_VERSION/flutter"
    git config --global --add safe.directory $FLUTTER_DIR
    
    flutter config --android-sdk $ANDROID_HOME
    flutter doctor --android-licenses
    flutter doctor
    
    # if [ -d "$FLUTTER_DIR" ]; then
    #    echo "Changing ownership and permissions for Flutter directory: $FLUTTER_DIR"
    #    sudo chown -R $(whoami) "$FLUTTER_DIR"
    #    sudo chmod -R 777 "$FLUTTER_DIR"
    #    echo "Ownership and permissions have been updated successfully."
    #else
    #    echo "Error: Flutter directory not found."
    #fi
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
    
    # Check if the extension is installed
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
    
    # Fetch the latest version from the VS Code Marketplace
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

