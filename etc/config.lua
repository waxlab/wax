rockspec = 'wax-latest-1.rockspec'


bin = { }

-- clib paths have are relative to `./src/`
-- ./src/ext - External dependencies (from other projects)
-- ./src/lib - The C code containing the Lua C Api logic
-- ./src/macros
clib = {
    { "wax.csv",  { "csv.c"  } },
    { "wax.fs",   { "fs.c" } },
    { "wax.json", { "ext/json/cJSON.c", "json.c" } },
    { "wax.os",   { "os.c" } },
    { "wax.user", { "user.c" } },
}
cbin = {
  -- {'target', 'code.c' }
}



-- vim: ts=4 sts=4 sw=4
