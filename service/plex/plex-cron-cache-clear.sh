#!/bin/bash
# This script adds a cron job to clear the Plex Cache/PhotoTranscoder folder of jpgs older than 5 days
PLEX_CACHE_DIR="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Cache/PhotoTranscoder"

# Check if the PhotoTranscoder folder exists
if [ ! -d "$PLEX_CACHE_DIR" ]; then
    echo "Error: The PhotoTranscoder folder does not exist at $PLEX_CACHE_DIR"
    echo "Please check the path and ensure Plex Media Server is installed correctly."
    exit 1
fi

# Check if a similar cron job already exists
if crontab -l | grep -q "find \"$PLEX_CACHE_DIR\" -name \"\*.jpg\" -type f -mtime +5 -delete"; then
    echo "A similar cron job is already active. Exiting."
    exit 0
fi

# Function to get user input for hour
get_hour() {
    while true; do
        read -p "Enter the hour (0-23) when the job should run: " hour
        if [[ $hour =~ ^[0-9]+$ ]] && [ "$hour" -ge 0 ] && [ "$hour" -le 23 ]; then
            break
        else
            echo "Invalid input. Please enter a number between 0 and 23."
        fi
    done
}

# Function to get user input for frequency
get_frequency() {
    echo "Select the frequency of the job:"
    echo "1. Daily"
    echo "2. Weekly"
    echo "3. Monthly"
    read -p "Enter your choice (1/2/3): " freq_choice

    case $freq_choice in
        1) frequency="* * *";;
        2) 
            read -p "Enter the day of the week (0-6, where 0 is Sunday): " dow
            frequency="* * $dow"
            ;;
        3) 
            read -p "Enter the day of the month (1-31): " dom
            frequency="$dom * *"
            ;;
        *) echo "Invalid choice. Defaulting to daily."; frequency="* * *";;
    esac
}

# Get user input
get_hour
get_frequency

# Construct the cron job
CRON_JOB="0 $hour $frequency find \"$PLEX_CACHE_DIR\" -name \"*.jpg\" -type f -mtime +5 -delete"

# Add the cron job
echo "Adding the cron job..."
(crontab -l; echo "$CRON_JOB") | crontab -
echo "Cron job added successfully."

# Display the added cron job
echo "The following cron job has been set:"
echo "$CRON_JOB"