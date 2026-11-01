#!/usr/bin/env python3
"""brain_ask3.py - v3 of brain_ask (new file per the alteration rule;
v1 and v2 untouched).

Ask the TalaRipper brain a question; the local model answers FROM the
record, STREAMING - her words print as she generates them. Run from the
folder holding brain_index.sqlite, with llama-server on 127.0.0.1:8080.
Standard library only.

    python3 brain_ask3.py "What is disenchantment?"

Why v3 exists, measured 2026-11-01: on the 4-core Codespace class she
generates at ~0.03 tokens/s, so v2's wait-for-the-whole-answer request
hit its own 3600 s timeout with nothing to show. v3 streams: the first
words arrive as soon as she produces them, and whatever she manages to
say is printed live and labeled - never a silent blank, never a silent
timeout. The answer budget is 384 tokens; /no_think is kept from v2.
"""

import json
import sqlite3
import sys
import urllib.request

DB = "brain_index.sqlite"
URL = "http://127.0.0.1:8080/v1/chat/completions"
MODEL = "Qwen3.8-27B-Q3_K_M.gguf"

TOP_K = 4            # passages handed to the model
CHUNK_TRIM = 1000    # characters kept per passage (keeps the 4096 context safe)
MAX_TOKENS = 384     # her answer budget

STOP = {
    "what", "is", "the", "a", "an", "of", "to", "in", "on", "and", "or",
    "who", "how", "why", "does", "do", "are", "was", "were", "it", "its",
    "this", "that", "with", "from", "about", "tell", "me",
}


def search(cur, question):
    words = [w.strip("?.,!;:\"'()").lower() for w in question.split()]
    keys = [w for w in words if w and w not in STOP and len(w) > 2] or words
    scored = {}
    for kw in keys:
        for rid, content in cur.execute(
            "SELECT id, content FROM brain WHERE content LIKE ?", ("%" + kw + "%",)
        ):
            entry = scored.setdefault(rid, [0, content])
            entry[0] += 1
    ranked = sorted(scored.values(), key=lambda v: -v[0])[:TOP_K]
    return [(content or "")[:CHUNK_TRIM] for _, content in ranked]


def ask_stream(question, chunks):
    context = "\n\n---\n\n".join(chunks)
    system = (
        "You are the voice of a personal knowledge brain built by James Cochrum "
        "(the TALA-CORE record). Answer the question using ONLY the brain passages "
        "provided below. If the passages do not hold the answer, say so plainly. "
        "Speak plainly and briefly. Do not invent facts that are not in the passages."
    )
    user = "Brain passages:\n\n" + context + "\n\nQuestion: " + question + "\n\n/no_think"
    body = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "max_tokens": MAX_TOKENS,
        "temperature": 0.3,
        "stream": True,
    }
    req = urllib.request.Request(
        URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    content_parts = []
    reasoning_parts = []
    finish = "?"
    with urllib.request.urlopen(req, timeout=7200) as resp:
        for raw in resp:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            payload = line[5:].strip()
            if payload == "[DONE]":
                break
            try:
                data = json.loads(payload)
            except json.JSONDecodeError:
                continue
            choice = (data.get("choices") or [{}])[0]
            delta = choice.get("delta") or {}
            piece = delta.get("content") or ""
            if piece:
                content_parts.append(piece)
                sys.stdout.write(piece)
                sys.stdout.flush()
            rpiece = delta.get("reasoning_content") or ""
            if rpiece:
                reasoning_parts.append(rpiece)
            if choice.get("finish_reason"):
                finish = choice["finish_reason"]
    sys.stdout.write("\n")
    sys.stdout.flush()
    return (
        "".join(content_parts).strip(),
        "".join(reasoning_parts).strip(),
        finish,
    )


def main():
    question = " ".join(sys.argv[1:]).strip()
    if not question:
        question = input("Ask the brain: ").strip()
    if not question:
        return
    con = sqlite3.connect(DB)
    chunks = search(con.cursor(), question)
    con.close()
    print("[%d passages pulled from the brain]" % len(chunks))
    if not chunks:
        print("The brain holds nothing on that - no passages matched.")
        return
    print("Asking her - she streams: her words print as she makes them.")
    print("On a small borrowed machine she is slow. The stream is the proof")
    print("she is alive in there; let her finish.")
    print()
    content, reasoning, finish = ask_stream(question, chunks)
    if content:
        print()
        print("[finish_reason: %s]" % finish)
    elif reasoning:
        print("[She streamed thinking but no final answer - finish_reason: %s]" % finish)
        print(reasoning)
    else:
        print("[She returned nothing at all - finish_reason: %s. "
              "That is a report, not a blank: the wire answered, the seat was empty.]" % finish)


if __name__ == "__main__":
    main()
