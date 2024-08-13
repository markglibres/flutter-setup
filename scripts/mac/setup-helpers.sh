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

# Function to add CocoaPods to the PATH
add_cocoapods_to_path() {
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        # Default to ~/.profile if the shell is not recognized
        SHELL_CONFIG_FILE=~/.profile
    fi

    PODS_PATH=$(gem environment | grep -E 'EXECUTABLE DIRECTORY' | awk '{print $3}')
    
    if ! grep -q "$PODS_PATH" "$SHELL_CONFIG_FILE"; then
        echo "Adding CocoaPods to the PATH in $SHELL_CONFIG_FILE"
        echo "export PATH=\$PATH:$PODS_PATH" >> "$SHELL_CONFIG_FILE"
        source "$SHELL_CONFIG_FILE"
        echo "CocoaPods successfully added to the PATH."
    else
        echo "CocoaPods is already in the PATH."
    fi
}

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

# Function to add rbenv to the PATH
add_rbenv_to_path() {
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        # Default to ~/.profile if the shell is not recognized
        SHELL_CONFIG_FILE=~/.profile
    fi

    if ! grep -q 'export PATH="$HOME/.rbenv/bin:$PATH"' "$SHELL_CONFIG_FILE"; then
        echo 'Adding rbenv to the PATH in $SHELL_CONFIG_FILE'
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$SHELL_CONFIG_FILE"
        echo 'eval "$(rbenv init -)"' >> "$SHELL_CONFIG_FILE"
        source "$SHELL_CONFIG_FILE"
        echo "rbenv successfully added to the PATH."
    else
        echo "rbenv is already in the PATH."
        source "$SHELL_CONFIG_FILE"
    fi
}

# Function to add Fastlane to the PATH
add_fastlane_to_path() {
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        # Default to ~/.profile if the shell is not recognized
        SHELL_CONFIG_FILE=~/.profile
    fi

    # Check if Fastlane's bin path is in the PATH
    if ! grep -q "export PATH=\"\$HOME/.fastlane/bin:\$PATH\"" "$SHELL_CONFIG_FILE"; then
        echo "Adding Fastlane to the PATH in $SHELL_CONFIG_FILE"
        echo 'export PATH="$HOME/.fastlane/bin:$PATH"' >> "$SHELL_CONFIG_FILE"
        source "$SHELL_CONFIG_FILE"
        echo "Fastlane successfully added to the PATH."
    else
        echo "Fastlane is already in the PATH."
        source "$SHELL_CONFIG_FILE"
    fi
}

# Function to get the installed version of Android Studio
get_android_studio_installed_version() {
    if [ -d "/Applications/Android Studio.app" ]; then
        /Applications/Android\ Studio.app/Contents/MacOS/studio -version | grep 'Android Studio' | awk '{print $3}'
    else
        echo "Not installed"
    fi
}

# Function to get the latest version of Android Studio from Homebrew
get_android_studio_latest_version() {
    brew info android-studio | grep "android-studio:" | awk '{print $3}'
}

