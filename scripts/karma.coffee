# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   ?karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#
# Author:
#   stuartf as munged by wiredfool

class Karma
  
  constructor: (@robot) ->
    @cache = {}
    
    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]
  
    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]
    
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma
  
  kill: (thing) ->
    delete @cache[thing]
    @robot.brain.data.karma = @cache
  
  increment: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] += 1
    @robot.brain.data.karma = @cache

  decrement: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] -= 1
    @robot.brain.data.karma = @cache
  
  incrementResponse: ->
     @increment_responses[Math.floor(Math.random() * @increment_responses.length)]
  
  decrementResponse: ->
     @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  get: (thing) ->
    k = if @cache[thing] then @cache[thing] else 0
    return k

  sort: ->
    s = []
    for key, val of @cache
      s.push({ name: key, karma: val })
    s.sort (a, b) -> b.karma - a.karma
  
  top: (n = 5) ->
    sorted = @sort()
    sorted.slice(0, n)
    
  bottom: (n = 5) ->
    sorted = @sort()
    sorted.slice(-n).reverse()
  
module.exports = (robot) ->
  karma = new Karma robot
  robot.hear /(\S+[^+\s])\+\+(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    karma.increment subject
    msg.send "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"
  
  robot.hear /(\S+[^-\s])--(\s|$)/, (msg) ->
    subject = msg.match[1].toLowerCase()
    karma.decrement subject
    msg.send "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"
  
  robot.hear /\?karma (\S+[^\s])$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match != "best" && match != "worst"
      msg.send "\"#{match}\" has #{karma.get(match)} karma."
  
