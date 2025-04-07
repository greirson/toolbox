#!/bin/bash

# Check if GAM is installed
if ! command -v gam &> /dev/null; then
    echo "Error: GAM is not installed or not in PATH"
    echo
    echo "Please install GAM using one of these methods:"
    echo "1. Using pip:"
    echo "   pip install gam"
    echo
    echo "2. Manual installation:"
    echo "   - Download from: https://github.com/GAM-team/GAM/releases"
    echo "   - Follow instructions at: https://github.com/GAM-team/GAM/wiki/How-to-Install-Advanced-GAM"
    echo
    echo "After installation, make sure GAM is in your PATH and properly configured."
    exit 1
fi

# Function to display usage information
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -e, --email EMAIL       User's email address (the departed employee)"
    echo "  -c, --company COMPANY   Company name"
    echo "  -n, --name NAME         Contact person's name"
    echo "  -m, --contact-email EMAIL Contact person's email"
    echo "  -h, --help             Show this help message"
    exit 1
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--email)
            user_email="$2"
            shift 2
            ;;
        -c|--company)
            company_name="$2"
            shift 2
            ;;
        -n|--name)
            contact_name="$2"
            shift 2
            ;;
        -m|--contact-email)
            contact_email="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Function to prompt for input with validation
prompt_input() {
    local prompt=$1
    local var_name=$2
    local validate=$3
    local current_value=${!var_name}
    
    if [ -n "$current_value" ]; then
        echo -e "\nCurrent value for $prompt: $current_value"
        read -p "Press Enter to keep this value or type a new one: " input
        if [ -n "$input" ]; then
            current_value=$input
        fi
    else
        read -p "$prompt: " current_value
    fi
    
    if [ "$validate" = "email" ]; then
        while ! validate_email "$current_value"; do
            echo "Invalid email format. Please try again."
            read -p "$prompt: " current_value
        done
    fi
    
    eval "$var_name='$current_value'"
}

# Clear screen and show header
clear
echo "============================================="
echo "        Gmail OOO Message Setup Tool"
echo "============================================="
echo

# Prompt for required information if not provided
prompt_input "Enter the user's email address (the departed employee)" "user_email" "email"
prompt_input "Enter the company name" "company_name" ""
prompt_input "Enter the contact person's name" "contact_name" ""
prompt_input "Enter the contact person's email" "contact_email" "email"

# Construct OOO message
ooo_message="Hello! Appreciate you reaching out. I am no longer at ${company_name}, but if you need to get in contact, please reach out to ${contact_name} at ${contact_email}."

# Show preview
echo
echo "============================================="
echo "           Message Preview"
echo "============================================="
echo "$ooo_message"
echo "============================================="
echo

# Confirm before proceeding
read -p "Do you want to set this OOO message? (y/n): " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Setting OOO message..."
    gam user "$user_email" vacation on subject "Out of Office" message "$ooo_message" contactsonly off domainonly off starttime now endtime never
    echo "OOO message has been set successfully!"
else
    echo "Operation cancelled."
fi