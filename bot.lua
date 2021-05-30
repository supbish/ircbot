--[[

	IRC Bot

	Inspired by https://github.com/davidshaw/ircbot.lua/blob/master/ircbot.lua
	Copyright (c) 2010, David Shaw; published under the BSD License.

]]--

local socket = require "socket" -- luasocket
local http = require "socket.http" -- luasocket http socket
local https = require "ssl.https" -- lua-sec https socket

local bot = {
	verbose = true, -- log detailed info to stdout
	modules = { "bot", "command", "launch" }, -- reload all these modules
	persisted = { "server", "nick", "channel", "owner", "connecting", "socket" }, -- persist these members on reload
}

-- main entrypoint, called from the launcher

function bot:init(server, nick, channel, owner)
	self.server, self.nick, self.channel, self.owner = server, nick, channel, owner
	self:connect()
	self:run()
end

-- main loop

function bot:run()
	if not xpcall(function ()
		while self:receive() do
			if self.replacement then self = self.replacement end
		end
	end, print) then return self:run() end 
end

-- hot reload all modules

function bot:reload()
	for _, v in ipairs(self.modules) do package.loaded[v] = nil end
	local replacement = require "bot"
	for _, v in ipairs(self.persisted) do replacement[v] = self[v] end
	self.replacement = replacement
end

-- connect to irc

function bot:connect()
	self.socket = socket.tcp()
	self.socket:connect(socket.dns.toip(self.server), 6667)
	self.connecting = true

	self:send("USER " .. self.nick .. " 0 * :" .. self.nick)
	self:send("NICK " .. self.nick)
end

-- send data to irc

function bot:send(content)
	if self.verbose then print("<<<", content) end
	self.socket:send(content .. "\r\n\r\n")
end

-- receive data from irc

function bot:receive()
	local received, message = self.socket:receive "*l"

	if self.verbose then print(">", received) end

	if self.connecting and received:match("^:" .. self.nick) then
		self:send("JOIN " .. self.channel)
		self.connecting = false
	-- ping / pong
	elseif received:match "^PING :" then
		self:send("PONG :" .. received:match "^PING :(.*)")
	-- chatter
	elseif received:match "^:[^:]+ PRIVMSG [^:]+:" then
		local channel, line = received:match "PRIVMSG%s*(.-)%s*:(.*)"
		local nick = received:match "^:(.-)!"
		if line and nick then
			require "command" (self, channel, nick, line)
		end
	end

	return received, message
end

-- scrape web

function bot:fetch(url)
	local insecure = url:find "http://" == 1
	local web = insecure and http or https
	local page, code, headers, status = web.request(url)
	if self.verbose then print(status, code, url) end
	-- follow redirects
	if code and code >= 300 and code < 400 and headers and headers.location then
		return self:fetch(headers.location)
	end 
	return page
end

return bot

