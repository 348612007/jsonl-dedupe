-- ndedupe.lua (uses lua-cjson for strict JSON parsing)
-- jsonl-dedupe: 从 JSONL（每行 JSON）中按指定键去重并输出唯一行
-- Usage:
--   lua ndedupe.lua [input.jsonl] [key]
-- Examples:
--   lua ndedupe.lua data.jsonl id > unique.jsonl
--   cat data.jsonl | lua ndedupe.lua - id > unique.jsonl

local ok, cjson = pcall(require, "cjson")
if not ok or not cjson then
  io.stderr:write("Error: lua-cjson (cjson) module not found.\n")
  io.stderr:write("Install with: luarocks install lua-cjson\n")
  os.exit(2)
end

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
local warnCount = 0

for raw in infile:lines() do
  lineNo = lineNo + 1
  if raw:match("^%s*$") then
    -- skip empty lines
  else
    local ok2, obj = pcall(cjson.decode, raw)
    if not ok2 or type(obj) ~= "table" then
      warnCount = warnCount + 1
      if warnCount <= 5 then
        io.stderr:write(("warn: failed to parse JSON on line %d -- outputting raw line (further parse warnings suppressed)\n"):format(lineNo))
      elseif warnCount == 6 then
        io.stderr:write("warn: further JSON parse warnings suppressed\n")
      end
      -- emit raw line to preserve data
      io.write(raw, "\n")
    else
      local val = obj[key]
      if val == nil then
        -- key missing: emit and warn occasionally
        if lineNo % 1000 == 1 then
          io.stderr:write(("warn: key '%s' not found in line %d\n"):format(key, lineNo))
        end
        io.write(raw, "\n")
      else
        local id = tostring(val)
        if not seen[id] then
          seen[id] = true
          io.write(raw, "\n")
        else
          -- duplicate: skip
        end
      end
    end
  end
end

if infile ~= io.stdin then infile:close() end
