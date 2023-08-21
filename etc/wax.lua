luaver { '5.1', '5.2', '5.3', '5.4' }

module 'wax.init'      { src = 'src/wax/init.lua'     }
module 'wax.lazy'      { src = 'src/wax/lazy.lua'     }
module 'wax.args'      { src = 'src/wax/args.lua'     }
module 'wax.ordassoc'  { src = 'src/wax/ordassoc.lua' }
module 'wax.show'      { src = 'src/wax/show.lua'     }
module 'wax.xconf'     { src = 'src/wax/xconf.lua'    }
module 'wax.html'      { src = 'src/wax/html.lua'     }
module 'wax.csv'       { src = 'src/wax/csv.c'        }
module 'wax.fs'        { src = 'src/wax/fs.c'         }
module 'wax.os'        { src = 'src/wax/os.c'         }

module 'wax.sql' {
  src = 'src/wax/sql.c',
  lib = 'sqlite3'
}

module 'wax.json' {
  src = {
    'src/wax/json/_cjson/cJSON.c',
    'src/wax/json/init.c'
  }
}


module 'wax.user' { src = 'src/wax/user/init.c' }

-- replace it
module 'wax.template'   { src = 'src/wax/template/init.lua' }

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