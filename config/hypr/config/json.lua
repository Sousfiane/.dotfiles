-- A small JSON decoder, enough for theme.json: objects, arrays, strings, numbers, true/false/null.
-- json.decode(text) returns the value, or raises an error saying where the text went wrong.

local json = {}

local escapes = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

-- the UTF-8 bytes of code point `c`
local function utf8char(c)
	if c < 0x80 then
		return string.char(c)
	elseif c < 0x800 then
		return string.char(0xC0 + math.floor(c / 0x40), 0x80 + c % 0x40)
	elseif c < 0x10000 then
		return string.char(0xE0 + math.floor(c / 0x1000), 0x80 + math.floor(c / 0x40) % 0x40, 0x80 + c % 0x40)
	end
	return string.char(
		0xF0 + math.floor(c / 0x40000),
		0x80 + math.floor(c / 0x1000) % 0x40,
		0x80 + math.floor(c / 0x40) % 0x40,
		0x80 + c % 0x40
	)
end

function json.decode(text)
	local pos = 1

	local function fail(what)
		local line = select(2, text:sub(1, pos):gsub("\n", "")) + 1
		error(("JSON: %s at line %d"):format(what, line), 0)
	end

	local function skip()
		pos = text:find("[^ \t\r\n]", pos) or #text + 1
	end

	local value

	local function str()
		pos = pos + 1 -- opening quote
		local out = {}
		while true do
			local c = text:sub(pos, pos)
			if c == "" then
				fail("unfinished string")
			elseif c == '"' then
				pos = pos + 1
				return table.concat(out)
			elseif c == "\\" then
				local e = text:sub(pos + 1, pos + 1)
				if e == "u" then
					local hex = text:sub(pos + 2, pos + 5)
					if not hex:match("^%x%x%x%x$") then fail("bad \\u escape") end
					out[#out + 1] = utf8char(tonumber(hex, 16))
					pos = pos + 6
				elseif escapes[e] then
					out[#out + 1] = escapes[e]
					pos = pos + 2
				else
					fail("bad escape")
				end
			else
				local stop = text:find('["\\]', pos) or #text + 1
				out[#out + 1] = text:sub(pos, stop - 1)
				pos = stop
			end
		end
	end

	local function list(open, close, item)
		pos = pos + 1 -- the opening bracket
		local out = {}
		skip()
		if text:sub(pos, pos) == close then
			pos = pos + 1
			return out
		end
		while true do
			item(out)
			skip()
			local c = text:sub(pos, pos)
			pos = pos + 1
			if c == close then return out end
			if c ~= "," then fail(("expected ',' or '%s'"):format(close)) end
			skip()
		end
	end

	function value()
		skip()
		local c = text:sub(pos, pos)
		if c == "{" then
			return list("{", "}", function(out)
				if text:sub(pos, pos) ~= '"' then fail("expected a key") end
				local k = str()
				skip()
				if text:sub(pos, pos) ~= ":" then fail("expected ':'") end
				pos = pos + 1
				out[k] = value()
			end)
		elseif c == "[" then
			return list("[", "]", function(out)
				out[#out + 1] = value()
			end)
		elseif c == '"' then
			return str()
		end
		for word, v in pairs({ ["true"] = true, ["false"] = false, ["null"] = json.null }) do
			if text:sub(pos, pos + #word - 1) == word then
				pos = pos + #word
				return v
			end
		end
		local num = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
		if num and num ~= "" and num ~= "-" then
			pos = pos + #num
			return tonumber(num)
		end
		fail("unexpected character '" .. c .. "'")
	end

	local result = value()
	skip()
	if pos <= #text then fail("text after the end") end
	return result
end

-- stands for JSON null (a nil would vanish from tables)
json.null = setmetatable({}, { __tostring = function() return "null" end })

return json
