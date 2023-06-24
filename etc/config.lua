-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

rockspec = 'wax-latest-1.rockspec'


modules = {
  ['wax'] = {
    init  = 'wax/init.lua',
    lazy  = 'wax/lazy.lua',
  },

  ['wax.args'] = {
    init  = 'args/init.lua',
  },

  ['wax.html'] = {
    init  = 'html/init.lua',
  },

  ['wax.template'] = {
    init  = 'template/init.lua'
  },

  ['wax.csv'] = {
    init  = 'csv/init.lua',
    initc = 'csv/init.c',
  },

  ['wax.fs']  = {
    init  = 'fs/init.lua',
    initc = 'fs/init.c',
  },

  ['wax.json'] = {
    init = 'json/init.lua',
    initc = { 'json/_cjson/cJSON.c', 'json/init.c' },
  },

  ['wax.os'] = {
    init  = 'os/init.lua',
    initc = 'os/init.c',
  },

  ['wax.sql'] = {
    init = 'sql/init.lua',
    initc = {'sql/init.c', lflags='-lsqlite3'}
  },

  ['wax.user'] = {
    init  = 'user/init.lua',
    initc = 'user/init.c'
  }
}


cbin = { --[[{'target', 'code.c' }]] }

bin = { }
