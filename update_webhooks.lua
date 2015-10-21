local room_shim = json.stringify({807756, 808547})

lease.acquire('webhooks')

local rooms_to_hook = json.parse(storage.rooms_to_hook or room_shim)

local current_webhooks = json.parse(storage.current_webhooks or "{}")

-- Delete all Existing Webhooks
for _, w in ipairs(current_webhooks) do	
	local res = http.request{
		url = "https://api.hipchat.com/v2/room/"..w.room_id..
		       "/webhook/"..w.webhook_id..
		       "?auth_token="..storage.auth_token,
		method = "DELETE"
	}
end

current_webhooks = {}

-- Create all Needed Webhooks
for _, room in ipairs(rooms_to_hook) do
	local body = {
		url = "https://hans.webscript.io/webhook",
		event = "room_message",
		name = "Talk to HANS"
	}
	
	local res = http.request{
		url = "https://api.hipchat.com/v2/room/"..tostring(room)..
		       "/webhook"..
		       "?auth_token="..storage.auth_token,
		method = "POST",
		data = json.stringify(body)
	}
	
	if res.statuscode == 201 then
		local res_tbl = json.parse(res.content)
		
		table.insert(current_webhooks, {
				webhook_id = res_tbl.id,
				room_id = room
			})
	end
end

storage.current_webhooks = json.stringify(current_webhooks)

lease.release('webhooks')

