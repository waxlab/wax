rockspec = 'wax-latest-1.rockspec'


bin = { }

-- clib paths have are relative to `./src/`
-- ./src/ext - External dependencies (from other projects)
-- ./src/lib - The C code containing the Lua C Api logic
-- ./src/macros
clib = {
    { "wax.os", {
        "macros.c",
        "lib/os.c" } },

    { "wax.path", {
        "macros.c",
        "lib/path.c" } },

    { "wax.user", {
        "macros.c",
        "lib/user.c" } },

    { "wax.json", {
        "macros.c",
        "ext/json/cJSON.c",
        "lib/json.c" } },
}

cbin = {
  -- {'target', 'code.c' }
}



-- vim: ts=4 sts=4 sw=4
