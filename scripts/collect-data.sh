#!/usr/bin/env bash
# collect-data.sh
# Downloads study_data.db from all 4 participant servers to ~/StudyData/

set -euo pipefail

SERVER="root@89.167.39.43"
SAVE_DIR="$HOME/Documents/Year3/Project/StudyData"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Collecting study data (session: $TIMESTAMP)..."
for i in 1 2 3 4; do
  REMOTE_FILE="~/servers/p$i/plugins/OSCity/study_data.db"
  LOCAL_FILE="$SAVE_DIR/study_data_p${i}_${TIMESTAMP}.db"

  # Check if the file exists on the server before trying to download
  if ssh "$SERVER" "[ -f $REMOTE_FILE ]"; then
    scp "$SERVER:$REMOTE_FILE" "$LOCAL_FILE"
    echo "  p$i -> $LOCAL_FILE"
  else
    echo "  p$i -> no study_data.db found (skipping)"
  fi
done

echo ""
echo "Done. Files saved to $SAVE_DIR"
