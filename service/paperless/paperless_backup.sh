#!/bin/bash

# Start timing
start_time=$(date +%s)

COMPOSE_DIR="/opt/stacks/paperless"
UPTIME_URL="https://uptime.example.com/api/push/YOURCODE"

# Change to the compose directory
cd "$COMPOSE_DIR" || {
    echo "Error: Could not change to compose directory"
    curl -m 10 --retry 5 "${UPTIME_URL}?status=down&msg=Directory+Change+Failed"
    exit 1
}

# Run the document exporter with all specified parameters
if docker compose exec -T paperless document_exporter /usr/src/paperless/export -c -nt -p -z -f -d; then
    echo "Backup completed successfully to mounted export directory"
    # Calculate execution time and notify uptime kuma
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    curl -m 10 --retry 5 "${UPTIME_URL}?status=up&msg=Backup+Successful&ping=${execution_time}"
else
    echo "Error: Document export failed"
    curl -m 10 --retry 5 "${UPTIME_URL}?status=down&msg=Export+Failed"
    exit 1
fi
