--- User-defined commands.
--- Add your own commands here!
--- @classmod command

local command = require "request"

--- Public commands
--- @section public
	
--- Get help on available commands.
function command:help()
	return "oh no whats wrong"
end

--- Get IP address for a host.
function command:ip(host) -- Host domain to check.
	return self:exec("host " .. self:quote(host))
end

--- Get temperature.
function command:temp(code) -- US zip or airport code.
	local m = self:fetch("https://forecast.weather.gov/zipcity.php?inputstring=" .. code):match "%d+&deg;[FC]"
	return m and ("it's " .. m:gsub("&deg;", "°")) or "try a US zip or airport code"
end

--- Define a word.
function command:define(word) -- Word to define.
	return self:fetch("https://www.dictionary.com/browse/" .. word):match "definition, (.-) See more."
end

function command:imdb(query)
    local list = self:fetch("https://www.imdb.com/find?q=" .. query)
    local link = list and list:match("href=\"(/title/[^/]+/)%?")
    local page = link and self:fetch("https://www.imdb.com/" .. link)
    return page and page:match '<meta name="description" content="([^"]+)'
end

--- Roll some dice.
function command:roll(dice) -- Number of dice and sides. For example 2d6 to roll two six-sided dice.
	local d, s = dice:match "^(%d+)d(%d+)$"
	d, s = tonumber(d), tonumber(s)

	if not d or d < 1 or d > 10 or s < 2 or s > 100 then
		return "try !roll 2d6"
	end

	if d < 2 then return reply("rolled " .. math.random(s)) end

	local rolls, total = {}, 0
	for i = 1, d do
		rolls[i] = math.random(s)
		total = total + rolls[i]
	end
	return ("rolled %i = (%s)"):format(total, table.concat(rolls, " + "))
end

--- Choose something randomly.
function command:choose(choices)  -- A set of space-delimited choices.
	local t = {}
	for s in choices:gmatch "%S+" do t[#t + 1] = s end
	return "choose " .. t[math.random(#t)]
end

local eightballResponses = {
	"it is certain",
	"it is decidedly so",
	"without a doubt",
	"yes, definitely",
	"you may rely on it",
	"as I see it, yes",
	"most likely",
	"outlook good",
	"yes",
	"signs point to yes",
	"reply hazy try again",
	"ask again later",
	"better not tell you now",
	"cannot predict now",
	"concentrate and ask again",
	"don't count on it",
	"my reply is no",
	"my sources say no",
	"outlook not so good",
	"very doubtful",
}

--- Magic 8-ball.
function command:eightball()
	return eightballResponses[math.random(#eightballResponses)]
end

--- Admin commands
--- @section admin

--- Send a raw IRC command. Calls `bot:send`.
function command:raw(command) -- Raw IRC command to send, without terminating line breaks.
	if self.bot.owner ~= self.nick then return end
	self.bot:send(command)
end

--- Reload the bot. Calls `bot:reload`.
function command:reload()
	if self.bot.owner ~= self.nick then return end
	self.bot:reload()
	return "done"
end

--- Kill the bot.
function command:die()
	if self.bot.owner ~= self.nick then return end
	self:reply "bye"
	os.exit()
end

--- Evaluate Lua code.
function command:eval(code) -- Lua code to evaluate.
	if self.bot.owner ~= self.nick then return end
    return (_G.load or _G.loadstring)(
        "self, command, bot = ...; " .. code)(
            self, command, self.bot)
end

return command
