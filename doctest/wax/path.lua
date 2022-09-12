--   Wax Project -- Axa Lua Development  --
--     Copyright 2022 Thadeu de Paula    --
--     https://github.com/axa-dev/wax    --
--       Licensed under MIT License      --

local path = require("wax.path")
local user = require("wax.user")
local lua = tonumber(_VERSION:gsub('%D',''), 10)

-- Prepares the environment for following tests
local testdir, testfile
do
  testdir = os.getenv("HOME").."/wax_path_testdir_root"
  os.execute( ("rm -rf %q"):format(testdir) )
  os.execute( ("mkdir %q"):format(testdir) )
  testfile = testdir.."/wax_path_testfile"
  local fh = io.open(testfile, "a")
  if fh ~= nil then
    fh:write("Lore ipsum\n")
    fh:close()
  end
end

--| # wax.path
--| This module contains filesystem related functions to list,
--| retrieve info of files as well as filename handling helpers
--|
--| **Compatibility**
--| All functions are tested in a Linux environment and should work
--| flawlessly under any modern Posix compliant system.
--| Windows is not presently not supported and most of functions
--| should return nil.
--|

--|
--| ## Constants
--|

do
--@ wax.path.dirsep : string
--{ Directory separator, that can change accordingly to the system.
--| * BSD, Linux etc.: `"/"` (slash)
--| * Windows:         `"\"` (backslash)

  assert( path.dirsep == "/" or path.dirsep == "\\" )
--}
end


--|
--| ## Path handling
--|

do
--@ wax.path.real( path: string ) : string | (nil, string)
--{ Resolves the realpath of the `path` and returns true.
--| When not possible, returns false and a descriptive string.
  assert( path.real("/usr/bin/")       == "/usr/bin")
  assert( path.real("/usr/bin/../lib") == "/usr/lib")

  local res, err = path.real("/a_/_b/c_/../_d")
  assert( res == nil and type(err) == "string" )
--}
end

do
--@ wax.path.dirname(path: string) : string
--{ Get the dir part of the path and return it.
  assert( path.dirname("/usr/lib") == "/usr" )
  assert( path.dirname("/usr/"   ) == "/"    )
  assert( path.dirname("usr"     ) == "."    )
  assert( path.dirname("/"       ) == "/"    )
  assert( path.dirname("."       ) == "."    )
  assert( path.dirname(".."      ) == "."    )
--}
end

do
--@ wax.path.basename(path: string) : string
--{ Get the dir part of the path and return it.
  assert( path.basename("/usr/lib") == "lib" )
  assert( path.basename("/usr/"   ) == "usr" )
  assert( path.basename("usr"     ) == "usr" )
  assert( path.basename("/"       ) == "/"   )
  assert( path.basename("."       ) == "."   )
  assert( path.basename(".."      ) ==  ".." )
--}
end

do
--@ wax.path.build(dir1 ... dirN: string) : string
--{ Receives a varible number of strings and builds a path from it
--|
  --| Basic Usage:

  -- 1. concatenate correctly the path elements
  assert( path.build("1nd","2nd","3rd") == "1nd/2nd/3rd" )

  -- 2. clear strange paths
  assert( path.build("a//b////c/./d/") == "a/b/c/d")

  --| Expected behaviors

  -- 1. Doesn't normalizes parent `..` entries
  assert( path.build("a/../a")          == "a/../a" )
  assert( path.build("..", "a"  ,"b"  ) == "../a/b" )

  -- 2. remove rightmost pending separator
  assert( path.build("a/b/c/") == "a/b/c" )

  -- 3. remove duplicated separators
  assert( path.build("a//","/b/","/c/") == "a/b/c"    )
  assert( path.build("//a","b/c"      ) == "/a/b/c"   )

  -- 4. remove relative here dot `.` that is not the first char
  assert( path.build(".", "a", "b"     ) == "./a/b"    )
  assert( path.build(".", "a", ".", "b") == "./a/b"    )
  assert( path.build("./a"," b/", "./c") == "./a/ b/c" )
  assert( path.build("a", "..", "b"    ) == "a/../b"   )
  assert( path.build("./", "a/", "b/"  ) == "./a/b"    )
  assert( path.build("/./","a/","/b/"  ) == "/a/b"     )
  assert( path.build("/a/b/./c","/./d" ) == "/a/b/c/d" )
--}
end

