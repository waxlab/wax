luaver { '5.1', '5.2', '5.3', '5.4' }

module 'wax.init'      { src = 'src/wax/init.lua'     }
module 'wax.lazy'      { src = 'src/wax/lazy.lua'     }
module 'wax.attest'    { src = 'src/wax/attest.lua'   }
module 'wax.kind'      { src = 'src/wax/kind.lua'     }
module 'wax.args'      { src = 'src/wax/args.lua'     }
module 'wax.irecord'   { src = 'src/wax/irecord.lua'  }
module 'wax.show'      { src = 'src/wax/show.lua'     }
module 'wax.xconf'     { src = 'src/wax/xconf.lua'    }
module 'wax.html'      { src = 'src/wax/html.lua'     }
module 'wax.csv'       { src = 'src/wax/csv.c'        }
module 'wax.fs'        { src = 'src/wax/fs.c'         }
module 'wax.proc'      { src = 'src/wax/proc.c'       }
module 'wax.async'     { src = 'src/wax/async.c'      }

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


module 'wax.user' { src = 'src/wax/user.c' }

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
