lua { '5.1', '5.2', '5.3', '5.4' }

module 'wax.init' {
  src = 'src/wax/init.lua'
}

module 'wax.lazy' {
  src = 'src/wax/lazy.lua'
}

module 'wax.hashset' {
  src = 'src/wax/hashset.lua'
}

module 'wax.show' {
  src = 'src/wax/show.lua'
}

module 'wax.arg.init' {
  src = 'src/wax/arg.lua'
}

module 'wax.html.init' {
  src = 'src/html/init.lua'
}

module 'wax.template.init' {
  src = 'src/template/init.lua'
}

module 'wax.csv.init' {
  src = 'src/csv/init.lua'
}

module 'wax.csv.initc' {
  src = 'src/csv/init.c'
}

module 'wax.fs.init' {
  src = 'src/fs/init.lua'
}

module 'wax.fs.initc' {
  src = 'src/fs/init.c'
}

module 'wax.json.init' {
  src = 'src/json/init.lua'
}

module 'wax.json.initc' {
  src = { 'src/json/_cjson/cJSON.c', 'src/json/init.c' },
}

module 'wax.os.init' {
  src = 'src/os/init.lua'
}

module 'wax.os.initc' {
  src = 'src/os/init.c'
}

module 'wax.sql.init' {
  src = 'src/sql/init.lua'
}

module 'wax.sql.initc' {
  src = 'src/sql/init.c',
  clink = '-lsqlite3' -- lflags
}

module 'wax.user.init' {
  src = 'src/user/init.lua'
}

module 'wax.user.initc' {
  src = 'src/user/init.c'
}

--luarocks 'wax-latest-1.rockspec'

--[[
bin 'waxdev'
  :src 'src/bin/waxdev.lua'

bin 'waxdevc'
  :src {
    'src/bin/waxdevlib.c'
    'src/bin/waxdevc.c'
  }
--]]
