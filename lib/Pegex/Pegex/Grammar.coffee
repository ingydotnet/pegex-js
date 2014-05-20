require '../../Pegex/Grammar'

global.Pegex.Pegex ?= ->
global.Pegex.Pegex.Grammar = exports.Grammar = class Grammar extends Pegex.Grammar

  text: ->
    '../pegex-pgx/pegex.pgx'

  make_tree: ->
    {
       "+grammar" : "pegex",
       "+toprule" : "grammar",
       "+version" : "0.1.0",
       "all_group" : {
          "+min" : 1,
          ".ref" : "rule_part",
          ".sep" : {
             ".rgx" : "(?:\\s|\\#.*\\n)*"
          }
       },
       "any_group" : {
          "+min" : "2",
          ".ref" : "rule_part",
          ".sep" : {
             ".rgx" : "(?:\\s|\\#.*\\n)*\\|(?:\\s|\\#.*\\n)*"
          }
       },
       "bracketed_group" : {
          ".all" : [
             {
                ".rgx" : "(\\.?)\\((?:\\s|\\#.*\\n)*"
             },
             {
                ".ref" : "rule_group"
             },
             {
                ".rgx" : "(?:\\s|\\#.*\\n)*\\)((?:[\\*\\+\\?]|[0-9]+(?:\\-[0-9]+|\\+)?)?)"
             }
          ]
       },
       "ending" : {
          ".rgx" : "(?:\\s|\\#.*\\n)*?(?:\\n(?:\\s|\\#.*\\n)*|;(?:\\s|\\#.*\\n)*|$)"
       },
       "error_message" : {
          ".rgx" : "`([^`\\r\\n]*)`"
       },
       "grammar" : {
          ".all" : [
             {
                ".ref" : "meta_section"
             },
             {
                ".ref" : "rule_section"
             }
          ]
       },
       "meta_definition" : {
          ".rgx" : "%(grammar|extends|include|version)[\\ \\t]+[\\ \\t]*([^;\\n]*?)[\\ \\t]*(?:\\s|\\#.*\\n)*?(?:\\n(?:\\s|\\#.*\\n)*|;(?:\\s|\\#.*\\n)*|$)"
       },
       "meta_section" : {
          "+min" : 0,
          ".any" : [
             {
                ".ref" : "meta_definition"
             },
             {
                ".rgx" : "(?:\\s|\\#.*\\n)+"
             }
          ]
       },
       "regular_expression" : {
          ".rgx" : "/([^/]*)/"
       },
       "rule_definition" : {
          ".all" : [
             {
                ".ref" : "rule_start"
             },
             {
                ".ref" : "rule_group"
             },
             {
                ".ref" : "ending"
             }
          ]
       },
       "rule_group" : {
          ".any" : [
             {
                ".ref" : "any_group"
             },
             {
                ".ref" : "all_group"
             }
          ]
       },
       "rule_item" : {
          ".any" : [
             {
                ".ref" : "rule_reference"
             },
             {
                ".ref" : "regular_expression"
             },
             {
                ".ref" : "bracketed_group"
             },
             {
                ".ref" : "whitespace_token"
             },
             {
                ".ref" : "error_message"
             }
          ]
       },
       "rule_part" : {
          "+max" : "2",
          "+min" : "1",
          ".ref" : "rule_item",
          ".sep" : {
             ".rgx" : "(?:\\s|\\#.*\\n)+(%{1,2})(?:\\s|\\#.*\\n)+"
          }
       },
       "rule_reference" : {
          ".rgx" : "([!=\\+\\-\\.]?)(?:([a-zA-Z]\\w*\\b)|(?:<([a-zA-Z]\\w*\\b)>))((?:[\\*\\+\\?]|[0-9]+(?:\\-[0-9]+|\\+)?)?)(?![\\ \\t]*:)"
       },
       "rule_section" : {
          "+min" : 0,
          ".any" : [
             {
                ".ref" : "rule_definition"
             },
             {
                ".rgx" : "(?:\\s|\\#.*\\n)+"
             }
          ]
       },
       "rule_start" : {
          ".rgx" : "([a-zA-Z]\\w*\\b)[\\ \\t]*:(?:\\s|\\#.*\\n)*"
       },
       "whitespace_token" : {
          ".rgx" : "(\\~+)"
       }
    }
