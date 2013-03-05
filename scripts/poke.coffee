# Description:
#   Responds to pokes and other assaults
#
# Commands:
#   /me pokes hubot
#
# Examples:
#   /me pokes hubot
#   hubot: ouch
#
# Author
#   wiredfool


clean = (thing) ->
  (thing || '').toLowerCase().trim()
dbg = (thing) ->
  console.log thing

module.exports = (robot) ->

  # /me pokes robot.name
  #   
  robot.hear /^([-\w_]+\s)?action: ([-\w._]+) pokes ([-\w._]+)\s*$/, (msg)->
    if msg.match
      nick = msg.match[2]
      who = clean msg.match[3]
      dbg "poke #{nick} #{who}"
      if who is robot.name
        msg.send "Ouch"
