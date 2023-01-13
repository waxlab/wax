local html = {}

function html.encode(str)
	return str
		:gsub('&','&amp;')
		:gsub('<','&lt;')
		:gsub('>','&gt;')
		:gsub('"','&quot;')
		:gsub("'",'&apos;')
end


function html.decode(str)
	return str
		:gsub('&lt;',   '<')
		:gsub('&gt;',   '>')
		:gsub('&quot;', '"')
		:gsub('&apos;', "'")
		:gsub('&amp;',  '&')
end

return html
