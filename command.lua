
-- irc bot commands

return function (bot, channel, nick, line)

	-- helper stuff
	local function command(c, f) local a = line:match("^!" .. c .. "%s*(.-)%s*$") return a and f(a) end
	local function admin(c, f) return nick == bot.owner and command(c, f) end
	local function reply(r) return r and bot:send(("PRIVMSG %s :%s, %s"):format(channel, nick, r)) end
	local function quote(q) return "'" .. q:gsub("'", "’") .. "'" end
	local function exec(c) return io.popen(c):read "*l" end
	
	-- public commands
	
	command("help", function()
		reply "what's wrong?"
	end)

	command("ip", function(host)
		reply(exec("host " .. quote(host)))
	end)

	command("temp", function(query)
		local m = bot:fetch("https://forecast.weather.gov/zipcity.php?inputstring=" .. query):match "%d+&deg;[FC]"
		reply(m and ("it's " .. m:gsub("&deg;", "°")) or "try a US zip or airport code")
	end)

	command("define", function(word)
		reply(bot:fetch("https://www.dictionary.com/browse/" .. word):match 'definition, (.-) See more."')
	end)

	command("roll", function(what)
		local dice, sides = what:match "^(%d+)d(%d+)$"
		dice, sides = tonumber(dice), tonumber(sides)
		if dice == 1 then return reply("rolled " .. math.random(sides)) end
		if not dice or dice < 1 or dice > 10 or sides < 2 or sides > 100 then
			return reply "try !roll 1d6"
		end

		local rolls, total = {}, 0
		for i = 1, dice do
			rolls[i] = math.random(sides)
			total = total + rolls[i]
		end
		reply(("rolled %i = (%s)"):format(total, table.concat(rolls, " + ")))
	end)

	command("choose", function(choices)
		local t = {}
		for s in choices:gmatch "%S+" do t[#t + 1] = s end
		reply(t[math.random(#t)])
	end)

	-- admin commands

	admin("raw", function(command)
		bot:send(command)
	end)

	admin("reload", function()
		bot:reload()
		reply "done"
	end)

	admin("die", function()
		reply "bye"
		os.exit()
	end)

end

