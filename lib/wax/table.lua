
local table_tostring, table_tochunk
do
  local cat,fmt = table.concat, string.format
  local validkey = { string='[%q]', number='[%s]', boolean='[%s]' }
  local validval = { string='%q', number='%s', boolean='%s', table=1 }

  function table_tostring(t)
    local p, res = {nil,'=',nil}, {}
    local ktype, kfmt ,vfmt
    local i = 1
    for _,v in ipairs(t) do
      vfmt = validval[type(v)]
      if vfmt then
        res[i] = vfmt == 1
            and table_tostring(v)
            or  fmt( vfmt, v )
        i=i+1
      end
    end
    for k,v in pairs(t) do
      ktype = type(k) kfmt = validkey[ktype]
      if kfmt and (ktype ~= 'number' or k < 1 or k % 1 ~= 0) then
        vfmt = validval[type(v)]
        if vfmt then
          p[1] = ktype == 'string' and k:match('^[%l%d_]+$')
            and tostring(k)
            or fmt(kfmt, tostring(k))
          p[3] = vfmt == 1
            and table_tostring(v)
            or  fmt(vfmt, tostring(v))
          res[i],i = cat(p), i+1
        end
      end
    end
    res[2],res[1],res[3] = cat(res,','),'{','}'
    return cat(res,'',1,3)
  end

  function table_tochunk(t)
    local kt, vfmt
    local p = {nil,'=',nil}
    local res, r = {},1
    for k,v in pairs(t) do
      kt = type(k)
      if kt == 'string' and k:match('^[%l%d_]+$') then
        vfmt = validval[type(v)]
        if vfmt then
          p[1] = k
          p[3] = vfmt == 1 and table_tostring(v) or fmt(vfmt,v)
          res[r],r = cat(p),r+1
        end
      end
    end
    return cat(res,'\n')
  end
end
local table = {
  tostring = table_tostring,
  tochunk = table_tochunk
}

return table
