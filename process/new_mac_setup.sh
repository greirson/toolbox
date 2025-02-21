#!/bin/bash

# Set -e to exit immediately on error
set -e

# Log file
log_file="$HOME/new_mac_setup.log"

# Function to log messages with timestamps
log() {
    echo "$(date) - $1" >> "$log_file"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a cask is installed
cask_installed() {
    brew list --cask | grep -q "$1"
}

# --- Progress and UI Functions ---

# Function to display a progress bar (using dialog if available)
display_progress() {
    local title="$1"
    local message="$2"
    local current_step="$3"
    local total_steps="$4"

    if command_exists dialog; then
        (
            echo "XXX" # Start of dialog's gauge format
            echo "$current_step"
            echo "$message"
            echo "XXX"
            # Calculate percentage (ensure it's an integer)
            percent=$(( (current_step * 100) / total_steps ))
            echo "$percent"
        ) | dialog --title "$title" --gauge "$message" 10 70 0
    else
        # Fallback: Simple echo with estimated time (very rough estimate)
        echo "$title: $message (Step $current_step/$total_steps)..."
        # Add a short delay to simulate progress.  Longer for update/upgrade.
        case "$message" in
          *"Updating Homebrew"*) sleep 5 ;;
          *"Upgrading Homebrew"*) sleep 8 ;;
          *) sleep 1 ;;
        esac
    fi
}

# Function to install a single cask app with progress and idempotency
install_single_cask() {
    local app="$1"
    local step="$2"
    local total_steps="$3"

    if ! brew list --cask | grep -q "$app"; then
        log "Installing $app..."
        display_progress "Installing Applications" "Installing $app..." "$step" "$total_steps"
        if brew install --cask "$app"; then
            log "Successfully installed $app"
        else
            log "Failed to install $app. Skipping..."
            display_progress "Installing Applications" "Failed to install $app. Skipping..." "$step" "$total_steps"
        fi
    else
        log "$app is already installed. Skipping..."
        display_progress "Installing Applications" "$app already installed. Skipping..." "$step" "$total_steps"
    fi
}

# Function to install a single MAS app
install_single_mas() {
    local app_id="$1"
    local step="$2"
    local total_steps="$3"
    local app_name="$4"

    if ! mas list | grep -q "$app_id"; then
        log "Installing app with ID $app_id from Mac App Store..."
        display_progress "Installing MAS Apps" "Installing $app_name..." "$step" "$total_steps"
        if mas install "$app_id"; then
            log "Successfully installed $app_name"
        else
            log "Failed to install $app_name. Skipping..."
            display_progress "Installing MAS Apps" "Failed to install $app_name. Skipping..." "$step" "$total_steps"
        fi
    else
        log "App $app_name is already installed. Skipping..."
        display_progress "Installing MAS Apps" "$app_name already installed. Skipping..." "$step" "$total_steps"
    fi
}

# --- Main Script ---

log "Starting new Mac setup..."

# --- Step 1: Install Homebrew ---
display_progress "Initial Setup" "Installing Homebrew..." 1 8
if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zsrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    log "Homebrew is already installed."
fi

# --- Step 2: Update and upgrade Homebrew ---
display_progress "Initial Setup" "Updating and Upgrading Homebrew..." 2 8
log "Updating Homebrew..."
if ! brew update >> "$log_file" 2>&1; then
    log "Error updating Homebrew. Check log for details."
    exit 1
fi

log "Upgrading Homebrew..."
if ! brew upgrade >> "$log_file" 2>&1; then
    log "Error upgrading Homebrew. Check log for details."
    exit 1
fi

# --- Step 3: Prompt for layer selection and install apps ---
display_progress "Application Installation" "Prompting for layer selection..." 3 8
echo "Which layer of applications do you want to install?"
select layer in "Base" "Base and Overkill"; do
    case $layer in
        "Base")
            apps=(
                1password 1password-cli arc cardhop chatgpt cursor cyberduck discord docker
                fantastical firefox raycast reflect zoom superhuman notion-calendar vlc
                todoist spotify slack snagit soundsource signal
            )
            break
            ;;
        "Base and Overkill")
            apps=(
                1password 1password-cli arc bruno cardhop chatgpt cursor cyberduck discord docker
                fantastical firefox raycast reflect zoom superhuman notion-calendar vlc
                todoist spotify slack snagit soundsource signal balenaetcher betterdisplay
                caffeine google-chrome google-drive home-assistant logitech-g-hub
                mountain-duck ntfy notion obsidian plexamp rsync steam termius
                visual-studio-code wifiman
            )
            break
            ;;
        *)
            echo "Invalid selection. Please select either 'Base' or 'Base and Overkill'."
            ;;
    esac
