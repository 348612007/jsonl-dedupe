-- jsonl-dedupe: 从 JSONL（每行 JSON）中按指定键去重并输出唯一行
-- Usage:
--   lua ndedupe.lua [input.jsonl] [key]
-- Examples:
--   lua ndedupe.lua data.jsonl id > unique.jsonl
--   cat data.jsonl | lua ndedupe.lua - id > unique.jsonl

local inputPath = arg[1] or "-"
local key = arg[2] or "id"

local infile
if inputPath == "-" then
  infile = io.stdin
else
  local f, err = io.open(inputPath, "r")
  if not f then
    io.stderr:write(("Error opening %s: %s\n"):format(inputPath, err))
    os.exit(2)
  end
  infile = f
end

local seen = {}
local lineNo = 0

-- Try to extract key value (string or number) via simple patterns.
-- This intentionally uses lightweight pattern matching (not a full JSON parser)
-- so it works well for common JSONL where the key is a top-level field.
local function extract_key_value(line, key)
  -- match "key": "value"
  local pattern_str = '"' .. key .. '%"%s*:%s*%"([^%"]+)%"'
  local s = line:match(pattern_str)
  if s then return s end
  -- match "key": number (integer/float)
  local pattern_num = '"' .. key .. '%"%s*:%s*([%d%.%-eE]+)'
  local n = line:match(pattern_num)
  if n then return n end
  return nil
end

for raw in infile:lines() do
  lineNo = lineNo + 1
  local id = extract_key_value(raw, key)
  if id then
    if not seen[id] then
      seen[id] = true
      io.write(raw, "\n")
    else
      -- duplicate: skip
    end
  else
    -- If the key isn't found, emit the line but warn once per 1000 lines to stderr.
    if lineNo % 1000 == 1 then
      io.stderr:write(("warn: key '%s' not found in line %d (showing every 1000 warnings)\n"):format(key, lineNo))
    end
    io.write(raw, "\n")
  end
end

if infile ~= io.stdin then infile:close() end
