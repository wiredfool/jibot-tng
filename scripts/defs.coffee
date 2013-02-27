# Description:
#   Assign roles to people you're chatting with
#   rewritten by wiredfool for general defs and jibot syntax
#
# Commands:
#   ?learn <user> is a badass guitarist - assign a role to a user
#   ?forget <user> is a badass guitarist - remove a role from a user
#   ?def <user> - see what roles a user has
#   ?forgetme
#
# Examples:
#   ?learn holman is an ego surfer
#   ?forge tholman is an ego surfer
#
# Author:
#   rewritten by wiredfool for general defs 

# undone -- privmessage flag. 
# 

class Defs
  
  constructor: (@robot) ->
    @cache = {}

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.defs
        @cache = @robot.brain.data.defs

  clean: (thing) ->
    thing.toLowerCase().trim()
        
  add_def: (thing, def) ->
    thing = @clean thing
    @cache[thing] ?= []
    unless def in @cache[thing]
      @cache[thing].push(def)
      @robot.brain.data.defs = @cache

  rm_def: (thing, def) ->
    thing = @clean thing
    @cache[thing] ?= []
    @cache[thing] = (olddef for olddef in @cache[thing] when olddef isnt def)
    @robot.brain.data.defs = @cache

  clear_def: (thing) ->
    thing = @clean thing
    @cache[thing]=[]
    @robot.brain.data.defs = @cache

  get: (thing) ->
    thing = @clean thing
    k = if @cache[thing] then @cache[thing] else []
    return k

  render: (name) ->
    thing = @clean name
    roles = @get thing
    if roles.length > 0
      "#{name} is #{roles.join(", ")}."
    else
      "I don't know anything about #{name}."


module.exports = (robot) ->
  defs = new Defs robot

  robot.hear /^\?def @?([\w .-]+):?/i, (msg) ->
    name = msg.match[1].trim()
    msg.send defs.render name
    

  robot.hear /^\?learn @?([\w .-_]+):? is (["'\w: -_]+)[.!]*$/i, (msg) ->
    name    = msg.match[1].trim()
    newRole = msg.match[2].trim()

    unless name in ['', 'who', 'what', 'where', 'when', 'why']
      defs.add_def name, newRole
      msg.send defs.render name
      
  robot.hear /\?forget @?([\w .-_]+):? is (["'\w: -_]+)[.!]*$/i, (msg) ->
    name    = msg.match[1].trim()
    newRole = msg.match[2].trim()

    unless name in ['', 'who', 'what', 'where', 'when', 'why']
      if newRole in defs.get name 
        defs.rm_def name, newRole
        msg.send defs.render name
      else
        msg.send "I knew that already."
      
  robot.hear /\?forgetme(\s|$)/i, (msg) ->
    #msg.send msg.message.user.room # if privmsg, this is going to be ''
    #msg.send msg.message.user.name # if privmsg, then name == reply_to

    name    = msg.message.user.name
    msg.send "Trying to forget #{name}"

    roles = defs.get name
    if not roles.length
      msg.send "I never knew anything about #{name}."
    else
      defs.clear_def name
      msg.send "I don't know anything about #{name}." 
 
        

