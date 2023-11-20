-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Copyright 2022-2023 - Thadeu de Paula and contributors

--[[
Filesystem utilities
--------------------

Use ``wax.fs`` module to to list, create, remove, set and get permissions of
files and directories.
--]]

local fs = require 'wax.fs'

-- It may be not compiled, so we emulate it
local user
do
  -- local user = require("wax.user")
  local id, name, home = os.getenv "UID", os.getenv "USER", os.getenv "HOME"
  user = {
    id   = function() return id end,
    name = function() return name end,
    home = function() return home end
  }
end

-- Prepares the environment for following tests
local testdir, testfile
do
  testdir = '.local/tmp'
  os.execute( ("rm -rf %q"):format(testdir) )
  os.execute( ("mkdir %q"):format(testdir) )
  testfile = testdir.."/wax.fs_testfile"
  local fh = io.open(testfile, "a")
  if fh ~= nil then
    fh:write("Lore ipsum\n")
    fh:close()
  end
end

--$ fs.dirsep : string
--| Directory separator, that can change accordingly to the system.
--| * BSD, Linux etc.: `"/"` (slash)
--| * Windows:         `"\"` (backslash)
do assert( fs.dirsep == "/" or fs.dirsep == "\\" ) end


--$ fs.realpath( path: string ) : string | (nil, string)
--| Resolves the realpath of the `path` and returns true.
--| When not possible, returns false and a descriptive string.
do
--{
  assert( fs.realpath("/usr/bin/")       == "/usr/bin")
  assert( fs.realpath("/usr/bin/../lib") == "/usr/lib")

  local res, err = fs.realpath("/a_/_b/c_/../_d")
  assert( res == nil and type(err) == "string" )
--}
end


--$ fs.dirname(path: string) : string
--| Get the dir part of the path and return it.
do
--{
  assert( fs.dirname("/usr/lib") == "/usr" )
  assert( fs.dirname("/usr/"   ) == "/"     )
  assert( fs.dirname("usr"     ) == "."     )
  assert( fs.dirname("/"       ) == "/"     )
  assert( fs.dirname("."       ) == "."     )
  assert( fs.dirname(".."      ) == "."     )
--}
end

--$ fs.basename(path: string) : string
--| Get the filename part of the path and return it.
do
--{
  assert( fs.basename("/usr/lib") == "lib" )
  assert( fs.basename("/usr/"   ) == "usr" )
  assert( fs.basename("usr"     ) == "usr" )
  assert( fs.basename("/"       ) == "/"   )
  assert( fs.basename("."       ) == "."   )
  assert( fs.basename(".."      ) ==  ".." )
--}
end

--$ fs.buildpath(dir1 ... dirN: string) : string
--| Receives a variable number of strings and builds a path from it
do
--| Basic Usage:
--| 1. concatenate correctly the path elements
--{
  assert( fs.buildpath("1nd","2nd","3rd") == "1nd/2nd/3rd" )
--}
--| 2. clear strange paths
--{
  assert( fs.buildpath("a//b////c/./d/") == "a/b/c/d")
--}
--| Expected behavior
--| 1. Doesn't normalizes parent `..` entries
--{
  assert( fs.buildpath("a/../a")       == "a/../a" )
  assert( fs.buildpath("..", "a", "b") == "../a/b" )
--}
--| 2. remove rightmost pending separator
--{
  assert( fs.buildpath("a/b/c/") == "a/b/c" )
--}
--| 3. remove duplicated separators
--{
  assert( fs.buildpath("a//","/b/","/c/") == "a/b/c"  )
  assert( fs.buildpath("//a","b/c"      ) == "/a/b/c" )
--}
--| 4. remove relative here dot `.` that is not the first char
--{
  assert( fs.buildpath(".", "a", "b"     ) == "./a/b"    )
  assert( fs.buildpath(".", "a", ".", "b") == "./a/b"    )
  assert( fs.buildpath("./a"," b/", "./c") == "./a/ b/c" )
  assert( fs.buildpath("a", "..", "b"    ) == "a/../b"   )
  assert( fs.buildpath("./", "a/", "b/"  ) == "./a/b"    )
  assert( fs.buildpath("/./","a/","/b/"  ) == "/a/b"     )
  assert( fs.buildpath("/a/b/./c","/./d" ) == "/a/b/c/d" )
--}
end