done

# Calculate total steps for app installation
total_app_steps=${#apps[@]}
current_app_step=1

for app in "${apps[@]}"; do
    install_single_cask "$app" "$current_app_step" "$total_app_steps"
    current_app_step=$((current_app_step + 1))
done

# --- Step 4: Install mas ---
display_progress "Initial Setup" "Installing mas (Mac App Store CLI)..." 4 8
if ! command_exists mas; then
    log "Installing mas..."
    brew install mas
else
    log "mas is already installed."
fi

# --- Step 5: Install applications from the Mac App Store ---
mas_apps=(
    "904280696:Things"
    "1435957248:Drafts"
    "441258766:Magnet"
    "1136220934:Infuse"
)

total_mas_steps=${#mas_apps[@]}
current_mas_step=1

for mas_app in "${mas_apps[@]}"; do
    app_id=$(echo "$mas_app" | cut -d':' -f1)
    app_name=$(echo "$mas_app" | cut -d':' -f2)
    install_single_mas "$app_id" "$current_mas_step" "$total_mas_steps" "$app_name"
    current_mas_step=$((current_mas_step + 1))
done

# --- Step 6: Configure the Dock ---
display_progress "System Configuration" "Configuring the Dock..." 5 8
add_to_dock() {
    local app_name="$1"
    local app_path="/Applications/${app_name}"
    
    # Ensure .app extension is added if not present
    if [[ ! "$app_path" == *.app ]]; then
        app_path="${app_path}.app"
    fi
    
    if [ -e "$app_path" ]; then
        defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app_path</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
        log "Added $app_name to Dock."
    else
        log "Application $app_name not found in /Applications. Skipping."
    fi
}

# Clear existing Dock apps
defaults write com.apple.dock persistent-apps -array
log "Cleared existing Dock apps."

# Updated dock_apps with correct application names and extensions
dock_apps=(
    "Messages.app" "Todoist.app" "Slack.app" "Superhuman.app" "Reminders.app" 
    "Arc.app" "Notion Calendar.app" "Spotify.app" "ChatGPT.app" "Cursor.app" 
    "zoom.us.app" "1Password.app" "Discord.app"
)

for app in "${dock_apps[@]}"; do
    add_to_dock "$app"
done

killall Dock
log "Restarted Dock."

# --- Step 7: System Configuration ---
display_progress "System Configuration" "Setting System Preferences..." 6 8
log "Setting default web browser to Arc..."
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \
    '{"LSHandlerContentType"="public.html";"LSHandlerRoleAll"="company.thebrowser.arc";}'
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add \
    '{"LSHandlerContentType"="public.url";"LSHandlerRoleAll"="company.thebrowser.arc";}'

# Optional: Verify default browser
log "Verifying default web browser..."
if command_exists xdg-mime; then
    xdg-mime default arc.desktop text/html
    xdg-mime default arc.desktop x-scheme-handler/http
    xdg-mime default arc.desktop x-scheme-handler/https
else
    log "xdg-mime not found. Skipping default browser verification."
fi

log "Enabling firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

log "Configuring Git..."
git config --global user.name "greirson"
git config --global user.email "me@greirson.com"
git config --global core.editor "cursor"

# --- Step 8: Install Dev Tools ---
display_progress "System Configuration" "Installing Developer Tools..." 7 8
if ! command_exists xcode-select; then
    log "Installing Xcode Command Line Tools"
    xcode-select --install
else
    log "Xcode Command Line Tools already installed"
fi

if ! command_exists python3; then
    log "Installing Python 3..."
    brew install python3
else
    log "Python 3 is already installed."
fi

if ! command_exists pip3; then
    log "Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
else
    log "pip is already installed."
fi

if ! command_exists node; then
    log "Installing Node.js..."
    brew install node
else
    log "Node.js is already installed."
fi

if ! command_exists npm; then
    log "Installing npm..."
    brew install npm
else
    log "npm is already installed."
fi

# --- Completion ---
display_progress "Setup Complete" "All steps finished!" 8 8
log "Setup complete! All them apps"
echo "Setup complete!  Check $log_file for details." 
