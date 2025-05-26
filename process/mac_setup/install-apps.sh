#!/bin/bash

set -euo pipefail

# Configuration
APP_LIST="apps.txt"
LOG_FILE="install.log"
MAX_PARALLEL=4
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --parallel) MAX_PARALLEL="$2"; shift 2 ;;
        --help) 
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --dry-run       Show what would be installed without installing"
            echo "  --parallel N    Set number of parallel installations (default: 4)"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        success "Homebrew is already installed"
        return 0
    fi
    
    log "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew installed successfully"
    else
        error "Failed to install Homebrew"
        exit 1
    fi
}

get_package_type() {
    local app="$1"
    
    # Check if it's a cask first (most GUI apps are casks)
    if brew info --cask "$app" &>/dev/null; then
        echo "cask"
    elif brew info "$app" &>/dev/null; then
        echo "formula"
    else
        echo "unknown"
    fi
}

is_installed() {
    local app="$1"
    brew list "$app" &>/dev/null || brew list --cask "$app" &>/dev/null
}

parse_app_line() {
    local line="$1"
    local app=""
    local type=""
    
    # Skip empty lines or comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        return 1
    fi
    
    # Check if line has type specified (app:type format)
    if [[ "$line" =~ ^([^:]+):([^:]+)$ ]]; then
        app="${BASH_REMATCH[1]}"
        type="${BASH_REMATCH[2]}"
    else
        app="$line"
        type=""
    fi
    
    # Trim whitespace
    app=$(echo "$app" | xargs)
    type=$(echo "$type" | xargs)
    
    echo "$app|$type"
    return 0
}

update_apps_file() {
    local temp_file="${APP_LIST}.tmp"
    local updated=false
    
    > "$temp_file"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Preserve comments and empty lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi
        
        local parsed=$(parse_app_line "$line")
        if [[ -z "$parsed" ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi
        
        local app="${parsed%%|*}"
        local type="${parsed##*|}"
        
        # If type is not specified, determine it
        if [[ -z "$type" ]]; then
            type=$(get_package_type "$app")
            if [[ "$type" != "unknown" ]]; then
                echo "${app}:${type}" >> "$temp_file"
                updated=true
                log "Updated $app with type: $type"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$APP_LIST"
    
    if $updated; then
        mv "$temp_file" "$APP_LIST"
        success "Updated $APP_LIST with package types"
    else
        rm -f "$temp_file"
    fi
}

install_app() {
    local app="$1"
    local type="$2"
    local max_retries=3
    local retry=0
    
    # Check if already installed
    if is_installed "$app"; then
        warning "$app is already installed, skipping..."
        echo "[$(date '+%H:%M:%S')] ⚠️  $app is already installed" >> "$LOG_FILE"
        return 0
    fi
    
    if $DRY_RUN; then
        log "[DRY RUN] Would install $app ($type)"
        return 0
    fi
    
    log "Installing: $app ($type)"
    echo "[$(date '+%H:%M:%S')] Installing: $app ($type)" >> "$LOG_FILE"
    
    # Retry logic
    while ((retry < max_retries)); do
        local install_cmd=""
        
        case "$type" in
            "cask")
                install_cmd="brew install --cask $app"
                ;;
            "formula")
                install_cmd="brew install $app"
                ;;
            *)
                # Try to determine type if unknown
                type=$(get_package_type "$app")
                if [[ "$type" == "cask" ]]; then
                    install_cmd="brew install --cask $app"
                elif [[ "$type" == "formula" ]]; then
                    install_cmd="brew install $app"
                else
                    error "Cannot determine package type for: $app"
                    echo "[$(date '+%H:%M:%S')] ❌ Cannot determine type: $app" >> "$LOG_FILE"
                    return 1
                fi
                ;;
        esac
        
        if $install_cmd >> "$LOG_FILE" 2>&1; then
            success "Installed $app ($type)"
            echo "[$(date '+%H:%M:%S')] ✅ Installed $app ($type)" >> "$LOG_FILE"
            return 0
        fi
        
        ((retry++))
        if ((retry < max_retries)); then
            warning "Installation failed, retry $retry/$max_retries for $app"
            sleep 2
        fi
    done
    
    error "Failed to install: $app after $max_retries attempts"
    echo "[$(date '+%H:%M:%S')] ❌ Failed to install: $app" >> "$LOG_FILE"
    return 1
}

