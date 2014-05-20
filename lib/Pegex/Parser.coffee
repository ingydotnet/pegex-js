###
name:      Pegex.Parser
abstract:  Pegex Parser module
author:    Ingy döt Net <ingy@ingy.net>
license:   MIT
copyright: 2012
###

require '../Pegex/Input'
require '../Pegex/Receiver'

global.Pegex.Parser = exports.Parser = class Parser

  constructor: (@grammar, @receiver) ->
    @receiver ?= new Pegex.Receiver
    @throw_on_error = on
    @wrap = @receiver.wrap ? no
    @input = ''
    @buffer = ''
    @error = null
    @position = 0
    @farthest = 0
    @debug = Pegex.Parser.Debug ? off

  parse: (input, start_rule) ->
    # XXX Not sure why but sometimes start_rule is an Array
    if start_rule instanceof Array
      start_rule = start_rule.shift()
    @input = input
    if typeof @input == 'string'
      @input = new Pegex.Input {string: @input}
    @input.open()
    @buffer = @input.read()
    @grammar ?
      throw "No 'grammar'. Can't parse"

    if typeof @grammar == 'string'
      Grammar = require '../' + grammar
      @grammar = new Pegex.Grammar
    else
      @grammar.tree ?= @grammar.make_tree()

    start_rule ?= @grammar.tree?['+toprule'] ? do =>
      if @grammar.tree['TOP']
        'TOP'
      else
        throw "No starting rule for Pegex.Parser.parse"
    receiver = @receiver ?
      throw "No 'receiver'. Can't parse"
    if typeof receiver == 'string'
      require '../' + receiver
      @receiver = new receiver
    @receiver.parser = @

    match = @match start_rule
    return unless match

    @input.close()

    return @receiver.data || match

  match: (rule) ->
    @receiver.initialize rule if @receiver.constructor::initialize
    match = @match_next { '.ref': rule }
    if ! match or @position < @buffer.length
      @throw_error "Parse document failed for some reason"
      return
    match = match[0]
    match = @receiver.final match, rule if @receiver.constructor::final
    unless match
      match = {}
      match[rule] = []
    if rule == 'TOP'
      match = match['TOP'] ? match
    match

  get_min_max: (next) ->
    [min, max] = [ next['+min'], next['+max'] ]
    if min?
      if max?
        [min, max]
      else
        [min, 0]
    else
      if max?
        [0, max]
      else
        [1, 1]

  match_next: (next) ->
    return @match_next_with_sep next if next['.sep']

    [min, max] = @get_min_max next
    assertion = next['+asr'] ? 0
    keys = ['ref', 'rgx', 'all', 'any', 'err', 'code']
    for key in keys when next[".#{key}"]?
      kind = key
      rule = next[".#{key}"]

    [match, position, count, method] =
      [[], @position, 0, "match_#{kind}"]

    while return_ = @[method].call this, rule, next
      position = @position unless assertion
      count++
      match.push return_...
      break if max == 1

    if max != 1
      match = [ match ]
      @set_position position

    result = (count >= min and (not max or count <= max))
    result ^= (assertion == -1)

    @set_position position if not result or assertion

    match = [] if next['-skip']

    result && match || 0

  match_next_with_sep: (next) ->
    [min, max] = @get_min_max next
    keys = ['ref', 'rgx', 'all', 'any', 'err', 'code']
    for key in keys when next[".#{key}"]?
      kind = key
      rule = next[".#{key}"]
    separator = next['.sep']

    [match, position, count, method, scount, [smin, smax]] =
      [[], @position, 0, "match_#{kind}", 0, @get_min_max separator]

    while return_ = @[method].call this, rule, next
      position = @position
      count++
      match.push return_...
      break unless return_ = @match_next separator
      return2 = [ return_... ]
      if return2.length
        return2 = ['XXX'] if smax != 1
        match.push return2...
      scount++
    if max != 1
      match = [ match ]

    result = (count >= min and (not max or count <= max))
    @set_position position if count == scount and
      not separator['+eok']

    match = [] if next['-skip']
    return result && match || 0

  match_ref: (ref, parent) ->
    rule = @grammar.tree[ref]
    rule ||= if @::["match_rule_#{ref}"] then { '.code': ref } else
        throw "\n\n*** No grammar support for '#{ref}'\n\n"
    trace = not rule['+asr'] and @debug
    @trace "try_#{ref}" if trace

    match = if typeof rule == 'function' then rule.call @ else @match_next rule

    if match
      @trace "got_#{ref}" if trace
      if not rule['+asr'] and not parent['-skip']
        callback = "got_#{ref}"
        sub = @receiver.constructor.prototype[callback]
        if sub?
          match = [ sub.call @receiver, match[0] ]
        else if @wrap and not parent['-pass'] or parent['-wrap']
          if match.length
            value = match[0]
            match = [{}]
            match[0][ref] = value
          else
            match = []
    else
      @trace "not_#{ref}" if trace
      match = 0
    console.log match if match and @debug
    match

  xxx_terminator_hack: 0
  xxx_terminator_max: 1000
  match_rgx: (regexp, parent) ->
    start = @position
    if start >= @buffer.length and
      @xxx_terminator_hack++ > @xxx_terminator_max
        throw "Your grammar seems to not terminate at end or stream"
    re = new RegExp regexp, 'g'
    re.lastIndex = start
    m = re.exec @buffer
    # XXX Not sure how to match at 'start' position
    return 0 if not m? or m.index != start
    finish = re.lastIndex
    match = []
    for num in [1...(m.length)]
      match.push(m[num])
    match = [ match ] if m.length > 2
    @set_position finish
    return match

  match_all: (list, parent) ->
    pos = @position
    set = []
    len = 0
    for elem in list
      if match = @match_next elem
        continue if elem['+asr'] or elem['-skip']
        set.push match...
        len++
      else
        @set_position pos
        return 0
    set = [ set ] if len > 1
    return set

  match_any: (list, parent) ->
    for elem in list
      if match = @match_next elem
        return match
    return 0

  match_err: (error) ->
    @throw_error error

  match_code: (code) ->
    method = "match_rule_#{code}"
    method.call @

  set_position: (position) ->
    @position = position
    @farthest = position if position > @farthest

  trace: (action) ->
    indent = action.match /^try_/
    @indent ||= 1
    @indent-- unless indent
    i1 = i2 = ''
    i1 += ' ' for x in [0..@indent]
    i2 += ' ' for x in [1..(30 - action.length)]
    @indent++ if indent
    snippet = @buffer.substr @position
    snippet = snippet.substr 0, 30 if snippet.length > 30
    snippet = snippet.replace /\n/g, '\\n'
    console.warn "#{i1} #{action}#{i2}>#{snippet}<"

  throw_error: (msg) ->
    @format_error msg
    return 0 unless @throw_on_error
    throw @error

  format_error: (msg) ->
    position = @farthest
    lines = (@buffer.substr 0, position).match /\n/g
    line = if lines? then lines.length + 1 else 1
    column = position - @buffer.lastIndexOf "\n", position
    context = @buffer.substr position, 50
    context = context.replace /\n/g, '\\n'
    @error = """
Error parsing Pegex document:
  msg: #{msg}
  line: #{line}
  column: #{column}
  context: #{context}
  position: #{position}
"""
