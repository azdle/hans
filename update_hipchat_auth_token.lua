-- Just manually store auth token for now. (Expires 12 Oct 2016)
storage.auth_token = ""

--[[
local username = ""
local password = ""


function url_encode(str)
	if (str) then
		--str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
			function (c)
				return string.format ("%%%02X", string.byte(c))
			end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

local body = 	{
	grant_type = "password",
	scope = "send_notification send_message",
	username = username,
	password = password
}

local user_pass = username..":"..password

local enc_body = ""

for key, value in pairs(body) do
	enc_body = enc_body..url_encode(tostring(key)).."="..url_encode(tostring(value)).."&"
end

print(enc_body)

local resp = http.request{
	url = "https://api.hipchat.com/v2/oauth/token",
	method = "POST",
	headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
	data = enc_body
}

if resp.statuscode ~= 200 then
	error("Error getting auth_token ("..
		tostring(resp.statuscode).."): "..resp.content)
end

local auth_table = json.parse(resp.content or {})

if type(auth_table.access_token) ~= 'string' then
	error("Couldn't get new auth token.")
end

storage.auth_token = new_auth.access_token
storage.auth_token_expires = auth_table.expires_in + os.time()
]]--
return "OK"