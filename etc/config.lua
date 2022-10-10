rockspec = 'wax-latest-1.rockspec'


bin = { }

-- clib paths have are relative to `./src/`
-- ./src/ext - External dependencies (from other projects)
-- ./src/lib - The C code containing the Lua C Api logic
-- ./src/macros
clib = {
    { "wax.os", {
        "waxm.c",
        "os.c" } },

    { "wax.fs", {
        "waxm.c",
        "fs.c" } },

    { "wax.user", {
        "waxm.c",
        "user.c" } },

    { "wax.json", {
        "waxm.c",
        "ext/json/cJSON.c",
        "json.c" } },
}

cbin = {
  -- {'target', 'code.c' }
}



-- vim: ts=4 sts=4 sw=4
