# Description:
#   Tells a message to a user when they eventually show up. 
#
# Commands:
#   hubot tell <user> <something>
#
# Examples:
#   hubot tell wiredfool he isn't here
#    
# Author:
#   wiredfool


clean = (thing) ->
  (thing || '').toLowerCase().trim()
dbg = (thing) ->
  console.log thing

is_pm = (msg) ->
  try
    msg.message.user.pm
  catch error
    false

ircname = (msg) ->
  try
    msg.message.user.name
  catch error
    false

ircchan = (msg) ->
  try
    dbg msg.message.user.room
    msg.message.user.room
  catch error
    false        

class Tell
  constructor: (@robot) ->
    @cache = {}

    @robot.brain.on 'loaded', @load
    if @robot.brain.data
      @load()  
    
  load: ->
    if @robot.brain.data.tell
      @cache = @robot.brain.data.tell
    else
      @robot.brain.data.tell = @cache

  add: (user, message) ->
    dbg "tell.add #{clean user} #{message}"
    @cache[clean user] = message

  get: (user) ->
    @cache[clean user] ? ""

  clear: (user) ->
    delete @cache[clean user]

module.exports = (robot) ->
  tell = new Tell robot
  
  robot.hear /.*/, (msg) ->
    message = tell.get(ircname msg)
    if message
      msg.send "#{ircname msg}: #{message}"
      tell.clear(ircname msg)
      
  robot.respond /tell @?([-\w._]+):? (.*)/, (msg) ->
    dbg "tell #{msg.match[1]} #{msg.match[2]}"
    nick = msg.match[1]
    message = msg.match[2]
    #gonna avoid loops right now. 
    return if nick is robot.name 
    if nick and message
      tell.add nick, "#{ircname msg} said #{message} on #{new Date()}"
      dbg "added message #{ircname msg} said #{message} on #{new Date()}"
      msg.send "I'll pass that along" 