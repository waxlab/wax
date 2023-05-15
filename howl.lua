-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors


-- docname specifies an unique identifier for documentation
name = "wax"

formats = {"vimhelp", "wiki"}

-- The following list has pairs `doc name` and `file name`.
-- Reorder and nest its elements adequating to your documentation
-- structure needs.
tree = {
  { "_contributing", "contributing.md" },
  { "doc_w8l", "doc/w8l.md" },
  { "run_main", "etc/run/main.lua" },
  { "run_sh", "etc/run/sh.lua" },
  { "_readme", "readme.md" },
  { "wArr_", "src/wax/arr.h" },
  { "c8l_l8n", "src/wax/lua.h" },
  { "json_README", "src/ext/json/README.md" },
  { "wax_args", "test/wax/args.lua" },
  { "wax_compat", "test/wax/compat.lua" },
  { "wax_csv", "test/wax/csv.lua" },
  { "wax_fs", "test/wax/fs.lua" },
  { "wax_html", "test/wax/html.lua" },
  { "wax_json", "test/wax/json.lua" },
  { "wax_os", "test/wax/os.lua" },
  { "wax_sql", "test/wax/sql.lua" },
  { "wax_table", "test/wax/table.lua" },
  { "wax_template", "test/wax/template.lua" },
  { "wax_user", "test/wax/user.lua" },
  { "wax_was", "test/wax/was.lua" },
  { "test_wax", "test/wax.lua" },
  { "doc_w8l", "tree/lib/luarocks/rocks-5.1/wax/latest-1/doc/w8l.md" },
  { "doc_w8l", "tree/lib/luarocks/rocks-5.2/wax/latest-1/doc/w8l.md" },
  { "doc_w8l", "tree/lib/luarocks/rocks-5.3/wax/latest-1/doc/w8l.md" },
  { "doc_w8l", "tree/lib/luarocks/rocks-5.4/wax/latest-1/doc/w8l.md" },
}

-- You can alternatively specify a tree with subdocs:
-- tree = {
--   { "intro", "doc/intro.md", {
--     { "usage", "doc/usage.md" },
--     { "about", "doc/about.md" },
--   },
--   { "recipes", "doc/recipes.md", {
--     { "funcs", "test/funcs.lua" },
--     { "math",  "test/math.lua" },
--   }
-- }
