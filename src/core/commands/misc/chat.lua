local cmd = {
	name = script.Name,
	desc = [[Chat and display your identity]],
	usage = "$ chat",
	displayOutput = true,
	fn = function(plr, pCsi, essentials, args)
		-- THIS DOES NOT FILTER MESSAGES YET!!!!!!!!!!!!!!!!

		-- Comunicate over a bindable in Server Storage, support authentication and encryption peer to peer (first person to start)?
		local MessagingService = game:GetService("MessagingService")
		local topicname = "_xChat"..game.GameId
		local remote

		remote = game:GetService("ServerStorage"):WaitForChild("_xChat" .. game.JobId, 3)
			or Instance.new("BindableEvent", game:GetService("ServerStorage"))
		remote.Name = "_xChat" .. game.JobId

		local oldparse = pCsi.parseCommand

		local peers = {}
		local room = pCsi.libs.sha_256().updateStr(game.JobId .. table.concat(args)).finish().asHex()

		local NAME_COLORS = {
			Color3.new(253 / 255, 41 / 255, 67 / 255), -- BrickColor.new("Bright red").Color,
			Color3.new(1 / 255, 162 / 255, 255 / 255), -- BrickColor.new("Bright blue").Color,
			Color3.new(2 / 255, 184 / 255, 87 / 255), -- BrickColor.new("Earth green").Color,
			BrickColor.new("Bright violet").Color,
			BrickColor.new("Bright orange").Color,
			BrickColor.new("Bright yellow").Color,
			BrickColor.new("Light reddish violet").Color,
			BrickColor.new("Brick yellow").Color,
		}

		local function GetNameValue(pName)
			local value = 0
			for index = 1, #pName do
				local cValue = string.byte(string.sub(pName, index, index))
				local reverseIndex = #pName - index + 1
				if #pName % 2 == 1 then
					reverseIndex = reverseIndex - 1
				end
				if reverseIndex % 4 >= 2 then
					cValue = -cValue
				end
				value = value + cValue
			end
			return value
		end

		local color_offset = 0
		local function ComputeNameColor(pName)
			return NAME_COLORS[((GetNameValue(pName) + color_offset) % #NAME_COLORS) + 1]
		end


		local subscribeSuccess, subscribeConnection = pcall(function()
			return MessagingService:SubscribeAsync(topicname, function(message)
			local data = message.Data
			if not data.header or not data.player then
				return
			end

			local displayname = "<b>?</b>"
			if data.player then 
				local color = ComputeNameColor(data.player[2])
				displayname = '<b><font color="rgb('
				.. math.round(color.R * 255)
				.. ","
				.. math.round(color.G * 255)
				.. ","
				.. math.round(color.B * 255)
				.. ')">'
				.. data.player[2]
				.. "</font></b>"
			end
		

			if data.header == "startSession" and data.room == room then
				local text = displayname.." joined"

				pCsi.io.write(text)
			elseif data.header == "endSession" and data.room == room then
				local text = displayname.." left"

				pCsi.io.write(text)

				peers[data.player.UserId] = nil
			elseif data.header == "messageSession" and data.room == room and data.message then
				local text = "("..displayname.."): "
					.. data.message
						:gsub("&", "&amp;")
						:gsub("<", "&lt;")
						:gsub(">", "&gt;")
						:gsub('"', "&quot;")
						:gsub("'", "&apos;")
				pCsi.io.write(text)
			end
			end)
		end)


		local text = "Joined chatroom <b>" .. room:sub(1,18) .. "</b>, use '!q' to leave"
		pCsi.io.write(text)

		local function startSession(plra)
			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(topicname, {
					header = "startSession",
					room = room,
					player = {plra.UserId, plra.Name},
				})
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end
		local function endSession(plra)
			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(topicname, {
					header = "endSession",
					room = room,
					player = {plra.UserId, plra.Name},
				})
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end

		local function processMessage(player, message)
			local TextService = game:GetService("TextService")

			local textObject
			local success, errorMessage = pcall(function()
				textObject = TextService:FilterStringAsync(message, player.UserId)
			end)
			if not success then
				message = string.rep("_", #message)
			end

			local filteredMessage
			local success1, errorMessage2 = pcall(function()
				filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
			end)
			if success1 then
				message = filteredMessage
			else
				message = string.rep("_", #message)
			end

			local publishSuccess, publishResult = pcall(function()
				MessagingService:PublishAsync(topicname, {
					header = "messageSession",
					room = room,
					player = {player.UserId, player.Name},
					message = message,
				})
			end)
			if not publishSuccess then
				warn(publishResult)
			end
		end

		startSession(plr)
		function pCsi:parseCommand(...)
			input = { ... }
			local plra = input[1]
			table.remove(input, 1)
			input = table.concat(input)
			if input == "!quit" or input == "!q" then
				endSession(plra)

				pCsi.parseCommand = oldparse
			end
			if not plra == plr then
				pCsi.io.write(
					"This chat session is being used by <b>" .. plr.Name .. "</b>, consider ending the session? '!quit' "
				)
			end
			input = processMessage(plra, input)
		end
	end,
}

return cmd
