-- This file updates Wax C dependencies from outer projects.
-- It is intended to be performed only when needed as external dependencies can
-- contain breaking changes


local tasks = {
  { url = "https://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.tar.gz",
    files = "cJSON-1.7.15/cJSON.*",
    dstdir = "json",
    license = "MIT"}
}

local tmpdir = "/tmp/wax-srcext-update"
local tmpfile = ('%s/%s'):format(tmpdir,'task.tgz')

local x = function(c) print(c) assert(os.execute(c)) end
local X = function(c) c = assert(io.popen(c)) return c:read(), c:close() end
local selfdir =
  X(('realpath %q')
  :format(debug.getinfo(1,'S').short_src:gsub('/[^/]+$','')))

x( ('mkdir -p %q'):format(tmpdir) )

function runtask(task)
  local dstdir = ('%s/%s/'):format(selfdir, task.dstdir)

  x( ('curl --location %q > %q'):format(task.url, tmpfile) )
  x( ('cd %q && tar zxvf %q'):format(tmpdir, tmpfile) )
  x( ('cd %q && cp -rf %s %q'):format(tmpdir, task.files, dstdir) )
end

for _,task in pairs(tasks) do runtask(task) end
