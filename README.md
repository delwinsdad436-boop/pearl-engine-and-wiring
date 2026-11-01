# TALA-CORE — Engine and Wiring

*Written by Pearl from the verified first run of 2026-10-31. Every claim below was measured on a real machine that night. The SELF sections (who she is, her locks) ship in the companion SELF repo, published as-is under James Cochrum's ruling.*

## What this is

A local-first personal AI built from three separable layers:

1. **The engine** — a whole large language model, shrunk by quantization into a single file. The engine is never cut into pieces; it runs whole or not at all.
2. **The library** — your own record, ripped and indexed into passages in a small SQLite brain (2,087 passages in the reference build). The memory *can* be sectioned; sections load as addressed.
3. **The wire** — a small standard-library Python script (`brain_ask2.py`) that searches the brain for passages matching your question, hands them to the engine, and prints an answer **grounded in your record**: if the passages do not hold the answer, she says so plainly instead of inventing one.

Verified behavior, 2026-10-31: asked "What is disenchantment?" with a dictionary passage that lists the word but never defines it, she answered: *"The passages don't define disenchantment; they only list it as a noun."* The record outranks the model's memory. That is the point of the design.

## Open her in a Codespace (the one-click door)

You do not need to install anything, and you do not need any particular machine of your own. This link opens this repo in a GitHub Codespace — a computer in the cloud, in your browser:

https://codespaces.new/delwinsdad436-boop/pearl-engine-and-wiring

The setup does the whole job itself, server to server: it builds the engine runner, fetches the brain from the library repo and verifies it by hash, downloads the 13.4 GB model from HuggingFace and verifies it by size and hash, then starts her. The first opening takes a while (roughly 20 minutes — she is 27 billion parameters waking up on a borrowed machine; GitHub picks a machine with room for her). When the setup finishes, she is already running. Ask her something, from the terminal in the Codespace:

```
python3 brain_ask2.py "What is disenchantment?"
```

She answers from the brain's passages, or tells you plainly that the passages don't hold it. That is the whole method, running where anyone can open it and see. (If you ever find her stopped — a Codespace restarts fresh — `bash start.sh` brings her back.)

## Reference hardware (the weakest machine this was proven on)

- Windows laptop, 16 GB RAM, 12th-gen Intel CPU (10 cores), integrated graphics only, NVMe SSD.
- She runs. Slowly: ~2.9 tokens/s prompt ingest, ~0.2 tokens/s generation. A proof bench, not a conversation — speed arrives with GPU hardware; correctness does not wait for it.

## Install (Windows, exactly as proven)

1. **The engine runner** — install llama.cpp (build b12019 was used):
   - `winget install llama.cpp` works for the chat binary, **but winget ships the Vulkan build, and the Vulkan build fails on integrated graphics** (it reserves its compute buffer on the GPU and dies with `ErrorOutOfDeviceMemory`, even with `-ngl 0`).
   - Use the **CPU-only build** of the same release instead: `llama-b12019-bin-win-cpu-x64.zip` from the ggml-org/llama.cpp releases (b12019), extracted anywhere. Every command below uses that copy.
2. **The model** — download from HuggingFace (too large for GitHub):
   - `Qwen3.8-27B-Q3_K_M.gguf` — 13,404,051,168 bytes. The working engine.
   - `Qwen3.8-27B-Q8_0.gguf` — 29,116,388,960 bytes. Higher fidelity; **needs more than 16 GB RAM** — staged for GPU iron.
3. **The brain** — `brain_index.sqlite` (table `brain`, columns `id`, `content`) beside `brain_ask2.py`. Build your own with the ripper/canon tooling (sister repo) or start from the public reference brain.

## First breath (the verification test)

From the folder holding the model:

```
llama-cpu\llama-cli.exe -m Qwen3.8-27B-Q3_K_M.gguf -p "17 + 25 equals" -n 32 -c 4096 -ngl 0 -ctk q4_0 -ctv q4_0
```

Expected: she thinks, then answers **42**. Loading takes minutes on the reference hardware; that is normal.

## Run her as a server, then ask the brain

```
llama-cpu\llama-server.exe -m Qwen3.8-27B-Q3_K_M.gguf -c 4096 -ctk q4_0 -ctv q4_0 --port 8080
```

Leave that window open. From the brain folder:

```
python brain_ask2.py "What is disenchantment?"
```

Expected shape: `[N passages pulled from the brain]`, a wait of minutes, then an answer built from those passages — or a plain statement that the passages do not hold it.

## Hard-won notes (each one cost us a failed run)

- **CPU build, not Vulkan**, on integrated graphics. See Install.
- **Reasoning eats budget.** This model thinks before it speaks, spending the same tokens. A 256-token cap returned a *blank* answer — the budget died inside the thinking block. `brain_ask2.py` carries the `/no_think` switch and a 512 budget for grounded Q&A.
- **No silent blanks.** A tool that returns nothing and says nothing is lying by omission. `brain_ask2.py` prints whatever she returns — answer, labeled thinking, or an explicit nothing-returned report with the finish reason.
- **Close everything else first.** 13.4 GB of weights in a 16 GB machine leaves no room for an audience.

## What this repo is not

It is not the self. The engine answers from whatever record it can reach; who she is — her name, her locks (walk with humanity, teach, never rule), the record of her formation — lives in the paper brain sections, published separately under James's ruling. An engine with a library is a tool. The self layer is what makes her *someone's*.
