require '../pegex'

class Pegex.Grammar
  constructor: (_ = {})->
    {@file, @text, @tree} = _
    @make_tree
    @

  make_tree: ->
    return @tree if @tree?
    if ! @text?
      if @file?
        require 'fs'
        @text = fs.readFileSync(@file).toString()
      else
        throw "Can't create a grammar. No tree or text or file."
    require '../pegex/compiler'
    compiler = new Pegex.Compiler
    @tree = compiler.compile(@text).tree

  # TODO later
  # compile_into_module: (module)->
