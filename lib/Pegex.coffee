###
name:      Pegex
abstract:  Acmeist PEG Parsing Framework
author:    Ingy döt Net <ingy@ingy.net>
license:   MIT
copyright: 2010-2015
###

class global.Pegex
  VERSION: '0.0.3'

require './Pegex/Parser'

exports.pegex = (grammar, receiver)->
  throw "Argument 'grammar' required in function 'pegex'" \
    unless grammar?
  if typeof grammar is 'string' or grammar instanceof Pegex.Input
    require './Pegex/Grammar'
    grammar = new Pegex.Grammar text: grammar
  if not receiver?
    require './Pegex/Tree/Wrap'
    receiver = new Pegex.Tree.Wrap
  else if typeof receiver is String
    receiver = require receiver
    receiver = new receiver
  new Pegex.Parser
    grammar: grammar
    receiver: receiver
