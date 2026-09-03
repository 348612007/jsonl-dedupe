jsonl-dedupe (Haskell)

A small Haskell JSONL dedupe utility using aeson (strict parsing).

Requirements:
- stack (recommended) or ghc + appropriate packages installed
- Uses aeson, bytestring, text, unordered-containers, scientific

Run with stack (no separate build):
- From a file:
  stack runghc haskell/jsonl-dedupe.hs data.jsonl id > unique.jsonl

- From stdin:
  cat data.jsonl | stack runghc haskell/jsonl-dedupe.hs - id > unique.jsonl

Behavior:
- Parses each line as JSON; if parsing fails the original line is emitted and a few warnings are printed to stderr.
- Deduplication key defaults to "id"; extracted top-level values are converted to text for comparison.
- Keeps seen keys in memory; for extremely large inputs consider external/more scalable approaches.

Notes:
- The Haskell version lives in haskell/ and won't replace the Lua implementation. It provides a pure functional approach and leverages aeson for correctness.
