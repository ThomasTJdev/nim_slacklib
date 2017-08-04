#[
    Program: Slack app library for Nim-lang
    Author:  ThomasTJ (https://github.com/ThomasTJdev)
    License: MIT
]#      

## This library integrates the communication with a slack app
##
##
## Example
## -------
##
## .. code-block::nim
##    const msgArm = slackMsg("nimslack", "Alarms is turned on", "good", "Alarm Update", "The controller has been turned on")
##
##    proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
##      # To change the standard port:
##      slackPort = Port(3000)`
##
##      # Case the command
##      case slackEvent(slackReq, "command"):
##      of "/arm": 
##        # If you need to run a proc with the arguments sent, access the 'text' field:
##        echo slackEvent(slackReq, "text")
##        await slackRespond(slackReq, msgArm))
##
##      of "/disarm":
##        echo "DISARMED"
##        await slackRespond(slackReq, slackMsg("#general", "nimslack", "DISARMED", "", "good", "Alarm Update", "The alarm has been disarmed"))
##
##      else:
##        await slackRespond(slackReq, slackMsg("#general", "nimslack", "ERROR", "", "danget", "Alarm Update", "That command is not part of me"))  
##
##    waitFor slackServer.serve(slackPort, slackServerRun)


import
  strutils, asynchttpserver, asyncdispatch, json, cgi, httpclient


var
  slackServer* = newAsyncHttpServer()
  slackPort* = Port(33556)
  slackIncomingWebhookUrl*: string
  slackReq*: asynchttpserver.Request


proc slackMsg*(channel, username, fallback, pretext, color, title, value: string): string =
  ## Generate the slack message

  let jsonNode = 
    %*{"channel": channel, 
      "username": username,
      "attachments":[
            {
              "fallback":fallback,
              "pretext":pretext,
              "color":color,
              "fields":[
                  {
                    "title":title,
                    "value":value,
                    "short":false
                  }
              ]
            }
        ]
      }
  result = $jsonNode


proc slackSend*(msg: string) {.async.} =
  ## Sends the message as async
  ## Connections is closed after sending

  if slackIncomingWebhookUrl != nil:
    var clientSlack = newAsyncHttpClient()
    clientSlack.headers = newHttpHeaders({ "Content-Type": "application/json" })
    discard await clientSlack.request(slackIncomingWebhookUrl, httpMethod = HttpPost, body = msg)
    clientSlack.close()
  else:
    echo "Missing incoming webhook URL"


proc slackSendSync*(msg: string): string =
  ## Sends the message as sync
  ##
  ## Connections is closed after sending
  ##
  ## Returns the Response.body as a string

  if slackIncomingWebhookUrl != nil:
    var clientSlack = newHttpClient()
    clientSlack.headers = newHttpHeaders({ "Content-Type": "application/json" })
    let clientSlackReq = clientSlack.request(slackIncomingWebhookUrl, httpMethod = HttpPost, body = msg)
    clientSlack.close()
    return clientSlackReq.body
  else:
    echo "Missing incoming webhook URL"


proc slackVerifyConnection*(slackReq: asynchttpserver.Request) {.async.} =
  ## Grabs the value from field with value "challenge" and
  ## sending it right back to the client
  ##
  ## This is used to verify the connection to the slack app

  let headers = newHttpHeaders([("Content-Type","application/json")])
  let msg = %* {"challenge": parseJson(slackReq.body)["challenge"].getStr()}
  echo "Sending verification for connection"
  echo "Challenge: " & $msg
  await slackReq.respond(Http200, $msg, headers)


proc toJson(slackReq: asynchttpserver.Request): JsonNode =
  ## Parse the Request to JsonNode

  var json_string = ""
  for items in split(decodeUrl(slackReq.body), "&"):
    json_string.add("\"" & split(items, "=")[0] & "\": \"" & split(items, "=")[1] & "\",\n")
  let jsonNode = parseJson("{" & json_string[0 .. ^2] & "}")
  return jsonNode


proc slackEventString*(slackReq: asynchttpserver.Request): string =
  ## Decodes the Request and returns a string

  return decodeUrl(slackReq.body)


proc slackEventJson*(slackReq: asynchttpserver.Request): JsonNode =
  ## Return the Request as a JsonNode

  return toJson(slackReq)
  

proc slackRespond*(slackReq: asynchttpserver.Request, msg: string) {.async.} =
  ## Sending a message to slack. This is used for responding on
  ## incoming messages.

  let headers = newHttpHeaders([("Content-Type","application/json")])
  await slackReq.respond(Http200, msg, headers)


proc slackEvent*(slackReq: asynchttpserver.Request, jsonKey: string): string =
  ## Return the value from the specified jsonKey as a string

  return toJson(slackReq)[jsonKey].getStr()

#[
proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # Standard port is been used. To change it:
  slackPort = Port(3000)


  # Verify you app connection. This is a one-timer, only use it for verifying connection to your app
  #slackVerifyConnection(slackReq) 

  
  # Access the event in string
  echo slackEventString(slackReq)


  # Access the event in JSON
  echo slackEventJson(slackReq)


  # Access a value from the event as a string
  echo slackEvent(slackReq, "command")


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
    
  
  # A message can be sent from anywhere in you code, with this command
  # It is a requirement, that you have defined the the var 'slackIncomingWebhookUrl' first
  asyncCheck slackSend(slackMsg("#general", "nimslack", "Hi dude", "", "good", "Sup?", "Just sending a message"))


  # Already know you messages? Prepare them as constants (in the top):
  # const msgOn = slackMsg("nimslack", "Alarms is turned on", "good", "Alarm Update", "The controller has been turned on")
]#
