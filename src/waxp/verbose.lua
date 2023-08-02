local verbose = {}
local stdout = io.stdout
function verbose.rule(msg, ...)
  stdout:write '---------------------------------\n'
  stdout:write(msg:format(...))
  stdout:write '\n'
end

return function(fmt,...)
  return (verbose[fmt] or print) (...)
end