--$ fs.stat(path: string) : table | (nil, string)
--| Get information about path status
do
--| Usage example
--{
  local res, err
  res, err = fs.stat( testfile )

  assert(type(err) == "nil")   -- has no error
  assert(type(res) == "table") -- the retrieved data

  -- Which are the fields returned?

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
--}

--| Another example with the user home dir
--{
  if user.name() ~= "root" then
    res, err = fs.stat(user.home())
    assert(res.mode == "755")
    assert(res.type == "dir")
  end
--}

--| What happens when some stat error happens?
--{
  res, err = fs.stat("/some_invalid_path")
  assert(type(res) == "nil")
  assert(type(err) == "string")
--}

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
end

--$ fs.utime(path: string, atime, mtime: number) : boolean [, string]
--| Change file access and/or modification times.
do
--| 1. it time is < 0, set it to now;
--| 2. if time >= 0 set it to seconds since unixtime;
--|
--| Returns true on success or false and a descriptive error string.
--|
--| Note: atime and mtime support fractions of seconds until nanoseconds limited
--| only by the floating pointer precision of the number type in Lua.
--|
--| To see some examples, consider these times in seconds since Unix epoch
--{
  local now = os.time(os.date("*t"))
  local yesterday = now - 86400
  local lastweek  = now - (86400 * 7)
  local lastmonth = now - (86400 * 31)
  local lastyear  = now - (86400 * 366)
--}
--| Example1: update mtime to yesterday and atime to lastweek
--{
  assert( fs.utime(testfile, yesterday, lastweek) )

  local stat1 = fs.stat(testfile)
  assert(stat1.mtime == yesterday and stat1.atime == lastweek)
--}
--| Example2: just touch the access time, no mtime update.
--{
  assert( fs.utime(testfile) )

  local stat2 = fs.stat(testfile)
  local diff2 = stat2.atime - now
  assert(stat2.mtime == stat1.mtime) -- mtime was kept
  assert(diff2 < 1 and diff2 >= 0)   -- is now!
--}
--| Example 3: keep current mtime but set a diffrent specific atime
--{
  assert( fs.utime(testfile, nil, lastmonth) )

  local stat3 = fs.stat(testfile)
  assert(stat3.atime == lastmonth)
  assert(stat3.mtime == stat1.mtime)
--}
--| Example 4: update mtime to a specific time
--| Observe that atime is always updated to now, unless it is specified
--{
  assert( fs.utime(testfile, lastyear) )

  local stat4 = fs.stat(testfile)
  local diff4 = stat4.atime - now
  assert(stat4.mtime == lastyear)
  assert(diff4 < 1 and diff4 >= 0)
--}
--| Example 5: sets distinct time for access and modification using nsecs
--| time should be informed as a tuple: { seconds, nanoseconds }
--{
  local atimeNew = { now + (86400*14), 123456789 }
  local mtimeNew = { now + (86400*21), 987654321 }

  res, err = fs.utime(testfile, mtimeNew, atimeNew)
  after = fs.stat(testfile)
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
--}
--| Example 6: error example, trying against an inexistent file
--{
  local res, err = fs.utime("/some_inexistent_path", -1, 1)
  assert(res == false and type(err) == "string")
--}
end

