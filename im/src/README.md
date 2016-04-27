Purpose:
=========

mod_push sends an API request to ZeroPush when a message is sent to an offline user.

The notification contains the following URI-encoded payload:

```json
{
	"from": "{sender-jid}",
	"to": "{recipient-jid}",
	"message": "{chat-message-body}"
}
```


