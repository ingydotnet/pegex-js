require '../Pegex'

global.Pegex.Receiver = exports.Receiver = class Receiver
  constructor: (a = {})->
    {@wrap} = a
    @wrap ?= no

  flatten: (array, times) ->
    times ?= -1
    return array unless times--
    result = []
    for elem in array
      if elem instanceof Array
        result = result.concat @flatten elem, times
      else
        result.push elem
    result