--$ fs.access(path: string, mode: string|integer) : boolean [,string]
--| Checks if user is allowed to access a file in specific modes.
--| Returns true if user has acess. Or false and a descriptive
--| message otherwise.
do
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
--|
--| Example 1: Some common uses
--| Some systems may have different permissions under root
--{
  if user.name() ~= "root" then
    assert(fs.access(testfile,"r")  == true)
    assert(fs.access(testfile,"r")  == true)
    assert(fs.access(testfile,"rx") == false)
    assert(fs.access(testfile,"x")  == false)
    assert(fs.access("/tmp","rwx")  == true)
    assert(fs.access(user.home(),"rwx") == true)
  end
--}
--| Example 2: Different users, different privileges.
--{
  if user.name() == "root" then
    assert(fs.access("/","rwx")     == true)
    assert(fs.access("/root","rwx") == true)
    assert(fs.access("/etc","rwx")  == true)
  else
    assert(fs.access("/root","w")  == false)
    assert(fs.access("/","rx")     == true)
    assert(fs.access("/","rwx")    == false)
    assert(fs.access("/etc","rwx") == false)
  end
--}

--| Example 3: mode number correspondence to mode strings
--{
  for _,p in pairs{"/", "/home", "/root", "/tmp", testfile} do
    assert(fs.access(p, "x")   == fs.access(p,1))
    assert(fs.access(p, "w")   == fs.access(p,2))
    assert(fs.access(p, "wx")  == fs.access(p,3))
    assert(fs.access(p, "r")   == fs.access(p,4))
    assert(fs.access(p, "rx")  == fs.access(p,5))
    assert(fs.access(p, "rw")  == fs.access(p,6))
    assert(fs.access(p, "rwx") == fs.access(p,7))
  end
--}

--| Example 4: Invalid modes; If wrong arguments are passed, throws error.
--{
  local res,err

  for _,invalidMode in pairs{"a", "rwz", 0, -1, 8, 100} do
    res, err = pcall(fs.access,"/",invalidMode)
    assert(res == false and type(err) == "string")
  end
--}
end

--$ fs.getmod(path: string) : string | (nil, string)
--| Returns the integer representation of the mode or nil and an error string
--| To understand the octal representation of mode, see the use of `format()`
--| below and tha explanation of octal return on `wax.fs.chmod()`
do
--{
  if user.name() ~= "root" then
    -- depending on OS root can be 700 or 750
    assert( fs.getmod(user.home()) == "755" )
  end
  assert( fs.getmod("/") == "755")
  assert( fs.getmod("/tmp") == "777")
--}
end

--$ fs.chmod(path: string, mode: string]) : boolean [, string]
--| Works as the system chmod. The number passed to mode should be
--| an integer number prefixed with "0" to constitute a octal representation
--|
--| Returns true on success or false and a descriptive error string.
--| To understand below tests, use this legend as reference:
do
--| ```
--|  ________ octal indicator
--| |  ______ user
--| | |  ____ group
--| | | |  __ others
--| | | | |
--| 0 7 6 4        r + w + x
--|   | | |__ 4 =  4   0   0
--|   | |____ 6 =  4   2   0
--|   |______ 7 =  4   2   1
--{ ```
  local perm

  perm = "755" -- (rwx,r-x,r-x)
  assert( fs.chmod(testfile, perm) )
  assert( fs.getmod(testfile) == perm )

  perm = "000" -- (---,---,---)
  assert( fs.chmod(testfile, perm) )
  assert( fs.getmod(testfile) == perm )

  perm = "123" -- (--x,-w-,-wx)
  assert( fs.chmod(testfile, perm) )
  assert( fs.getmod(testfile) == perm )

  perm = "466" -- (r--,rw-,rw-)
  assert( fs.chmod(testfile, perm) )
  assert( fs.getmod(testfile) == perm )

  perm = "644" -- (rw-,r--,r--)
  assert( fs.chmod(testfile, perm) )
  assert( fs.getmod(testfile) == perm )
--}
end