# Function to uninstall Android Studio if installed
uninstall_android_studio() {
    if brew list --cask | grep -q "android-studio"; then
        echo "Uninstalling Android Studio using Homebrew..."
        brew uninstall --cask android-studio
    elif [ -d "/Applications/Android Studio.app" ]; then
        echo "Removing manually installed Android Studio..."
        rm -rf "/Applications/Android Studio.app"
    else
        echo "Android Studio is not installed."
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
    # Check if CocoaPods is installed
    if gem list -i "^cocoapods$" >/dev/null 2>&1; then
        echo "CocoaPods is already installed."
        add_cocoapods_to_path
    else
        echo "CocoaPods is not installed. Installing now..."
        sudo gem install cocoapods
        add_cocoapods_to_path
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

installFastlane() {
    installRuby
    # Check if Fastlane is installed
    if command -v fastlane >/dev/null 2>&1; then
        echo "Fastlane is already installed."
        add_fastlane_to_path
    else
        echo "Fastlane is not installed. Installing now..."
        
        # Install Fastlane using Homebrew or RubyGems
        if command -v brew >/dev/null 2>&1; then
            brew install fastlane
        else
            echo "Homebrew is not installed. Installing Fastlane via RubyGems..."
            sudo gem install fastlane
        fi
        
        add_fastlane_to_path
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

installRuby() {
    # Check if rbenv is installed
    # Install a specific version of Ruby using rbenv
    RUBY_VERSION="3.1.0"  # You can change this to any version you want to install
    
    if ! rbenv versions | grep -q "$RUBY_VERSION"; then
        echo "Installing Ruby version $RUBY_VERSION..."
        rbenv install "$RUBY_VERSION"
    else
        echo "Ruby version $RUBY_VERSION is already installed."
    fi
    
    # Set the installed Ruby version as global
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

installAndroidStudio() {
    # Get the installed and latest versions
    INSTALLED_VERSION=$(get_android_studio_installed_version)
    LATEST_VERSION=$(get_android_studio_latest_version)
    
    # Check if Android Studio is installed and up-to-date
    if [ "$INSTALLED_VERSION" == "Not installed" ]; then
        echo "Android Studio is not installed. Installing now..."
        brew install --cask android-studio
        echo "Android Studio installation complete."
    elif [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
        echo "Installed version of Android Studio ($INSTALLED_VERSION) is outdated. Uninstalling and reinstalling to update to version $LATEST_VERSION..."
        
        # Uninstall the existing Android Studio
        uninstall_android_studio
        
        # Reinstall the latest version of Android Studio
        brew install --cask android-studio
        echo "Android Studio updated to version $LATEST_VERSION."
    else
        echo "Android Studio is already up-to-date (version $INSTALLED_VERSION)."
    fi
    
    # Check if the Android SDK is installed
    ANDROID_HOME=$HOME/Library/Android/sdk
    if [ ! -d "$ANDROID_HOME" ]; then
        echo "Android SDK not found. Installing Android SDK..."
        
        # Open Android Studio to trigger the initial setup wizard
        open -a "Android Studio"
        
        echo "Please complete the initial setup wizard in Android Studio to install the Android SDK."
        echo "Waiting for Android Studio to close before continuing..."
    
        # Wait for Android Studio to close
        while pgrep -x "studio" > /dev/null; do
            sleep 5
        done
        
        echo "Android Studio has closed. Continuing with the script..."
    else
        echo "Android SDK found at $ANDROID_HOME"
    fi
    
    # Add Android SDK to PATH
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        SHELL_CONFIG_FILE=~/.profile
    fi
    
    if ! grep -q "export ANDROID_HOME=$ANDROID_HOME" "$SHELL_CONFIG_FILE"; then
        echo "Adding Android SDK to PATH in $SHELL_CONFIG_FILE"
        echo "export ANDROID_HOME=$ANDROID_HOME" >> "$SHELL_CONFIG_FILE"
        echo "export PATH=\$PATH:\$ANDROID_HOME/emulator:\$ANDROID_HOME/tools:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools" >> "$SHELL_CONFIG_FILE"
        source "$SHELL_CONFIG_FILE"
    else
        echo "Android SDK is already in the PATH."
        source "$SHELL_CONFIG_FILE"
    fi
    
    # Configure Flutter to use the Android SDK
    flutter config --android-sdk "$ANDROID_HOME"
    
    # Run Flutter doctor to verify the installation
    flutter doctor
    
    echo "Android SDK installation and configuration are complete."
    echo "Please restart your terminal or run 'source $SHELL_CONFIG_FILE' to apply the changes."

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
    # Determine which shell configuration file to use
    SHELL_CONFIG_FILE=""
    if [[ $SHELL == *zsh* ]]; then
        SHELL_CONFIG_FILE=~/.zprofile
    elif [[ $SHELL == *bash* ]]; then
        SHELL_CONFIG_FILE=~/.bash_profile
    else
        SHELL_CONFIG_FILE=~/.profile
    fi
    
    # Check if the file exists, create it if it does not
    if [ ! -f "$SHELL_CONFIG_FILE" ]; then
        touch "$SHELL_CONFIG_FILE"
        echo "$SHELL_CONFIG_FILE has been created."
    fi
    
    # Source the shell configuration file to apply changes immediately
    echo "Sourcing $SHELL_CONFIG_FILE to apply changes..."
    source "$SHELL_CONFIG_FILE"
    
    echo "Path and environment variables refreshed in the current terminal session."
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
