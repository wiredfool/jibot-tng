# Description:
#   Assign roles to people you're chatting with
#   rewritten by wiredfool for general defs and jibot syntax
#
# Commands:
#   ?learn <user> is <something> - assign something to a user
#   ?def <user> is <something> - like learn
#   ?forget <user> is <something> - remove something from a user
#   ?def <user> - see what user is
#   ?forgetme - forgets all defs for a user
#   ?hearldme - toggles heralding
#   
# Examples:
#   ?learn jeannie is the queen
#   ?forget jeannie is snoggs
#
# Author:
#   rewritten by wiredfool for general defs 

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
    if roles.length > 5
      "#{name} is #{roles.join(" & ")}."
    else if roles.length > 0
      "#{name} is #{roles.join(" and ")}."
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

class AKA
  # keeps a list of what aliases show up for what users
  # forward is alias -> user, supposedly one user per alias
  # reverse is user-> [alias,], where we expect more than one   
  constructor: (@robot) ->
    @cache = {forward:{},reverse:{}}
    
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.aka
        @cache = @robot.brain.data.aka
      else
        @robot.brain.data.aka = @cache

  save: ->
      @robot.brain.data.aka = @cache

  add: (user, alias) ->
    user = clean user
    alias = clean alias
    @cache.reverse[user] ?= []
    unless alias in @cache.reverse[user]
      @cache.reverse[user].push(alias)
      @cache.forward[alias] = user
      @save
      console.log("added alias #{alias} for #{user}")

  rm: (user, alias) ->
    user = clean user
    alias = clean alias
    if @cache.forward[alias] = user
      delete @cache.forward[alias]
      @cache.reverse[user] = (old for old in @cache.reverse[user] when old isnt alias)

  canonicalize: (name) ->
    @cache.forward[clean name] ? name
      
  whois: (name) ->
    @cache.reverse[clean name] ? []  
 
            
module.exports = (robot) ->
  defs = new Defs robot
  herald = new Herald robot
  aka = new AKA robot

  # start [botname one space] ?def <nick>
  # pms have botname prepended to the message 
  robot.hear /^([-\w_]+\s)?\?def @?([-\w._]+):?(.*)/i, (msg) ->
    name = msg.match[2].trim()
    dbg "def #{name}, '#{msg.match[3].trim().substr(0,2)}'"
    if msg.match[3].trim().length is 0
      dbg 'splaining'
      msg.send defs.render name

  # doubling the quotes to fix syntax highlighting. Shouldn't affect the regex 
  robot.hear /^([-\w-]+\s)?\?(learn|def) @?([-\w._]+):? is ([""''\w: -_]+)[.!]*$/i, (msg) ->
    dbg "learn|def"
    if is_pm msg
      msg.send "I don't change defs in private messages"
      return
    name    = msg.match[3].trim()
    newRole = msg.match[4].trim()

    unless name in ['', 'who', 'what', 'where', 'when', 'why']
      dbg 'setting def'
      defs.add_def name, newRole
      msg.send defs.render name

  robot.hear /^([-\w_]+\s)?\?forget @?([-\w._]+):? is ([""''\w: -_]+)[.!]*$/i, (msg) -> 
    if is_pm msg
      msg.send "I don't change defs in private messages"
      return

    name    = msg.match[2].trim()
    newRole = msg.match[3].trim()

    unless name in ['', 'who', 'what', 'where', 'when', 'why']
      if newRole in defs.get name
        dbg "forgetting role #{newRole}"
        defs.rm_def name, newRole
        msg.send defs.render name
      else
        msg.send "I knew that already."
      
  robot.hear /^([-\w_]+\s)?\?forgetme(\s|$)/i, (msg) ->
    if is_pm msg
      msg.send "I don't change defs in private messages"
      return
      
    name = ircname msg

    roles = defs.get name
    if not roles.length
      msg.send "I never knew anything about #{name}."
    else
      defs.clear_defs name
      msg.send "I don't know anything about #{name}." 


  #heralding for entering.    
  robot.enter (msg) ->
    name = ircname msg
    if herald.joined name
      roles = defs.get name
      if roles.length
        dbg "heralding #{name}"
        msg.send defs.render name
    
  robot.leave (msg) ->
    name = ircname msg
    herald.left name
    
  robot.hear /\?heraldme(\s|$)/i, (msg) ->
    name = ircname msg
    herald.toggle name
    actioning = 'ignoring'
    if herald.enabled name
      actioning = "heralding"
    msg.send "Now #{actioning} your entries"

  # adding an aka for people who switch names.
  robot.hear /\?aka @?([\w.-_]+):?/i, (msg) -> 
    name = msg.match[1].trim()
    akas = aka.whois name
    if akas.length
      msg.send "#{name} is also known as #{akas.join(', ')}"
    else
      msg.send "I don't have any info for #{name}"
    
  robot.catchAll (msg)->
    matches = msg.message.match /^nick: ([\w.-_]+) ([\w.-_]+)$/
    if matches
      oldnick = matches[1]
      newnick = matches[2]
      aka.add oldnick, newnick
