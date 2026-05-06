#!/usr/bin/env bash
# deploy-jar.sh
# Builds the OSCity plugin, stops all 4 servers, uploads the new JAR, and restarts them.

set -euo pipefail

SERVER="root@89.167.39.43"
JAR_PATH="$(cd "$(dirname "$0")" && pwd)/OSCity/build/libs/OSCity-1.0-SNAPSHOT.jar"

# Build
echo "==> Building OSCity..."
(cd "$(dirname "$0")/OSCity" && ./gradlew build -q)
echo "  Build successful."

# Stop servers
echo "==> Stopping servers..."
ssh "$SERVER" bash <<'ENDSSH'
for i in 1 2 3 4; do
  if screen -list | grep -q "p$i"; then
    screen -S "p$i" -X stuff "stop$(printf '\r')"
    echo "  Stopping p$i..."
  fi
done
sleep 8
ENDSSH

# Upload new JAR to all 4 servers
echo "==> Uploading new JAR..."
for i in 1 2 3 4; do
  scp "$JAR_PATH" "$SERVER:~/servers/p$i/plugins/OSCity-1.0-SNAPSHOT.jar"
  echo "  Uploaded to p$i"
done

# Restart servers
echo "==> Restarting servers..."
ssh "$SERVER" bash <<'ENDSSH'
set -euo pipefail
JAR=$(ls ~/servers/p1/paper-*.jar | head -1 | xargs basename)
for i in 1 2 3 4; do
  screen -dmS "p$i" bash -c "cd ~/servers/p$i && java -Xms1G -Xmx3G -jar $JAR --nogui"
  echo "  Started p$i"
done
ENDSSH

echo ""
echo "Done. All 4 servers are restarting with the new JAR."
