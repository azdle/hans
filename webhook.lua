local event = json.parse(request.body)

if settings ~= nil then
	return 400, "Token Not Found"
end

function auth_token()
	return storage.auth_token
end

function send_pm(msg, user_id, notify)
	local body = json.stringify({
		message = msg,
		message_format = "text",
		notify = notify
	})
	
	local req = http.request{
		--url = "http://api.hipchat.com/v2/room/Notifications/reply?auth_token="..hipchat_auth,
		url = "https://api.hipchat.com/v2/user/"..user_id.."/message?auth_token="..auth_token(),
		method = "POST",
		headers = {
			["Content-Type"] = "application/json"
		},
		data = body
	}
end

function send_room_notification(msg, room_id, settings)
	local body = json.stringify({
		message = msg,
		message_format = "text",
		color = settings.color,
		notify = settings.notify
	})
	
	local req = http.request{
		url = "https://api.hipchat.com/v2/room/"..room_id.."/notification?auth_token="..auth_token(),
		method = "POST",
		headers = {
			["Content-Type"] = "application/json"
		},
		data = body
	}
end

function send_room_reply(msg, parent_msg_id, room_id)
	send_room_notification(msg, room_id, {})
	return
	--[[local body = json.stringify({
		message = msg,
		parentMessageId = parent_msg_id
	})
	
	local req = http.request{
		url = "https://api.hipchat.com/v2/room/"..room_id.."/reply?auth_token="..auth_token(),
		method = "POST",
		data = body
	}]]
end

