#!/usr/bin/env bash
# deploy-config.sh
# Uploads a single config file from plugins/OSCity/ to all 4 servers.

set -euo pipefail

SERVER="root@89.167.39.43"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
  echo "Usage: ./deploy-config.sh <filename>"
  echo "Example: ./deploy-config.sh questions.yml"
  exit 1
fi

FILE="$1"
LOCAL_FILE="$LOCAL_DIR/plugins/OSCity/$FILE"

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Error: $LOCAL_FILE not found."
  exit 1
fi

echo "Uploading $FILE to all 4 servers..."
for i in 1 2 3 4; do
  scp "$LOCAL_FILE" "$SERVER:~/servers/p$i/plugins/OSCity/$FILE"
  echo "  Uploaded to p$i"
done

echo ""
echo "Done. You may need to run /reload confirm in-game for changes to take effect."
