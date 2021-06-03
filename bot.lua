--- Core functionality for IRC bot.
--- Singleton class initted from shell args. Connects to IRC, handles main loop, and manages hot reload.
--- @classmod bot

local bot = {
	--- Whether to log detailed info to stdout.
	verbose = true,
	--- List of modules to reload on `bot:reload` command.
	modules = { "bot", "command", "request" },
	--- List of bot fields to persist on `bot:reload` command.
	persisted = { "server", "nick", "channel", "owner", "connecting", "socket" },
	--- Is the bot connecting to a server?
	connecting = false,
	--- Server domain.
	server = nil,
	--- IRC handle to use for bot.
	nick = nil,
	--- IRC channel to join.
	channel = nil,
	--- Bot operator's IRC handle.
	owner = nil,
	--- IRC socket.
	socket = nil,
}

--- Main entrypoint; shell args are passed in here.
function bot:init(
		server, -- Server domain.
		nick, -- IRC handle to use for bot.
		channel, -- IRC channel to join.
		owner -- Bot operator's IRC handle.
	)
	self.server, self.nick, self.channel, self.owner = server, nick, channel, owner
	self:connect()
	self:run()
end

--- Main loop.
function bot:run()
	if not xpcall(function ()
		while self:receive() do self = self.replacement or self end
	end, print) then return self:run() end 
end

--- Reload all modules listed in `bot.modules`.
function bot:reload()
	for _, v in ipairs(self.modules) do package.loaded[v] = nil end
	self.replacement = require "bot"
	for _, v in ipairs(self.persisted) do self.replacement[v] = self[v] end
end

--- Connect to IRC.
function bot:connect()
	self.socket = require "socket" .tcp()
	self.socket:connect( require "socket" .dns.toip(self.server), 6667)
	self.connecting = true

	self:send("USER " .. self.nick .. " 0 * :" .. self.nick)
	self:send("NICK " .. self.nick)
end

--- Send a raw IRC command.
function bot:send(content) -- Raw IRC command to send, without terminating line breaks.
	if self.verbose then print("<<<", content) end
	self.socket:send(content .. "\r\n\r\n")
end

--- Receive data from IRC.
--- @return Data received from IRC, or nil on failure.
--- @return Error message on failure.
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
	else
		local channel, line = received:match "^:[^:]+ PRIVMSG%s*(.-)%s*:(.*)"
		local nick = received:match "^:(.-)!"
		if line and nick then require "command" (self, channel, nick, line) end
	end
	return received, message
end

return bot

