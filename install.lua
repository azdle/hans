local ct = json.parse(request.body)

if type(ct.oauthId) == "string" then
	storage.hipchat_auth = request.body
else
	error("Got something without oauthId.")
end