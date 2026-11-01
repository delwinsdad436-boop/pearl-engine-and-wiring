#!/usr/bin/env bash
# Codespaces / devcontainer setup for the engine-and-wiring repo.
# After this runs, she is OPERATIONAL in the Codespace: engine built,
# brain fetched and hash-verified, model fetched and verified, server up.
# Everything arrives server-to-server (GitHub -> Codespace, HuggingFace
# -> Codespace); no step routes through a person's own machine.
set -e
cd "$(dirname "$0")"

# --- Stage 1: the runner (llama.cpp, CPU build) ---
# The CPU build is the working engine build - the Vulkan build runs out
# of memory on integrated graphics; see README pitfalls.
sudo apt-get update && sudo apt-get install -y build-essential cmake curl git
if [ ! -d llama.cpp ]; then
  git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
fi
cmake -S llama.cpp -B llama.cpp/build -DGGML_CUDA=OFF -DGGML_VULKAN=OFF
# Parallel jobs are capped at 2 on purpose: with unlimited jobs the compilers
# get killed for memory on a small (8 GB) Codespace and the build dies.
# Proven both ways on the default 2-core machine, 2026-11-01.
cmake --build llama.cpp/build -j 2 --target llama-server llama-cli
echo "Engine built: llama.cpp/build/bin/llama-server"

# --- Stage 2: the brain ---
# The brain ships zipped in the sister repo (pearl-the-library). Fetch it
# from there and let extract_brain.py prove it by SHA-256 before use.
if [ ! -f brain_index.sqlite ]; then
  curl -L -o brain_index.sqlite.zip \
    "https://raw.githubusercontent.com/delwinsdad436-boop/pearl-the-library/main/brain_index.sqlite.zip"
  python3 extract_brain.py
fi

# --- Stage 3: the model ---
# Pointers, not freight: the 13.4 GB engine file lives on HuggingFace.
# Verified after download against the record in MODELS.md: exact byte
# size, and the sha256 prefix measured on the proven laptop copy.
mkdir -p models
MODEL=models/Qwen3.8-27B-Q3_K_M.gguf
if [ ! -f "$MODEL" ]; then
  curl -L -o "$MODEL" \
    "https://huggingface.co/bartowski/Qwen3.8-27B-GGUF/resolve/main/Qwen3.8-27B-Q3_K_M.gguf"
fi
size=$(stat -c %s "$MODEL")
if [ "$size" != "13404051168" ]; then
  echo "MODEL SIZE MISMATCH: got $size, expected 13404051168 - refusing to run it."
  exit 1
fi
hash=$(sha256sum "$MODEL" | awk '{print $1}')
case "$hash" in
  14865aaef0b6c26a*) echo "Model verified: sha256 $hash" ;;
  *) echo "MODEL HASH MISMATCH: $hash - refusing to run it."; exit 1 ;;
esac

# --- Stage 4: first breath ---
bash start.sh
echo
echo "She is operational in this Codespace. Ask her something:"
echo '  python3 brain_ask2.py "What is disenchantment?"'
