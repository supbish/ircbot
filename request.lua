--- User request. Bot commands run as methods of this class.
--- @classmod request

local request = {}

--- Reply to a request.
function request:reply(response) -- Response to reply with.
	return response and self.bot:send(("PRIVMSG %s :%s, %s"):format(self.channel, self.nick, response))
end

--- Quote something. Sanitizes a string for `exec`.
function request:quote(phrase) -- String to quote.
	return "'" .. phrase:gsub("'", "’") .. "'"
end

--- Execute a shell command.
function request:exec(shell) -- String to pass to shell.
	return io.popen(shell):read "*l"
end

--- Scrape a web page.
function request:fetch(url)
	local insecure = url:find "http://" == 1
	local web = insecure and require "socket.http" or require "ssl.https"
	local page, code, headers, status = web.request(url)
	if self.verbose then print(status, code, url) end
	-- follow redirects
	if code and code >= 300 and code < 400 and headers and headers.location then
		return self:fetch(headers.location)
	end 
	return page
end

--- Get command prefix pattern.
function request:getCommandPrefix(bot)
	return bot.nick .. "[%s%p]*"
end

return setmetatable({}, {
	__index = request,
	__call = function (self, bot, channel, nick, line)
		local command, arg = line:match("^" .. self:getCommandPrefix(bot) .. "(%S+)%s*(.-)%s*$")
		local f = command and rawget(self, command)
		if not f then return end
		
		local instance = setmetatable({ bot = bot, channel = channel, nick = nick }, { __index = self })
		return instance, instance:reply(f(instance, arg))
	end,
})

