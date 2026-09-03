# jsonl-dedupe (Lua)

A tiny, dependency-free Lua utility to deduplicate newline-delimited JSON (JSONL) by a given top-level key (default `id`).

Features
- Very small (single-file) and portable — runs with stock Lua.
- Dedupe by string or numeric top-level fields (simple pattern matching).
- Streams input/output; works with files or stdin/stdout.

Usage
- From a file:
  lua ndedupe.lua data.jsonl id > unique.jsonl

- From stdin:
  cat data.jsonl | lua ndedupe.lua - id > unique.jsonl

Defaults
- If input path omitted, reads stdin.
- If key omitted, uses `id`.

Notes and limitations
- This tool uses light-weight pattern matching (not a full JSON parser), so it works best with well-formed JSONL where the dedupe key is a top-level (non-escaped) field like:
  {"id":"abc","name":"x"}
- For complex JSON structures or keys with embedded quotes/escapes, use a JSON-aware tool (jq, Python, etc.). This script is intended as a tiny, zero-dependency first-pass utility.

License
- MIT
