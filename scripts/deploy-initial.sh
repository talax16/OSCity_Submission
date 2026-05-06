#!/usr/bin/env bash
# deploy-initial.sh
# Collects any existing study data, wipes all 4 participant servers, uploads fresh files, and starts them.

set -euo pipefail

SERVER="root@89.167.39.43"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"
SAVE_DIR="$HOME/Documents/Year3/Project/StudyData"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Collect any existing study data before wiping
echo "Saving existing study data..."
for i in 1 2 3 4; do
  REMOTE_FILE="~/servers/p$i/plugins/OSCity/study_data.db"
  LOCAL_FILE="$SAVE_DIR/study_data_p${i}_${TIMESTAMP}.db"
  if ssh "$SERVER" "[ -f $REMOTE_FILE ]" 2>/dev/null; then
    scp "$SERVER:$REMOTE_FILE" "$LOCAL_FILE"
    echo "  p$i -> $LOCAL_FILE"
  fi
done

# Stop any running server instances
echo "Stopping any running servers..."
ssh "$SERVER" bash <<'ENDSSH'
for i in 1 2 3 4; do
  if screen -list | grep -q "p$i"; then
    screen -S "p$i" -X stuff "stop$(printf '\r')"
    echo "  Stopping p$i..."
  fi
done
sleep 8
ENDSSH

# Upload fresh server files to p1 
echo "Uploading server files to p1..."
rsync -av --progress \
  --exclude='.DS_Store' \
  --exclude='OSCity/' \
  --exclude='logs/' \
  --exclude='cache/' \
  --exclude='libraries/' \
  --exclude='versions/' \
  --exclude='TestCode/' \
  --exclude='worldFlatTest/' \
  --exclude='study_data.db' \
  --exclude='map-color-cache.dat' \
  --exclude='usercache.json' \
  --exclude='OSCityWorld_nether/' \
  --exclude='OSCityWorld_the_end/' \
  --exclude='plugins/Citizens/lib/' \
  --exclude='plugins/WorldEdit/sessions/' \
  --exclude='plugins/WorldEdit/.archive-unpack/' \
  --exclude='deploy-initial.sh' \
  --exclude='deploy-jar.sh' \
  --exclude='deploy-config.sh' \
  --exclude='collect-data.sh' \
  --exclude='start-servers.sh' \
  "$LOCAL_DIR/" "$SERVER:~/servers/p1/"

# Clone p1 to p2/p3/p4 on the server
echo "Cloning p1 to p2, p3, p4..."
ssh "$SERVER" bash <<'ENDSSH'
set -euo pipefail
for i in 2 3 4; do
  echo "  p1 -> p$i"
  rm -rf ~/servers/p$i
  cp -r ~/servers/p1 ~/servers/p$i
done
ENDSSH

# Patch server.properties per instance 
echo "Patching server.properties..."
ssh "$SERVER" bash <<'ENDSSH'
set -euo pipefail
declare -A PORTS=([1]=25565 [2]=25566 [3]=25567 [4]=25568)
for i in 1 2 3 4; do
  FILE=~/servers/p$i/server.properties
  PORT=${PORTS[$i]}
  sed -i "s/^server-port=.*/server-port=$PORT/" "$FILE"
  sed -i "s/^online-mode=.*/online-mode=false/" "$FILE"
  sed -i "s/^max-players=.*/max-players=1/" "$FILE"
  sed -i "s/^enforce-secure-profile=.*/enforce-secure-profile=false/" "$FILE"
  echo "  p$i -> port $PORT"
done
ENDSSH

# Start all 4 servers
echo "Starting the four study servers..."
ssh "$SERVER" bash <<'ENDSSH'
set -euo pipefail
JAR=$(ls ~/servers/p1/paper-*.jar | head -1 | xargs basename)
for i in 1 2 3 4; do
  screen -dmS "p$i" bash -c "cd ~/servers/p$i && java -Xms1G -Xmx3G -jar $JAR --nogui"
  echo "  Started p$i"
done
ENDSSH

echo ""
echo "All done. 4 fresh servers are starting up."
echo "Ports: p1=25565  p2=25566  p3=25567  p4=25568"
echo "Check status: ssh root@89.167.39.43 then: screen -ls"
