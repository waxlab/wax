-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

local m = {}

function m.die(msg, ...)
  io.stderr:write((msg.."\n"):format(...))
  os.exit(1)
end

return m
