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
#   ?forget holman is an ego surfer
#
# Author:
#   rewritten by wiredfool for general defs 

# undone -- privmessage flag. 
# 

clean = (thing) ->
  thing.toLowerCase().trim()
dbg = (thing) ->
  console.log thing

class Defs
  
  constructor: (@robot) ->
    @cache = {}

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.defs
        @cache = @robot.brain.data.defs

        
  add_def: (thing, def) ->
    thing = clean thing
    @cache[thing] ?= []
    unless def in @cache[thing]
      @cache[thing].push(def)
      @save

  save: ->
      @robot.brain.data.defs = @cache

  rm_def: (thing, def) ->
    thing = clean thing
    @cache[thing] ?= []
    @cache[thing] = (olddef for olddef in @cache[thing] when olddef isnt def)
    @save

  clear_defs: (thing) ->
    thing = clean thing
    @cache[thing]=[]
    @save

  get: (thing) ->
    thing = clean thing
    k = if @cache[thing] then @cache[thing] else []
    return k

  render: (name) ->
    thing = clean name
    roles = @get thing
    if roles.length > 0
      "#{name} is #{roles.join(", ")}."
    else
      "I don't know anything about #{name}."

class Herald 

  constructor: (@robot) ->
    @cache = {left:{},pref:{},last:{}}
    @threshold = 5*60*1000;
    
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.herald
        @cache = @robot.brain.data.herald
      else
        @robot.brain.data.herald = @cache

  save: ->
      @robot.brain.data.herald = @cache

  enabled: (user) ->
    @cache.pref[clean user] ? true

  toggle: (user) ->
    user = clean user
    @cache.pref[user] = !(@cache.pref[user] ? true)
    @save

  left: (user) ->
    # not saving, don't need this through a restart
    @cache.left[clean user] = new Date() - 0
    @save
    
  joined: (user) ->
    # Not heralding if the user came or left in the last threshold milliseconds
    # Prevents people from being heralded on a bounce, or on a netsplit. 
    user = clean user
    now = new Date() - 0
    last_left = @cache.left[user] || 0 
    last_joined = @cache.last[user] || 0
    dbg "herald.joined #{last_left} #{last_joined} #{now}"
    if (last_left + @threshold < now) and (last_joined + @threshold < now)
      # not saving, I don't need this through a restart
      dbg "we're good"
      @cache.last[user]=now
      dbg @cache.last
      @save
      true
    else
      dbg "too recent a herald/leave"
      false
    
module.exports = (robot) ->
  defs = new Defs robot
  herald = new Herald robot
  
  robot.hear /^\?def @?([\w.-]+):?(.*)/i, (msg) ->
    name = msg.match[1].trim()
    unless msg.match[2].trim().substr(0,2) is 'is'
      msg.send defs.render name

  # doubling the quotes to fix syntax highlighting. Shouldn't affect the regex 
  robot.hear /^\?(learn|def) @?([\w.-_]+):? is ([""''\w: -_]+)[.!]*$/i, (msg) -> 
    name    = msg.match[2].trim()
    newRole = msg.match[3].trim()

    unless name in ['', 'who', 'what', 'where', 'when', 'why']
      defs.add_def name, newRole
      msg.send defs.render name

  # syntax...
  robot.hear /\?forget @?([\w.-_]+):? is ([""''\w: -_]+)[.!]*$/i, (msg) -> 
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
      defs.clear_defs name
      msg.send "I don't know anything about #{name}." 


  #heralding for entering.    
  robot.enter (msg) ->
    name = msg.message.user.name
    if herald.joined name
      roles = defs.get name
      if roles.length
        msg.send defs.render name
    
  robot.leave (msg) ->
    name = msg.message.user.name
    herald.left name
    
  robot.hear /\?heraldme(\s|$)/i, (msg) ->
    name    = msg.message.user.name
    herald.toggle name
    actioning = 'ignoring'
    if herald.enabled name
      actioning = "heralding"
    msg.send "Now #{actioning} your entries"