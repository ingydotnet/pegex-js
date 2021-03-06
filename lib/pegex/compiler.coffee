require '../pegex/parser'
require '../pegex/pegex/grammar'
require '../pegex/pegex/ast'
require '../pegex/grammar/atoms'

class Pegex.Compiler
  constructor: ->
    @tree = null
    @_tree = null

  compile: (input)->
    @parse input
    @combinate()
    @native()
    @

  parse: (input)->
    parser = new Pegex.Parser
      grammar: new Pegex.Pegex.Grammar
      receiver: new Pegex.Pegex.AST
    @tree = parser.parse input
    @

  combinate: (rule)->
    rule ?= @tree['+toprule']
    return @ unless rule
    @_tree = {}
    for k, v of @tree when k.match /^\+/
      @_tree[k] = v
    @combinate_rule rule
    @tree = @_tree
    delete @_tree
    @

  combinate_rule: (rule)->
    return if @_tree[rule]?
    object = @_tree[rule] = @tree[rule]
    @combinate_object object

  combinate_object: (object)->
    if object['.sep']?
      @combinate_object object['.sep']
    if object['.rgx']
      @combinate_re object
    else if object['.ref']?
      rule = object['.ref']
      if @tree[rule]?
        @combinate_rule rule
      else
        if regex = Pegex.Grammar.Atoms::atoms()[rule]
          @tree[rule] = '.rgx': regex
          @combinate_rule rule
    else if object['.any']?
      for elem in object['.any']
        @combinate_object elem
    else if object['.all']?
      for elem in object['.all']
        @combinate_object elem
    else if object['.err']
      1
    else
      throw "Can't combinate: #{object}"
    @

  combinate_re: (regexp)->
    atoms = Pegex.Grammar.Atoms::atoms()
    re = regexp['.rgx']
    loop
      re = re.replace /<([-\w]+)>/, (m, $1) =>
        key = $1.replace /-/g, '_'
        if @tree[key]?
          if @tree[key]['.rgx']?
            @tree[key]['.rgx']
          else if @tree[key]['.ref']?
            "<#{@tree[key]['.ref']}>"
          else
            throw "'#{key}' not defined as a single RE"
        else if atoms[key]?
          atoms[key]
        else
          throw "'#{$1}' not defined in the grammar"
      break if re == regexp['.rgx']
      regexp['.rgx'] = re

  native: ->
    # XXX precompilation not working yet
    # @js_regexes @tree
    @

  js_regexes: (node)->
    if typeof node == 'object'
      if node instanceof Array
        @js_regexes elem for elem in node
      else
        if node['.rgx']?
          re = node['.rgx']
          node['.rgx'] = new RegExp "^#{re}"
        else
          for key, value of node
            @js_regexes value

  to_yaml: ->
    throw "Pegex.Compiler.to_yaml not yet defined"

  to_json: ->
    JSON.stringify @tree

  to_js: ->
    (require 'util').format @tree

# vim: sw=2:
