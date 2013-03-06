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
#   ?karma <thing> - check thing's karma
# 
# Author:
#   stuartf as munged by wiredfool

is_pm = (msg) ->
  try
    msg.message.user.pm
  catch error
    false


class Karma
  
  constructor: (@robot) ->
    @cache = {}
    
    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]
  
    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]
    
    @robot.brain.on 'loaded', @load
    if @robot.brain.data.users.length
      @load()  
    
  load: =>
    if @robot.brain.data.karma
      @cache = @robot.brain.data.karma
    else
      @robot.brain.data.karma = @cache
      
  kill: (thing) ->
    delete @cache[thing]
  
  increment: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] += 1

  decrement: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] -= 1
  
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
    return if is_pm msg
    subject = msg.match[1].toLowerCase()
    karma.increment subject
  
  robot.hear /(\S+[^-\s])--(\s|$)/, (msg) ->
    return if is_pm msg
    subject = msg.match[1].toLowerCase()
    karma.decrement subject
  
  robot.hear /\?karma (\S+[^\s])$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match is "chameleon"
      msg.send "https://www.youtube.com/watch?v=JmcA9LIIXWw"
    else
      msg.send "#{match} has #{karma.get(match)} points."
  
