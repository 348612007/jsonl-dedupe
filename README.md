# jsonl-dedupe (Lua)

A tiny Lua utility to deduplicate newline-delimited JSON (JSONL) by a given top-level key (default `id`).

This version uses lua-cjson for strict JSON parsing and is more robust than the lightweight pattern-matching original.

Features
- Strict JSON parsing via lua-cjson (faster and safer than regex).
- Dedupe by any top-level JSON value (string, number, boolean) — converted to string for comparison.
- Streams input/output; works with files or stdin/stdout.

Dependencies
- lua-cjson (module name: `cjson`). Install via LuaRocks:

  luarocks install lua-cjson

On some Linux distributions there may also be a system package (e.g. `lua-cjson`) — prefer LuaRocks for compatibility.

Usage
- From a file:
  lua ndedupe.lua data.jsonl id > unique.jsonl

- From stdin:
  cat data.jsonl | lua ndedupe.lua - id > unique.jsonl

Behavior
- If `lua-cjson` is not installed the script exits with an error and suggests the installation command.
- Lines that fail JSON parsing are emitted unchanged; the script will warn up to a few parse errors and then suppress further parse warnings.
- If the dedupe key is missing in a JSON object, the line is emitted and a periodic warning is printed to stderr.

Notes and limitations
- This script expects each input line to be a single JSON value (object/array/etc.). It is intended for JSONL where each line is a top-level JSON object.
- The dedupe key must be a top-level field. Nested keys are not supported by this simple tool.
- For very large datasets consider using streaming tools and ensure sufficient memory — this script keeps seen keys in memory.

License
- MIT
