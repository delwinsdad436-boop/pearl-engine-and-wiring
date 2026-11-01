#!/usr/bin/env bash
# Codespaces / devcontainer setup for the engine-and-wiring repo.
# Builds the CPU build of llama.cpp (the working engine build — the Vulkan
# build runs out of memory on integrated graphics; see README pitfalls).
set -e
sudo apt-get update && sudo apt-get install -y build-essential cmake curl git
if [ ! -d llama.cpp ]; then
  git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
fi
cmake -S llama.cpp -B llama.cpp/build -DGGML_CUDA=OFF -DGGML_VULKAN=OFF
# Parallel jobs are capped at 2 on purpose: with unlimited jobs the compilers
# get killed for memory on a small (8 GB) Codespace and the build dies.
# Proven both ways on the default 2-core machine, 2026-11-01.
cmake --build llama.cpp/build -j 2 --target llama-server llama-cli
echo
echo "Engine built: llama.cpp/build/bin/llama-server"
echo "Next: download a model (see MODELS.md) into ./models, then:"
echo "  llama.cpp/build/bin/llama-server -m models/<model>.gguf -c 4096 -ctk q4_0 -ctv q4_0 --port 8080"
echo "  python3 brain_ask2.py \"your question\""