do
--@ wax.path.stat(path: string) : table | (nil, string)
--{ Get information about path status


  --| Usage example
  local res, err
  res, err = path.stat( testfile )

  assert(type(err) == "nil")   -- has no error
  assert(type(res) == "table") -- the retrieved data

  --| Which are the fields returned?
  assert(type(res.dev) == "string")  -- device id
  assert(type(res.rdev) == "string") -- device id for special files
  assert(res.ino     >= 0)           -- inode

  assert(res.mode == "644" ) -- octal permission
  assert(res.type == "file") -- filetype
  assert(res.nlink   >= 0)   -- number of hardlinks
  assert(res.uid     >= 0)   -- user id of owner
  assert(res.gid     >= 0)   -- group id of owner
  assert(res.size    >= 0)   -- total size in bytes
  assert(res.blksize >= 0)   -- block size for filesystem I/O
  assert(res.blocks  >= 0)   -- number of blocks allocated

  assert(res.atime   >= 0)   -- time of last access (unix secs)
  assert(res.atimens >= 0)   -- nanoseconds part of atime
  assert(res.ctime   >= 0)   -- time of last inode change (unix secs)
  assert(res.ctimens >= 0)   -- nanoseconds part of ctime
  assert(res.mtime   >= 0)   -- time of last modification (unix secs)
  assert(res.mtimens >= 0)   -- nanoseconds part of mtime

  --| Another example with the user home dir
  if user.name() ~= "root" then
    res, err = path.stat(user.home())
    assert(res.mode == "755")
    assert(res.type == "dir")
  end

  --| How it looks like when some stat error happens?
  res, err = path.stat("/some_invalid_path")
  assert(type(res) == "nil")
  assert(type(err) == "string")

--| Observations:
--|
--| 1. Some systems may not be able to retrieve nanoseconts for
--| atimens, ctimens and mtimens. In such cases the value should be zero.
--|
--| 2. Device Id's (dev and rdev) are returned as strings.
--| Lua number in C is of signed double type while the C value is of unsigned
--| long type. Some OSes, like FreeBSD and MacOS, already make use of the full
--| range of values of that type leading to misrepresentation
--| on Lua side.
--}
end

do
--@ wax.path.utime(path: string, atime, mtime: number) : boolean [, string]
--{ Change file access and/or modification times.
--|
--| 1. it time is < 0, set it to now;
--| 2. if time >= 0 set it to seconds since unixtime;
--|
--| Returns true on success or false and a descriptive error string.
--|
--| Note: atime and mtime support fractions of seconds until nanoseconds limited
--| only by the floating pointer precision of the number type in Lua.

  --| To see some examples, consider these times in seconds since Unix epoch
  local now = os.time(os.date("!*t"))
  local yesterday = now - 86400
  local lastweek  = now - (86400 * 7)
  local lastmonth = now - (86400 * 31)
  local lastyear  = now - (86400 * 366)

  --| Example1: update mtime to yesterday and atime to lastweek
  assert( path.utime(testfile, yesterday, lastweek) )

  local stat1 = path.stat(testfile)
  assert(stat1.mtime == yesterday and stat1.atime == lastweek)

  --| Example2: just touch the access time, no mtime update.
  assert( path.utime(testfile) )

  local stat2 = path.stat(testfile)
  local diff2 = stat2.atime - now
  assert(stat2.mtime == stat1.mtime) -- mtime was kept
  assert(diff2 < 1 and diff2 >= 0)   -- is now!

  --| Example 3: keep current mtime but set a diffrent specific atime
  assert( path.utime(testfile, nil, lastmonth) )

  local stat3 = path.stat(testfile)
  assert(stat3.atime == lastmonth)
  assert(stat3.mtime == stat1.mtime)


  --| Example 4: update mtime to a specific time
  --| Observe that atime is always updated to now, unless it is specified
  assert( path.utime(testfile, lastyear) )

  local stat4 = path.stat(testfile)
  local diff4 = stat4.atime - now
  assert(stat4.mtime == lastyear)
  assert(diff4 < 1 and diff4 >= 0)


  --| Example 5: sets distinct time for access and modification using nsecs
  --| time should be informed as a tuple: { seconds, nanoseconds }
  local atimeNew = { now + (86400*14), 123456789 }
  local mtimeNew = { now + (86400*21), 987654321 }

  res, err = path.utime(testfile, mtimeNew, atimeNew)
  after = path.stat(testfile)
  assert(after.atime == atimeNew[1] or after.atime == mtimeNew[1])
  assert(after.mtime == mtimeNew[1])

  mtimeNewUs = math.floor(mtimeNew[2]/1000) * 1000

  assert(after.atimens == atimeNew[2] -- fresh and good systems
      or after.atimens == mtimeNew[2] -- in systems that mtime updates atime
      or after.atimens == mtimeNewUs  -- systems with microsec resolution
      or after.atimens == 0)          -- in systems with no resolution < 1sec

  assert(after.mtimens == mtimeNew[2] -- fresh and good systems
      or after.mtimens == mtimeNewUs  -- systems with microsec resolution
      or after.mtimens == 0)          -- in systems with no resolution < 1sec


  --| Example 6: error example, trying against an inexistent file
  local res, err = path.utime("/some_inexistent_path", -1, 1)
  assert(res == false and type(err) == "string")

--}
end

