local unpack = table.unpack or unpack

local parse do
	local fold

	function fold(t, arg, p, o)
		local a = arg[p]

		if not a then return t end
		if a:find('^%-%-') then
			o = a:sub(3)
			if o ~= '' then t.opt[o] = t.opt[o] or {} end
		elseif o and o ~= '' then
			t.opt[o][#t.opt[o] + 1],o = arg[p]
			o = nil
		else
			t.arg, p = {unpack(arg,p)}, -1000
		end
		return fold(t, arg, p+1, o)
	end

	function parse(a, index)
		local t = {opt={}, arg={}}
		return fold(t, a or _G.arg, index or 1)
	end
end


return {
	parse = parse,
}
