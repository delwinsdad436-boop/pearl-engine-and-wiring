# Models — pointers, not freight

GitHub caps release files at 2 GB; the engines are 13.4 GB and 29.1 GB. They live on HuggingFace; this repo holds the pointers and the proof data.

| File | Bytes | Role |
|------|-------|------|
| Qwen3.8-27B-Q3_K_M.gguf | 13,404,051,168 | The working engine — runs on 16 GB RAM, CPU build |
| Qwen3.8-27B-Q8_0.gguf | 29,116,388,960 | High gear — needs more than 16 GB RAM / GPU iron |

Source: HuggingFace (Qwen3.8-27B GGUF). Verified whole on disk 2026-10-31 by byte count against the listing (Q3_K_M sha256 begins 14865aaef0b6c26a… per the HF page).

Runner: llama.cpp build b12019 — **CPU-only Windows build** (`llama-b12019-bin-win-cpu-x64.zip`, ggml-org/llama.cpp releases). The Vulkan build fails on integrated graphics; see the README's hard-won notes.