do
--@ wax.path.access(path: string, mode: string|integer) : boolean [,string]
--{ Checks if user is allowed to access a file in specific modes.
--| Returns true if user has acess. Or false and a descriptive 
--| message otherwise.
--|
--| `mode: string` should be a combination of following letters:
--| - `r`: read permission
--| - `w`: write permission
--| - `x`: execute/search permission
--|
--| `mode : number` must combine following:
--| - `4`: read permission
--| - `2`: write permission
--| - `1`: execute/search permission
--|
--| Note that this function has is more performatic when a number
--| is specified on the `mode` argument.

  --| Example 1: Some common uses
  --| Some systems may have different permissions under root
  if user.name() ~= "root" then
    assert(path.access(testfile,"r")  == true)
    assert(path.access(testfile,"r")  == true)
    assert(path.access(testfile,"rx") == false)
    assert(path.access(testfile,"x")  == false)
    assert(path.access("/tmp","rwx")  == true)
    assert(path.access(user.home(),"rwx") == true)
  end


  --| Example 2: Different users, different privileges.
  if user.name() == "root" then
    assert(path.access("/","rwx") == true)
    assert(path.access("/root","rwx") == true)
    assert(path.access("/etc","rwx") == true)
  else
    assert(path.access("/root","w") == false)
    assert(path.access("/","rx") == true)
    assert(path.access("/","rwx") == false)
    assert(path.access("/etc","rwx") == false)
  end

  --| Example 3: mode number correspondence to mode strings
  for _,p in pairs{"/", "/home", "/root", "/tmp", testfile} do
    assert(path.access(p, "x")   == path.access(p,1))
    assert(path.access(p, "w")   == path.access(p,2))
    assert(path.access(p, "wx")  == path.access(p,3))
    assert(path.access(p, "r")   == path.access(p,4))
    assert(path.access(p, "rx")  == path.access(p,5))
    assert(path.access(p, "rw")  == path.access(p,6))
    assert(path.access(p, "rwx") == path.access(p,7))
  end

  --| Example 4: Invalid modes; If wrong arguments are passed, throws error.
  local res,err

  for _,invalidMode in pairs{"a", "rwz", 0, -1, 8, 100} do
    res, err = pcall(path.access,"/",invalidMode)
    assert(res == false and type(err) == "string")
  end

--}
end

do
--@ wax.path.getmod(path: string) : string | (nil, string)
--{ Returns the integer representation of the mode or nil and an error string
--| To understand the octal representation of mode, see the use of
--| `format()` below and tha explanation of octal return on `wax.path.chmod()`
  if user.name() ~= "root" then
    -- depending on OS root can be 700 or 750
    assert( path.getmod(user.home()) == "755" )
  end
  assert( path.getmod("/") == "755")
  assert( path.getmod("/tmp") == "777")
--}
end

do
--@ wax.path.chmod(path: string, mode: string]) : boolean [, string]
--{ Works as the system chmod. The number passed to mode should be
--| an integer number prefixed with "0" to constitute a octal representation
--|
--| Returns true on success or false and a descriptive error string.
--| To understand below tests, use this legend as reference:
--|
--|```
--|  ________ octal indicator
--| |  ______ user
--| | |  ____ group
--| | | |  __ others
--| | | | |
--| 0 7 6 4        r + w + x
--|   | | |__ 4 =  4   0   0
--|   | |____ 6 =  4   2   0
--|   |______ 7 =  4   2   1
--|```
  local perm

  perm = "755" -- (rwx,r-x,r-x)
  assert( path.chmod(testfile, perm) )
  assert( path.getmod(testfile) == perm )

  perm = "000" -- (---,---,---)
  assert( path.chmod(testfile, perm) )
  assert( path.getmod(testfile) == perm )

  perm = "123" -- (--x,-w-,-wx)
  assert( path.chmod(testfile, perm) )
  assert( path.getmod(testfile) == perm )

  perm = "466" -- (r--,rw-,rw-)
  assert( path.chmod(testfile, perm) )
  assert( path.getmod(testfile) == perm )

  perm = "644" -- (rw-,r--,r--)
  assert( path.chmod(testfile, perm) )
  assert( path.getmod(testfile) == perm )
--}
end