cleanup() {
    if ! $DRY_RUN; then
        log "Running Homebrew cleanup..."
        brew cleanup >> "$LOG_FILE" 2>&1 || true
        brew autoremove >> "$LOG_FILE" 2>&1 || true
    fi
}

main() {
    log "Starting Homebrew app installer"
    
    if $DRY_RUN; then
        warning "Running in DRY RUN mode - no actual installations will occur"
    fi
    
    # Setup
    install_homebrew
    
    # Clear previous log
    if ! $DRY_RUN; then
        rm -f "$LOG_FILE"
        echo "Installation started at $(date)" > "$LOG_FILE"
    fi
    
    # Fix Homebrew cache issues
    if ! $DRY_RUN; then
        log "Updating Homebrew..."
        echo "[$(date '+%H:%M:%S')] Updating Homebrew..." >> "$LOG_FILE"
        if ! brew update --force >> "$LOG_FILE" 2>&1; then
            warning "Homebrew update had issues, continuing..."
        fi
    fi
    
    # Check if apps list exists
    if [[ ! -f "$APP_LIST" ]]; then
        error "$APP_LIST not found"
        exit 1
    fi
    
    # Update apps.txt with package types
    log "Updating $APP_LIST with package types..."
    update_apps_file
    
    # Count total apps
    local total_apps=$(grep -cvE '^\s*(#|$)' "$APP_LIST" 2>/dev/null || echo 0)
    local current=0
    
    log "Installing apps (parallel: $MAX_PARALLEL)"
    echo "[$(date '+%H:%M:%S')] Installing apps (parallel: $MAX_PARALLEL)" >> "$LOG_FILE"
    
    local failed_apps=()
    local successful_apps=()
    local pids=()
    local apps_in_batch=()
    
    # Process apps
    while IFS= read -r line || [[ -n "$line" ]]; do
        local parsed=$(parse_app_line "$line")
        [[ -z "$parsed" ]] && continue
        
        local app="${parsed%%|*}"
        local type="${parsed##*|}"
        
        ((current++))
        log "[$current/$total_apps] Processing: $app"
        
        # Run installation in background
        {
            if install_app "$app" "$type"; then
                echo "SUCCESS:$app"
            else
                echo "FAILED:$app"
            fi
        } &
        
        local pid=$!
        pids+=($pid)
        apps_in_batch+=("$app")
        
        # Wait for batch to complete
        if ((${#pids[@]} >= MAX_PARALLEL)); then
            for i in "${!pids[@]}"; do
                wait "${pids[$i]}"
                local result=$(cat <<< "$?")
            done
            pids=()
            apps_in_batch=()
        fi
    done < "$APP_LIST"
    
    # Wait for remaining jobs
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # Parse results from log file to get accurate counts
    if [[ -f "$LOG_FILE" ]] && ! $DRY_RUN; then
        successful_apps=($(grep -E "✅ Installed" "$LOG_FILE" | grep -oE "[^ ]+$" | sort -u))
        failed_apps=($(grep -E "❌ Failed to install:" "$LOG_FILE" | grep -oE "[^ ]+$" | sort -u))
    fi
    
    # Final summary
    echo ""
    echo "" >> "$LOG_FILE"
    success "Installation complete!"
    success "Successfully installed: ${#successful_apps[@]} apps"
    
    if ! $DRY_RUN; then
        echo "[$(date '+%H:%M:%S')] ✅ Installation complete!" >> "$LOG_FILE"
        echo "[$(date '+%H:%M:%S')] Successfully installed: ${#successful_apps[@]} apps" >> "$LOG_FILE"
    fi
    
    if [[ ${#failed_apps[@]} -gt 0 ]]; then
        error "Failed to install: ${#failed_apps[@]} apps"
        error "Failed apps: ${failed_apps[*]}"
        if ! $DRY_RUN; then
            echo "[$(date '+%H:%M:%S')] ❌ Failed apps: ${failed_apps[*]}" >> "$LOG_FILE"
        fi
    fi
    
    if ! $DRY_RUN; then
        log "Detailed logs available in: $LOG_FILE"
    fi
    
    # Set up cleanup trap
    trap cleanup EXIT
}

# Run main function
main