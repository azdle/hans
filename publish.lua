if request.method ~= "POST" then
	return 405, "Method Must Be POST"
end

if #request.body == 0 then
	return 400, "Body Must Not Be Empty"
end

local key = request.query.key

if key == nil then
	return 400, "Required parameter 'key' not found."
end

local chan_name = json.parse(storage.key_list or "{}")[key]

if chan_name == nil then
	return 400, "Token Not Found"
end

local settings = json.parse(storage.chan_list or "{}")[chan_name]

if settings == nil then
	return 500, "Key Found, But Channel Not Found"
end

-- Helpers
function auth_token()
	return storage.auth_token
end

function default(user_val, default_val)
	if user_val == nil then
		return default_val
	else
		return user_val
	end
end

function send_pm(msg, user_id, notify)
	local body = json.stringify({
		message = msg,
		message_format = "text",
		notify = notify
	})
	
	local req = http.request{
		url = "https://api.hipchat.com/v2/user/"..user_id..
		      "/message?auth_token="..auth_token(),
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
		url = "https://api.hipchat.com/v2/room/"..room_id..
		      "/notification?auth_token="..auth_token(),
		method = "POST",
		headers = {
			["Content-Type"] = "application/json"
		},
		data = body
	}
end

-- Main Code
local message = request.body

log(storage.chan_list)

-- Message Subscribed Users
for _, user_id in pairs(settings.subscribers or {}) do
	send_pm(message.." ("..chan_name..")",
		      user_id,
		      settings.notify)
end

-- Message Subscribed Rooms
for _, room_id in pairs(settings.room_subscribers or {}) do
	send_room_notification(message.." ("..chan_name..")",
		      room_id,
		      settings)
end

-- Log All Messaged to the HANS Room
settings.notify = false -- never notify HANS room
send_room_notification(message.." ("..chan_name..")",
	                     "808547",
	                     settings)

return "OK"