


# slacklib

Nim-lang library for working with a slack app or sending messages to a slack channel

# General

This nim file was created with the purpose to control a Raspberry Pi 3.

The lib has 3 main purposes:

1. Responding to the `slack app verification` with the "challenge". This will verify you connection and is required by slack.
2. Accessing commands sent in the slack chat, parsing them and responding
3. Send messages using the incoming webhook app

# Prerequisites

## Slack account
Get a slack account (https://slack.com)

## Slack app
You need to build a slack app to communicate with.

1) Create a new slack app (https://api.slack.com/apps/new)
2) Add the permissions depending on your needs: Incoming webhooks, Slash commands, Permissions
3) Install the app to your team
4) Scopes: commands, incoming webhooks

## Router

You need to open the slackPort in your router to communicate with slack.

## Include slacklib in your code

### Imports

```nim
import asyncdispatch, asynchttpserver, slacklib
```

### Adjust slack port (optional)

Change the port (optional). Otherwise port 33556 is used.

```nim
slackPort = Port(65432)
```

### Add to your code

#### Proc

```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
```

#### Runner

Choose the prefeered option below: 

```nim
waitFor slackServer.serve(slackPort, slackServerRun)
```



```nim
asyncCheck slackServer.serve(slackPort, slackServerRun)
runForever()
```


## Compiler

When compiling and using the webhook, you need to include `-d:ssl` since the communication with slack is using HTTPS:

`nim c -d:ssl main.nim`


# Examples

All the examples using slackServerRun* requires you to activate it with either waitFor or asyncCheck.

Please be aware, that when sending commands from you channel, the channel awaits a response. You always need to respond to a command.

## Change port
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Standard port is been used. To change it:
  slackPort = Port(3000)
```

## Verify your app connection
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Verify you app connection. This is a one-timer, only use it for verifing connection to your app
  slackVerifyConnection(slackReq) 
```

## Access the request as string
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Access the event as a string
  echo slackEventString(slackReq)
```

## Access the request as a JsonNode
```nim
import json

proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Access the event as a JsonNode
  echo slackEventJson(slackReq)
  echo slackEventJson(slackReq)["command"].getStr
```

## Access the request as a Json value
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Access a value from the event as a string
  echo slackEvent(slackReq, "command")
```

## Access the request as a Request
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Access the event as a Request
  #[
    Request = object
      client*: AsyncSocket
      reqMethod*: HttpMethod
      headers*: HttpHeaders
      protocol*: tuple[orig: string, major, minor: int]
      url*: Uri
      hostname*: string
      body*: string
  ]#
  echo $slackReq.body
```


## Case the command and respond appropriate
```nim
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Case the command
  # slackEvent always return a string, use slackEventJson(slackReq)["someField"].xxx to access in other types

  case slackEvent(slackReq, "command"):
  of "/arm": 
    # If you need to run a proc with the arguments sent, access the 'text' field:
    echo slackEvent(slackReq, "text")
    await slackRespond(slackReq, slackMsg("#general", "nimslack", "ARMED", "", "warning", "Alarm Update", "The alarm has been armed"))

  of "/disarm":
    echo "DISARMED"
    await slackRespond(slackReq, slackMsg("#general", "nimslack", "DISARMED", "", "good", "Alarm Update", "The alarm has been disarmed"))

  else:
    await slackRespond(slackReq, slackMsg("#general", "nimslack", "ERROR", "", "danget", "Alarm Update", "That command is not part of me"))   
```


## Send a message using the webhook (async)

Just sending a command using the webhook, can be performed anywhere in your code

```nim
# A message can be sent from anywhere in you code, with this command
# It is a requirement, that you have defined the the var 'slackIncomingWebhookUrl' first
asyncCheck slackSend(slackMsg("#general", "nimslack", "Hi dude", "", "good", "Sup?", "Just sending a message"))
```

## Send a message using the webhook (sync)

Just sending a command using the webhook, can be performed anywhere in your code.

This method does not utilize the async - it is synchronous.

It returns the Reponse.body as a string.

```nim
# A message can be sent from anywhere in you code, with this command
# It is a requirement, that you have defined the the var 'slackIncomingWebhookUrl' first
let msgResponse = slackSendSyn(slackMsg("#general", "nimslack", "Hi dude", "", "good", "Sup?", "Just sending a message"))
echo msgResponse
```

## Prepare constants with predefined messages
```nim
# Already know you messages? Prepare them as constants (in the top):
const msgOn = slackMsg("nimslack", "Alarms is turned on", "good", "Alarm Update", "The controller has been turned on")

# A message can be sent from anywhere in you code, with this command
# It is a requirement, that you have defined the the var 'incomingWebhookUrl' first
asyncCheck slackSend(msgOn)
```
