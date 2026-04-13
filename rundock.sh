#!/bin/bash

# Usage: ./run-in-docker.sh path/to/script.sh [container_name]
# Defaults to container_name="testubuntu" if not provided

SCRIPT_PATH="$1"
CONTAINER_NAME="${2:-testubuntu}"  # default to testubuntu

# Get script filename
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# Validate input
if [[ -z "$SCRIPT_PATH" ]]; then
  echo "❌ Usage: $0 path/to/script.sh [container_name]"
  exit 1
fi

# Check if file exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "❌ File not found: $SCRIPT_PATH"
  exit 1
fi

# Copy script into container
echo "📁 Copying $SCRIPT_NAME to container $CONTAINER_NAME..."
docker cp "$SCRIPT_PATH" "$CONTAINER_NAME":/tmp/"$SCRIPT_NAME"

# Make it executable
echo "🔧 Setting execute permissions..."
docker exec "$CONTAINER_NAME" chmod +x /tmp/"$SCRIPT_NAME"

# Run the script
echo "🚀 Running the script inside the container..."
docker exec "$CONTAINER_NAME" /tmp/"$SCRIPT_NAME"