do
--@ wax.path.chown(path: string, user: string|int): boolean | (nil, string)
--{ Change path ownership. Group is optional.
  local testuser = "testuser"

  io.open(testfile,"w"):close()

  -- We need to be root to change file ownership on most of systems
  if user.id() == 0 then
    assert( path.chown(testfile, 10000) == true )
    assert( path.stat(testfile).uid == 10000 )
    assert( path.chown(testfile, "root") == true )
    assert( path.stat(testfile).uid == 0 )
    assert( path.chown(testfile, testuser) == true )
    assert( path.stat(testfile).uid == 2000 )
    assert( path.chown(testfile, "root") == true )
  end

--}
end


--|
--| ## Directory handling
--|

do
--@ wax.path.getcwd() : string | (nil, string)
--{ Get the current working directory path.
--| When not possible, returns nil and a descriptive string
  local curdir, newdir, destdir
  curdir = path.getcwd()

  -- directory should be a non empty string
  assert(type(curdir) == "string")
  assert(#curdir > 0)

  -- respect changings of the current path
  destdir = "/tmp"
  assert(path.chdir(destdir) == true)
  newdir = path.getcwd()
  assert(newdir == destdir)

  -- we reset the directory
  assert(path.chdir(curdir) == true)
  assert(path.getcwd() == curdir)
--}
end


do
--@ wax.path.isdir(path: string) : boolean [, string]
--{ If path is directory returns true or returns false with error string
  -- When path exists and is a file
  assert(path.isdir(testdir) == true)

  -- When path exists and is not a file
  assert(path.isdir(testfile) == false)

  -- When path not exists
  assert(path.isdir("/some_inexistent_dir_somewhere") == false)
--}
end


do
--@ wax.path.exists(path: string) : boolean
--{ Checks if path exists and returns true or returns false with error string
  assert(path.exists("/") == true)
  assert(path.exists("/home") == true)
  assert(path.exists(testfile) == true)
  local res, err = path.exists("/inexistent_component")
  assert(res == false and type(err) == "string")
--}
end


do
--@ wax.path.umask([mask: string]) : string
--{ Set a new mask and returns the old one.
--| When called without argument, returns the current umask.

  -- Sets the umask to 777 and retrieves current mask
  local curmask = path.umask("777")
  local curmasknum = tonumber(curmask, 8)
  local minmask, maxmask = 0, 511 -- 511 is the decimal of "777" octal

  assert(#curmask == 3)
  assert(curmasknum >= minmask and curmasknum <= maxmask)

  -- Reset the umask to the original
  local newmask = path.umask(curmask)
  assert(newmask == "777")

  -- Check again the umask to test with no arguments
  assert(path.umask() == curmask) -- check if previous call take effect
  assert(path.umask() == curmask) -- check if previews empty not change
--}
end


do
--@ wax.path.chdir(path: string) : boolean [, string]
--{ Changes current working dir.
--| returns true on success or false and descriptive string
  local curdir = path.getcwd()
  local home = path.real( user.home() )
  assert(path.chdir(home) == true)
  assert(path.getcwd() == home)
  assert(path.chdir(curdir) == true)
  assert(path.getcwd() == curdir)
--}
end


do
--@ wax.path.mkdir(path: string, mode: string) : boolean [, string]
--{ Create a new directory and returns true or returns false with error string.
--| If you need to create nested subdirectories see `wax.path.mkdirs()`
--| The `mode` parameter is a string like "777".
  local testSubDir = path.build(testdir,"Sub","Dir")
  local mode = "777";
  local masked = ("%03o"):format( tonumber(mode,8) - tonumber(path.umask(),8));

  if path.exists(testdir) then path.rmdir(testdir) end

  -- Success example
  local newdir = path.build(testdir,"newdir")
  assert(not path.isdir(newdir))
  assert(path.mkdir(newdir,mode) == true)
  assert(path.isdir(newdir) == true)

  -- The umask is applyied on creation (usually 022). So 777 | 022 = 755
  -- you can discover or set the umask using `wax.path.umask()`
  assert(path.getmod(newdir) == masked)

  -- Error example (trying to create directly subdirectories)
  local ok, err = path.mkdir(testSubDir,mode)
  assert(ok == false)
  assert(type(err) == "string")

  -- Another error examples
  assert(not path.mkdir(testdir,mode)) -- already exists
  assert(not path.mkdir(testfile,mode)) -- exists and is a file

--}
end

do
--@ wax.path.mkdirs(path: string, mode: string) : boolean [, string]
--{ Make all missing directories in path string and returns true.
--| When not possible, returns a descriptive string.ocal ds = "%s"..path.dirsep.."%s"
--| The `mode` parameter is a string like "777".

  local uncle = path.build("..","uncleDir")
  local cousin = path.build(uncle,"cousin")
  assert(path.mkdirs(cousin,"777"))
  assert(path.isdir(cousin))
  assert(path.rmdir(cousin))
  assert(path.rmdir(uncle))

  local mlangPathParts = {
  --[[Arab      ]] "الدليل",
  --[[Armenian  ]] "կատալոգ",
  --[[Georgian  ]] "საქაღალდე",
  --[[Hindi     ]] "फ़ोल्डर",
  --[[Russian   ]] "каталог",
  --[[S. Chinese]] "目录",
  --[[Tamil     ]] "அடைவு",
  }

  local unpack = unpack or table.unpack

  -- Create the entire path, wher each subfolder has a different glyph set
  local mlangPath = path.build(testdir, unpack(mlangPathParts))
  assert( path.mkdirs(mlangPath,"777") )

  -- Cleanup the kitchen
  for i=#mlangPathParts, 1, -1 do
    mlangPath = path.build(testdir, unpack(mlangPathParts,1,i))
    assert( path.isdir(mlangPath) )
    assert( path.rmdir(mlangPath) )
  end

  if user.name() ~= "root" then
    res, err = path.mkdirs("/some_dir","777")
    assert(res == false)
    assert(type(err) == "string")
  end
--}
end

do
--@ wax.path.rmdir(path: string) : boolean [, string]
--{ Remove directory if it is not empty.
  local dirParent = path.build( path.getcwd(), "rmdirParent" )
  local dirChild  = path.build( dirParent,"rmdirChild" )
  assert(path.mkdirs(dirChild,"777"))

  -- Error: Directory is not empty
  local res, err = path.rmdir(dirParent)
  assert(res == false and type(err) == "string")

  -- Success
  assert(path.rmdir(dirChild))
  assert(not path.isdir(dirChild))

  -- Error: Directory not exists
  res, err = path.rmdir(dirChild)
  assert(res == false and type(err) == "string")

  -- Success
  assert(path.rmdir(dirParent))
--}
end


do
--@ wax.path.list(directory: string) : iterator, userdata
--{ Open an iterator to list for filesystem entries inside
--| the specified directory.

  --| Example 1: Basic usage
  if path.isdir("/") then
    for entry in path.list("/") do
      -- do something with entry
      assert(type(entry) == "string")
    end
  end

  --| Example 2: What path.list() returns?
  if path.isdir("/") then
    local iter, data = path.list("/")
    assert(type(iter) == "function")
    assert(type(data) == "userdata")
  end

  --| Example 3: Root directory should have more than one entry
  if path.isdir("/") then
    local count = 0;
    for _ in path.list("/") do
      count = count + 1
    end
    assert(count > 0)
  end

  --| Example 4: Observe that in above examples we checked with path.isdir()
  --| before iterate with path.list(). If you don't do that you can break the
  --| Lua execution. Other way to avoid the path.isdir() check is to use
  --| pcall() but it is not so clear as the above:
  local ok, iter, data = pcall(path.list,"/baaa/beeeh/biii/boooh/bum!")

  if ok then
    for entry in iter, data do
      print(entry)
    end
  else
    assert(ok == false and type(iter) == "string")
  end
end
--}

do
--@ wax.path.listex(pathexp: string) : function, userdata
--{ List for filesystem entries using word expansions
--| The usage is very similar of shell `ls` command.
--| Don't be confused with Lua patterns or RegExps.
--|
--| The word expansions patters works this way:
--| * `*` matches any character in any ammount.
--| * `?` matches any character in specified position.
--| * `[a-z]` matches any character in the range [a-z] in an specified position.
--| * `[az]` matches only "a" and "z" in an specified position.
--|
--| * `/tmp/?.lua` matches anything inside temporary directory with its name
--| consisting of a single character followed by `.lua` string
--| * `/tmp/*.lua` matches any file or directory with name ended in `.lua`
--| * `/tmp/[a-c]*.lua` matches any file started with "a", "b" or "c" followed
--| by any ammount of characters ended with ".lua" string

  --| Example 1.
  --| Basic usage
  for matched in path.listex("/*") do
    -- do something with the matched
    assert(type(matched) == "string")
  end

  --| Example 2.
  --| What path.listex() returns?
  local func, data = path.listex('/*')
  assert(type(func) == "function")
  assert(type(data) == "userdata")

  --| Example 3.
  --| If the path doesn't exists listex() doesnt throws
  local count = 0
  for _ in path.listex('/some/inexistent/path/*/*/*/*') do
    count = count + 1
  end
  assert(count == 0)

  --| Example 4.
  --| `path.listex()` always returns the entire path matched for entries.
  --| So if you search "../something/*" and there are matches, all the entries
  --| will have the "../something" as its prefix.
  local queries = { "./*", "../*", "/b*" }
  for _, query in ipairs(queries) do
    for entry in path.listex(query) do
      assert( entry:sub(1,2) == query:sub(1,2) )
    end
  end

  --| Observe that unlike `path.list()` we didn't check if directory exists or
  --| if we have permission to access it. This relaxed nature allows you to
  --| use it for searching files and do things if some path is found. In fact
  --| `path.listex()` is more like a "filter" counterpart of `path.list()` that
  --| can return zero or more entries.
  --|
  --| You are encouraged to develop yourself your test strategy if needed
  --| before call `path.listex()`.

--}
end
os.exit(0)

--|
--| ## Symbolic links handling
--|

do
--@ wax.path.islink(path: string) : boolean
--{ checks if the path exists and is a link
  assert(path.islink("/somelink") == true)

  local ok, errstr

  --| Existent path but not directory
  ok, errstr = path.islink("/some_not_link")
  assert(ok == false)
  assert(type(errstr) == "nil")

  --| Inexistent path
  ok, errstr = path.islink("/some_inexistent_path")
  assert(ok == false);
  assert(type(errstr) == "nil")
--}
end

do
--@ wax.path.makeLink(orig, dest: string) : boolean [, string]
--{ Creates a new link from `orig` to `dest` and return true.
--| When not possible returns false and a descriptive string.
assert(path.makeLink());
--}
end

--@ wax.path.linkStat(path: string) : table | (nil, string)
--{ Get the stat for links returning a table.
--| When not possible, returns nil and a descriptive string.
  assert(path.linkStat())
--}

--|
--| ## Regular files handling
--|

do
--@ wax.path.isfile(path: string) : boolean
--{ Check if path is a regular file and is reachable.
--| Note that "reachable" doen't means "writable".
--| If script has not access to path resolution, the function also
--| return a error string.
  assert(path.isfile(testfile))
--}
end

do
--@ wax.path.unlink(path: string) : boolean [, string]
--{ Removes a file or link and returns true.
--| When it is not possible, returns false and a descriptive string.
  assert(path.unlink())
--}
end

--|
--| ## Named pipes handling
--|
--| Named pipes or FIFO's are special files used for comunications between
--| applications.

do
--@ wax.path.ispipe(path: string) : boolean
--{ Check if the file is a pipe (FIFO)
  assert(path.ispipe("/pipe"))
--}
end

do
--@ wax.path.makePipe(path: string) : boolean [, string]
--{ Create a new named pipe file (FIFO) and return true.
--| When not possible returns false and a descriptive string.
assert(path.makepipe())
--}
end


--|
--| ## Others
--|

do
--@ wax.path.ischardev(path: string) : boolean
--{ Checks if the file is a character device.
--| These are special files used to send data for devices like
--| printer, screen, speakers, mouse, keyboard etc.
assert(path.ischardev("/dev/tty"))
--}
end

do
--@ wax.path.isblockdev(path: string) : boolean
--{ Checks if the file is a block device.
--| These are special files used to manage physical data storage
--| like USB, SD, HDD etc.
  assert(path.isblockdev("/dev/sda"))
--}
end


print("\n_______ wax.path ".._VERSION..": OK!");

-- vim: foldmethod=marker foldmarker=--{,--} foldenable
