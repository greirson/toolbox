#!/bin/sh

# Start timing
start_time=$(date +%s)

# Define variables
MEALIE_URL="https://recipes.example.com"
MEALIE_API_KEY=""
UPTIME_URL="https://uptime.example.com/api/push/YOURCODE"

# Check if jq is installed, install if not
if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not installed. Attempting to install..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y jq
    elif command -v yum >/dev/null 2>&1; then
        yum install -y jq
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache jq
    else
        echo "Could not install jq. No supported package manager found."
        curl -m 10 --retry 5 "${UPTIME_URL}?status=down&msg=JQ+Install+Failed"
        exit 1
    fi
fi

# Run backup
echo "Starting backup..."
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$MEALIE_URL/api/admin/backups" -H "Authorization: Bearer $MEALIE_API_KEY")

# Check if backup was successful
if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
    echo "Backup successful."
else
    echo "Backup failed with response code $response."
    curl -m 10 --retry 5 "${UPTIME_URL}?status=down&msg=Backup+Failed+Code+${response}"
    exit 2
fi

# Get list of backups
echo "Retrieving list of backups..."
backups=$(curl -s -X GET "$MEALIE_URL/api/admin/backups" -H "Authorization: Bearer $MEALIE_API_KEY")

# Parse and delete backups older than 7 days
current_date=$(date +%s)
seven_days_ago=$(date -d "7 days ago" +%s)

echo "Checking for backups older than 7 days..."
# Iterate over each backup
echo "$backups" | jq -c '.imports[]' | while read -r backup; do
    file_name=$(echo "$backup" | jq -r '.name')
    created_at=$(echo "$backup" | jq -r '.date')
    created_at_epoch=$(date -d "$created_at" +%s)

    if [ "$created_at_epoch" -lt "$seven_days_ago" ]; then
        echo "Deleting backup: $file_name created on $created_at"
        curl -X DELETE "$MEALIE_URL/api/admin/backups/$file_name" -H "Authorization: Bearer $MEALIE_API_KEY"
    else
        echo "Backup $file_name is not older than 7 days."
    fi
done

echo "Backup maintenance completed."

# Calculate execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Notify uptime kuma of successful completion with execution time
curl -m 10 --retry 5 "${UPTIME_URL}?status=up&msg=Backup+Successful&ping=${execution_time}"