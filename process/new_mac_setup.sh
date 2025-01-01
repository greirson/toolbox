#!/bin/bash

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 

# Add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zsrc
eval "$(/opt/homebrew/bin/brew shellenv)"

# Update and upgrade Homebrew
brew update
brew upgrade

# Install applications via Homebrew Cask
brew install --cask 1password
brew install --cask 1password-cli
brew install --cask balenaetcher
brew install --cask betterdisplay
brew install --cask caffeine
brew install --cask cardhop
brew install --cask chatgpt
brew install --cask cursor
brew install --cask cyberduck
brew install --cask discord
brew install --cask docker
brew install --cask fantastical
brew install --cask firefox
brew install --cask google-chrome
brew install --cask google-drive
brew install --cask home-assistant
brew install --cask iterm2
brew install --cask linear-linear
brew install --cask logitech-g-hub
brew install --cask losslesscut
brew install --cask mountain-duck
brew install ntfy
brew install --cask notion
brew install --cask notion-calendar
brew install --cask obsidian
brew install --cask plexamp
brew install --cask raycast
brew install rsync
brew install --cask slack
brew install --cask snagit
brew install --cask soundsource
brew install --cask spotify
brew install --cask steam
brew install --cask superhuman
brew install --cask termius
brew install --cask visual-studio-code
brew install --cask vlc
brew install --cask wifiman
brew install --cask zoom

# Install mas for app store applications
brew install mas
# Clean up
brew cleanup

# Install applications from the Mac App Store
mas install 904280696 # Things
mas install 1435957248 # Drafts
mas install 441258766 # Magnet
mas install 1136220934 # Infuse

# Function to add an application to the Dock
add_to_dock() {
    local app_path="/Applications/$1.app"
    if [ -e "$app_path" ]; then
        defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app_path</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    else
        echo "Application $1 not found in /Applications."
    fi
}

# Clear existing Dock apps
defaults write com.apple.dock persistent-apps -array

# Add desired applications to the Dock
add_to_dock "Messages"
add_to_dock "Todoist"
add_to_dock "Slack"
add_to_dock "Superhuman"
add_to_dock "Reminders"
add_to_dock "Arc"
add_to_dock "Notion Calendar"
add_to_dock "Notion"
add_to_dock "Spotify"
add_to_dock "ChatGPT"
add_to_dock "Cursor"
add_to_dock "zoom.us"
add_to_dock "Obsidian"
add_to_dock "1Password"
add_to_dock "Discord"
add_to_dock "Termius"

# Restart the Dock to apply changes
killall Dock

echo "Dock setup complete!"

# SUCCESS!!!
echo "Setup complete! All them apps" 