return {
	name= "HANS: HipChat Automated Notification System",
	description= "Simple, subscribable notifications configured in chat.",
	key = "io.webscript.hans",
	vendor = {
		name = "Patrick Barrett",
		url = "https://mkii.org",
	},
	links = {
		homepage = "http://hans.webscript.io/",
		self = "https://hans.webscript.io/capabilities.json"
	},
	capabilities = {
		hipchatApiConsumer = {
			scopes = {
				"send_notification",
				"send_message",
				"view_messages"
			},
			fromName = "HANS"
		},
		installable = {
			callbackUrl = "https://hans.webscript.io/install"
		},
		webhook = {
			url = "https://hans.webscript.io/webhook",
			event = "room_message",
			name = "Talk to HANS"
		}
	}
}