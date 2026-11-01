#!/usr/bin/env bash
# Start her engine server if it is not already answering, and wait until
# the model is loaded. Safe to re-run: if she is already up, it says so
# and exits. Runs automatically when a Codespace starts (postStart), and
# setup.sh calls it for the first breath.
set -e
cd "$(dirname "$0")"
HEALTH=http://127.0.0.1:8080/health
if curl -s --max-time 3 "$HEALTH" | grep -q '"ok"'; then
  echo "She is already up (http://127.0.0.1:8080)."
  exit 0
fi
if [ ! -x llama.cpp/build/bin/llama-server ]; then
  echo "The engine is not built yet - run: bash setup.sh"
  exit 1
fi
if [ ! -f models/Qwen3.8-27B-Q3_K_M.gguf ]; then
  echo "The model is not here yet - run: bash setup.sh"
  exit 1
fi
echo "Starting her engine (a 27B model takes a few minutes to load)..."
nohup llama.cpp/build/bin/llama-server \
  -m models/Qwen3.8-27B-Q3_K_M.gguf \
  -c 4096 -ctk q4_0 -ctv q4_0 --port 8080 \
  > server.log 2>&1 &
for i in $(seq 1 120); do
  if curl -s --max-time 3 "$HEALTH" | grep -q '"ok"'; then
    echo "She is up: http://127.0.0.1:8080"
    echo 'Ask her:  python3 brain_ask2.py "What is disenchantment?"'
    echo 'Streaming ask (answer arrives word by word - better on this machine class):  python3 brain_ask3.py "What is disenchantment?"'
    exit 0
  fi
  sleep 5
done
echo "She did not answer on the health port within 10 minutes - see server.log."
exit 1