--$ fs.chown(path: string, user: string|int): boolean | (nil, string)
--| Change path ownership. Group is optional.
do
--{
  local testuser = "testuser"

  io.open(testfile,"w"):close()

  -- We need to be root to change file ownership on most of systems
  if user.id() == 0 then
    assert( fs.chown(testfile, 10000) == true )
    assert( fs.stat(testfile).uid == 10000 )
    assert( fs.chown(testfile, "root") == true )
    assert( fs.stat(testfile).uid == 0 )
    assert( fs.chown(testfile, testuser) == true )
    assert( fs.stat(testfile).uid == 2000 )
    assert( fs.chown(testfile, "root") == true )
  end
--}
end


--|
--| ## Directory handling
--|

--$ fs.getcwd() : string | (nil, string)
--| Get the current working directory path.
--| When not possible, returns nil and a descriptive string
do
--{
  local curdir, newdir, destdir
  curdir = fs.getcwd()

  -- directory should be a non empty string
  assert(type(curdir) == "string")
  assert(#curdir > 0)

  -- respect changings of the current path
  destdir = "/tmp"
  assert(fs.chdir(destdir) == true)
  newdir = fs.getcwd()
  assert(newdir == destdir)

  -- we reset the directory
  assert(fs.chdir(curdir) == true)
  assert(fs.getcwd() == curdir)
--}
end


--$ fs.isdir(path: string) : boolean [, string]
--| If path is directory returns true or returns false with error string
do
--{
  -- When path exists and is a file
  assert(fs.isdir(testdir) == true)

  -- When path exists and is not a file
  assert(fs.isdir(testfile) == false)

  -- When path not exists
  assert(fs.isdir("/some_inexistent_dir_somewhere") == false)
--}
end


--$ fs.exists(path: string) : boolean
--| Checks if path exists and returns true or returns false with error string
do
--{
  assert(fs.exists("/") == true)
  assert(fs.exists("/home") == true)
  assert(fs.exists(testfile) == true)
  local res, err = fs.exists("/inexistent_component")
  assert(res == false and type(err) == "string")
--}
end


--$ fs.umask([mask: string]) : string
--| Set a new mask and returns the old one.
--| When called without argument, returns the current umask.
do
--{
  -- Sets the umask to 777 and retrieves current mask
  local curmask = fs.umask("777")
  local curmasknum = tonumber(curmask, 8)
  local minmask, maxmask = 0, 511 -- 511 is the decimal of "777" octal

  assert(#curmask == 3)
  assert(curmasknum >= minmask and curmasknum <= maxmask)

  -- Reset the umask to the original
  local newmask = fs.umask(curmask)
  assert(newmask == "777")

  -- Check again the umask to test with no arguments
  assert(fs.umask() == curmask) -- check if previous call take effect
  assert(fs.umask() == curmask) -- check if previews empty not change
--}
end


--$ fs.chdir(path: string) : boolean [, string]
--| Changes current working dir.
--| returns true on success or false and descriptive string
do
--{
  local curdir = fs.getcwd()
  local home = fs.realpath( user.home() )
  assert(fs.chdir(home) == true)
  assert(fs.getcwd() == home)
  assert(fs.chdir(curdir) == true)
  assert(fs.getcwd() == curdir)
--}
end


--$ fs.mkdir(path: string, mode: string) : boolean [, string]
--| Create a new directory and returns true or returns false with error string.
--| If you need to create nested subdirectories see `wax.fs.mkdirs()`
--| The `mode` parameter is a string like "777".
do
--{
  local testSubDir = fs.buildpath(testdir,"Sub","Dir")
  local mode = "777";
  local masked = ("%03o"):format( tonumber(mode,8) - tonumber(fs.umask(),8));

  if fs.exists(testdir) then fs.rmdir(testdir) end

  -- Success example
  local newdir = fs.buildpath(testdir,"newdir")
  assert(not fs.isdir(newdir))
  assert(fs.mkdir(newdir,mode) == true)
  assert(fs.isdir(newdir) == true)

  -- The umask is applyied on creation (usually 022). So 777 | 022 = 755
  -- you can discover or set the umask using `wax.fs.umask()`
  assert(fs.getmod(newdir) == masked)

  -- Error example (trying to create directly subdirectories)
  local ok, err = fs.mkdir(testSubDir,mode)
  assert(ok == false)
  assert(type(err) == "string")

  -- Another error examples
  assert(not fs.mkdir(testdir,mode)) -- already exists
  assert(not fs.mkdir(testfile,mode)) -- exists and is a file
--}
end

--$ fs.mkdirs(path: string, mode: string) : boolean [, string]
--| Make all missing directories in path string and
--| returns true. When not possible, returns a descriptive
--| string. `mode` parameter is a string like "777".
do
--{
  local uncle = fs.buildpath("..","uncleDir")
  local cousin = fs.buildpath(uncle,"cousin")
  assert(fs.mkdirs(cousin,"777"))
  assert(fs.isdir(cousin))
  assert(fs.rmdir(cousin))
  assert(fs.rmdir(uncle))

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
  local mlangPath = fs.buildpath(testdir, unpack(mlangPathParts))
  assert( fs.mkdirs(mlangPath,"777") )

  -- Cleanup the kitchen
  for i=#mlangPathParts, 1, -1 do
    mlangPath = fs.buildpath(testdir, unpack(mlangPathParts,1,i))
    assert( fs.isdir(mlangPath) )
    assert( fs.rmdir(mlangPath) )
  end

  if user.name() ~= "root" then
    res, err = fs.mkdirs("/some_dir","777")
    assert(res == false)
    assert(type(err) == "string")
  end
--}
end

--$ fs.rmdir(path: string) : boolean [, string]
--| Remove directory if it is not empty.
do
--{
  local dirParent = fs.buildpath( fs.getcwd(), "rmdirParent" )
  local dirChild  = fs.buildpath( dirParent,"rmdirChild" )
  assert(fs.mkdirs(dirChild,"777"))

  -- Error: Directory is not empty
  local res, err = fs.rmdir(dirParent)
  assert(res == false and type(err) == "string")

  -- Success
  assert(fs.rmdir(dirChild))
  assert(not fs.isdir(dirChild))

  -- Error: Directory not exists
  res, err = fs.rmdir(dirChild)
  assert(res == false and type(err) == "string")

  -- Success
  assert(fs.rmdir(dirParent))
--}
end


--$ fs.list(directory: string) : function
--| List for filesystem entries inside the specified directory.
--| It retuns a function that can be used to retrieve a file per call.
do
--| Example 1: Basic usage
--{
  if fs.isdir("/") then
    for entry in fs.list("/") do
      -- do something with entry
      assert(type(entry) == "string")
    end
  end
--}
--| Example 2: What fs.list() returns?
--{
  if fs.isdir("/") then
    local iter = fs.list("/")
    assert(type(iter) == "function")
  end
--}
--| Example 3: Root directory should have more than one entry
--{
  if fs.isdir("/") then
    local count = 0;
    for _ in fs.list("/") do
      count = count + 1
    end
    assert(count > 0)
  end
--}
--| Example 4: Observe that in above examples we checked with fs.isdir()
--| before iterate with fs.list(). If you don't do that you can break the
--| Lua execution. Other way to avoid the fs.isdir() check is to use
--| pcall() but it is not so clear as the above:
--{
  local ok, iter, data = pcall(fs.list,"/baaa/beeeh/biii/boooh/bum!")

  if ok then
    for entry in iter, data do
      print(entry)
    end
  else
    assert(ok == false and type(iter) == "string")
  end
--}
end


--$ fs.glob(pathexp: string) : function
--| List for filesystem entries using word expansions.
--| The resulting function is an iterator that retrieves
--| a path per call.
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
do
--| Example 1.
--| Basic usage
--{
  for matched in fs.glob("/*") do
    -- do something with the matched
    assert(type(matched) == "string")
  end
--}
--| Example 2.
--| What fs.glob() returns?
--{
  local func = fs.glob('/*')
  assert(type(func) == "function")
--}
--| Example 3.
--| If the path doesn't exists glob() doesnt throws
--{
  local count = 0
  for _ in fs.glob('/some/inexistent/path/*/*/*/*') do
    count = count + 1
  end
  assert(count == 0)
--}
--| Example 4.
--| `fs.glob()` always returns the entire path matched for entries.
--| So if you search "../something/*" and there are matches, all the entries
--| will have the "../something" as its prefix.
--{
  local queries = { "./*", "../*", "/b*" }
  for _, query in ipairs(queries) do
    for entry in fs.glob(query) do
      assert( entry:sub(1,2) == query:sub(1,2) )
    end
  end
--}
--| Observe that unlike `fs.list()` we didn't check if directory exists or
--| if we have permission to access it. This relaxed nature allows you to
--| use it for searching files and do things if some path is found. In fact
--| `fs.glob()` is more like a "filter" counterpart of `fs.list()` that
--| can return zero or more entries.
--|
--| You are encouraged to develop yourself your test strategy if needed
--| before call `fs.glob()`.
end


--|
--| ## Regular files handling
--|

--$ fs.isfile(path: string) : boolean
--| Check if path is a regular file and is reachable.
do
--| Note that "reachable" doesn't means "writable". If script has not access to
--| path resolution, the function also returns an error string.
--{
  assert(fs.isfile(testfile))
--}
end

--$ fs.unlink(path: string) : boolean [, string]
--| Removes a file or link and returns true.
--| When it is not possible, returns false and a descriptive string.
do
--{
  local tmpfile = os.tmpname()
  assert(fs.unlink(tmpfile))
--}
end

-- TODO: implement below functions
os.exit(0)

--|
--| ## Named pipes handling
--|
--| Named pipes or FIFO's are special files used for comunications between
--| applications.

do
--$ fs.makePipe(path: string) : boolean [, string]
--| Create a new named pipe file (FIFO) and return true on success or false and
--| a descriptive string on error.
--{
  local fifo = fs.mkpipe('/tmp/exfifo')
  assert(fifo)
--}

--$ fs.ispipe(path: string) : boolean
--{ Check if the file is a pipe (FIFO)
  assert(fs.ispipe(fifo))
--}
  fs.unlink(fifo)
end



--|
--| ## Others
--|

--$ fs.ischardev(path: string) : boolean
--| Checks if the file is a character device.
--| These are special files used to send data for devices like
--| printer, screen, speakers, mouse, keyboard etc.
do
--{
  assert(fs.ischardev("/dev/tty"))
--}
end

--$ fs.isblockdev(path: string) : boolean
--| Checks if the file is a block device.
--| These are special files used to manage physical data storage
--| like USB, SD, HDD etc.
do
--{
  assert(fs.isblockdev("/dev/sda"))
--}


end

--|
--| ## Symbolic links handling
--|

--$ fs.islink(path: string) : boolean
--| checks if the path exists and is a link
do
--{
  assert(fs.islink("/somelink") == true)

  local ok, errstr
--}
--| Existent path but not directory:
--{
  ok, errstr = fs.islink("/some_not_link")
  assert(ok == false)
  assert(type(errstr) == "nil")
--}
--| Inexistent path:
--{
  ok, errstr = fs.islink("/some_inexistent_path")
  assert(ok == false);
  assert(type(errstr) == "nil")
--}
end

--$ fs.makeLink(orig, dest: string) : boolean [, string]
--| Creates a new link from `orig` to `dest` and return true.
--| When not possible returns false and a descriptive string.
do
--{
assert(fs.makeLink());
--}
end

--$ fs.linkStat(path: string) : table | (nil, string)
--| Get the stat for links returning a table.
--| When not possible, returns nil and a descriptive string.
do
--{
  assert(fs.linkStat("/"))
--}
end

--$ fs.listex()
--| Deprecated. Use `fs.glob()` instead.