function string.random(length)
  local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
	local clen = #charset
	local result = {}
	
	for loop = 1,length do
		local ran = math.random(1, #charset)
		table.insert(result, string.sub(charset, ran, ran))
	end

	return table.concat(result)
end

function table.has(table, item)
  local set = {}
  for _, l in ipairs(table) do set[l] = true end
  return set[item] == true
end

function table.indexof(table, item)
  local set = {}
  for k, v in pairs(table) do 
		if v == item then return k end
	end
end

function default(user_val, default_val)
	if user_val == nil then
		return default_val
	else
		return user_val
	end
end


-- Parse Command
local command = {}
for i in string.gmatch(event.item.message.message, "%S+") do
	table.insert(command, i)
end

log(command)
log(storage)

--TODO: Verify Request is From HipChat

if command[1] == "help" then
	if #command == 1 then
		send_room_reply(
			"I am the HipChat Automated Notification System. I can help you easily setup notification channels to subscribe to and HTTP endpoints to publish to."..
			"\r\nInstead of going through the hassle of creating your own HipChat API tokens that can only broadcast to an entire room, you can create a notification channel that will allow individuals to subscribe to only the alerts that they care about. The best part, all configuration is done from within this channel."..
			"\r\n"..
			"\r\nCommands:"..
			"\r\n    help - print this text"..
			"\r\n    create - create a notification channel"..
			"\r\n    delete - delete a notification channel"..
			"\r\n    list - list your notification channels"..
			"\r\n    publish - send a notification to your channel"..
			"\r\n    subscribe - subscribe yourself to a channel"..
			"\r\n    unsubscribe - unsubscribe yourself from a channel"..
			"\r\n    subscriptions - list the channels you're subscribed to"..
			"\r\n"..
			"\r\n Get more information for each with the command 'help <command>'.",
			event.item.message.id,
			event.item.room.id
		)
	else
		if command[2] == "create" then
			send_room_reply(
				"create <name> [<notify>] [<color>]"..
				"\r\n"..
				"\r\n    notify: true, false"..
				"\r\n    color: yellow, green, red, purple, gray, random"..
				"\r\n"..
				"\r\n    The notify setting determines whether users in the channel are alerted that"..
				"\r\n    a message has been posted to the channel or whether the message is just silently"..
				"\r\n    included into the room log.",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "list" then
			send_room_reply(
				"list",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "delete" then
			send_room_reply(
				"delete <name>",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "publish" then
			send_room_reply(
				"publish <name> <message - can include spaces>",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "subscribe" then
			send_room_reply(
				"subscribe <name> [<room name>]",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "subscribers" then
			send_room_reply(
				"subscribers <name>",
				event.item.message.id,
				event.item.room.id
			)
		elseif command[2] == "unsubscribe" then
			send_room_reply(
				"unsubscribe <name> [<room name>]",
				event.item.message.id,
				event.item.room.id
			)
		else
			send_room_reply(
				"I don't understand. Type 'help' for available commands.",
				event.item.message.id,
				event.item.room.id
			)
		end
	end
elseif command[1] == "create" then
	if #command > 4 or #command < 2 then
		send_room_reply(
			"Error: Bad Arg Count",
			event.item.message.id,
			event.item.room.id
		)
	else
		local new_key = string.random(20)
		local name = command[2]
		local notify
		local color
		
		if command[3] == 'true' then
			notify = true
		elseif command[3] == 'false' or command[3] == false then
			notify = false
		elseif table.has({'yellow', 'green', 'red', 'purple', 'gray', 'random'}, command[3]) then
		  color = command[3]
		end
		
		if command[4] == 'true' then
			notify = true;
		elseif command[4] == 'false' then
			notify = false;
		elseif table.has({'yellow', 'green', 'red', 'purple', 'gray', 'random'}, command[4]) then
		  color = command[4]
		end
		
		lease.acquire("chan_list")
		
		local chan_list = json.parse(storage.chan_list or "{}")
		
		if chan_list[name] ~= nil then
			send_room_reply(
				"Couldn't create channel "..name..". Name already exists.",
				event.item.message.id,
				event.item.room.id
			)
		else
			-- Update Channel List
			chan_list[name] = {
				notify = notify,
				color = color,
				owner = event.item.message.from.id,
				owner_name = event.item.message.from.name
			}
			
			storage.chan_list = json.stringify(chan_list)
			
			-- Update Key List
			lease.acquire("key_list")
			local key_list = json.parse(storage.key_list or "{}")
			
			key_list[new_key] = name
			
			storage.key_list = json.stringify(key_list)
			lease.release("key_list")
			
			send_room_reply(
				" Created notification \""..name..
				"\". You have a PM with a key.",
				event.item.message.id,
				event.item.room.id
			)
			send_pm(
				" Created notification \""..name..
				"\","..
				"\r\nTo use, POST to http://hans.webscript.io/publish?key="..new_key.." and the body will be posted as a notification.",
				event.item.message.from.id,
				true
			)
		end
		
		lease.release("chan_list")
	end
elseif command[1] == "list" then
	local chan_list = json.parse(storage.chan_list)
	local msg = ""
	log(json.stringify(chan_list))
	for name, settings in pairs(chan_list) do
		log(name)
		msg = msg..
		name.."("..settings.owner_name..")\r\n"
	end
	
	send_room_reply(
		msg,
		event.item.message.id,
		event.item.room.id
	)
elseif command[1] == "delete" then
	local name = command[2]
	local chan_list = json.parse(storage.chan_list)
	local settings = chan_list[name]

	if settings == nil then
		send_room_reply(
			"Couldn't find a channel named \""..name.."\".",
			event.item.message.id,
			event.item.room.id
		)
	elseif settings.owner ~= event.item.message.from.id then
		send_room_reply(
			"You don't seem to be the owner of \""..name..
			"\", only "..settings.owner_name.." can do that.",
			event.item.message.id,
			event.item.room.id
		)
	else
		lease.acquire("chan_list")
		local chan_list = json.parse(storage.chan_list or "{}")
		
		chan_list[name] = nil
		
		storage.chan_list = json.stringify(chan_list)
		
		-- Update Key List
		lease.acquire("key_list")
		local key_list = json.parse(storage.key_list or "{}")
		
		for key, kl_name in pairs(key_list) do
			if kl_name == name then
				key_list[key] = nil
			end
		end
		
		storage.key_list = json.stringify(key_list)
		lease.release("key_list")
		lease.release("chan_list")
			
		send_room_reply(
			"Channel \""..name.."\" deleted.",
			event.item.message.id,
			event.item.room.id
		)
	end
elseif command[1] == "publish" then
	local name = command[2]
	local chan_list = json.parse(storage.chan_list)
	local settings = chan_list[name]

	if settings == nil then
		send_room_reply(
			"Couldn't find a channel named \""..name.."\".",
			event.item.message.id,
			event.item.room.id
		)
	elseif settings.owner ~= event.item.message.from.id then
		send_room_reply(
			"You don't seem to be the owner of \""..name..
			"\", only "..settings.owner_name.." can do that.",
			event.item.message.id,
			event.item.room.id
		)
	else
		-- Just callout to the publish api endpoint.
		local key_list = json.parse(storage.key_list or "{}")
		log(storage.key_list)
		log(table.indexof(key_list, name))
		local req = http.request{
			url = "https://hans.webscript.io/publish"..
			      "?key="..table.indexof(key_list, name),
			method = "POST",
			data = table.concat(command, " ", 3)
		}
	end
elseif command[1] == "subscribe" then	
	lease.acquire("chan_list")
	local chan_list = json.parse(storage.chan_list or "{}")
	
	if #command == 2 and chan_list[command[2]] ~= nil then
		local subscribers = chan_list[command[2]].subscribers or {}
		
		if not table.has(subscribers, event.item.message.from.id) then
			table.insert(subscribers, event.item.message.from.id)
			chan_list[command[2]].subscribers = subscribers
			storage.chan_list = json.stringify(chan_list)
			
			send_room_reply(
				"Okay",
				event.item.message.id,
				event.item.room.id
			)
		else
			send_room_reply(
				"You're already subscribed to that.",
				event.item.message.id,
				event.item.room.id
			)
		end
	elseif #command == 3 and chan_list[command[2]] ~= nil then
		local subscribers = chan_list[command[2]].room_subscribers or {}
		
		if not table.has(subscribers, command[3]) then
			table.insert(subscribers, command[3])
			chan_list[command[2]].room_subscribers = subscribers
			storage.chan_list = json.stringify(chan_list)
			
			send_room_reply(
				"Okay",
				event.item.message.id,
				event.item.room.id
			)
		else
			send_room_reply(
				"Room already subscribed to that.",
				event.item.message.id,
				event.item.room.id
			)
		end
	else
		send_room_reply(
			"Couldn't find the channel "..tostring(command[2])..".",
			event.item.message.id,
			event.item.room.id
		)
	end
	lease.release("chan_list")
elseif command[1] == "subscriptions" then	
	local chan_list = json.parse(storage.chan_list or "{}")
	local subbed_chans = ""
	local count = 0
	
	for name, settings in pairs(chan_list) do
			
		if table.has(settings.subscribers or {},
				event.item.message.from.id) then
			subbed_chans = subbed_chans.."\n - "..tostring(name)
			count = count + 1
		end
	end
			
	send_room_reply(
		"You're subscribed to "..count.." channels."..subbed_chans,
		event.item.message.id,
		event.item.room.id
	)
elseif command[1] == "unsubscribe" then
	lease.acquire("chan_list")
	local chan_list = json.parse(storage.chan_list or "{}")
	
	if #command == 2 and chan_list[command[2]] ~= nil then
		local subscribers = chan_list[command[2]].subscribers or {}
		
		if table.has(subscribers, event.item.message.from.id) then
			local idx = table.indexof(subscribers, event.item.message.from.id)
			chan_list[command[2]].subscribers[idx] = nil
			storage.chan_list = json.stringify(chan_list)
			
			send_room_reply(
				"Okay",
				event.item.message.id,
				event.item.room.id
			)
		else
			send_room_reply(
				"You're not subscribed to that.",
				event.item.message.id,
				event.item.room.id
			)
		end
	elseif #command == 3 and chan_list[command[2]] ~= nil then
		local subscribers = chan_list[command[2]].room_subscribers or {}
		
		if table.has(subscribers, command[3]) then
			local idx = table.indexof(subscribers, command[3])
			chan_list[command[2]].room_subscribers[idx] = nil
			storage.chan_list = json.stringify(chan_list)
			
			send_room_reply(
				"Okay",
				event.item.message.id,
				event.item.room.id
			)
		else
			send_room_reply(
				"Room not subscribed to that.",
				event.item.message.id,
				event.item.room.id
			)
		end
	else
		send_room_reply(
			"Couldn't find the channel "..tostring(command[2])..".",
			event.item.message.id,
			event.item.room.id
		)
	end
	
	lease.release("chan_list")
end


return "OK"