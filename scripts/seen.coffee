# Description:
#   When was someone last seen, and where
#
# Commands:
#   .seen <user>
#
# Examples:
#   .seen wiredfool
#    wiredfool was last seen in #joiito on <date>
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

class Seen
  constructor: (@robot) ->
    @cache = {}
        
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.seen
        @cache = @robot.brain.data.seen
      else
        @robot.data.brain.seen = @cache
      dbg @robot.brain.data.seen
            
#    save: ->
#        @robot.data.brain.seen = @cache
#        dbg "saving seen"
#        dbg @robot.data.brain.seen

  add: (user, channel) ->
    dbg "seen.add #{clean user} on #{channel}"
    #@cache[clean user] = {c:channel, d:new Date() - 0}
        #@save()

  last: (user) ->
    @cache[clean user] ? {}

module.exports = (robot) ->
  seen = new Seen robot

  robot.hear /.*/, (msg) ->
    unless is_pm msg
      seen.add (ircname msg), (ircchan msg)

  robot.hear /^([-\w-]+\s)?\.seen @?([-\w._]+):?/, (msg) ->
    dbg "seen check #{clean msg.match[2]}"
    nick = msg.match[2]
    last = seen.last nick
    if last.d
      msg.send "#{nick} was last seen in #{last.c} at #{new Date(last.d)}"
    else
      msg.send "I haven't seen #{nick} around lately"
      