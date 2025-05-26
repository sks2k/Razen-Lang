; Razen Language Bracket Matching
; Tree-sitter queries for bracket matching in Razen

; Parentheses
(function_call "(" @open ")" @close)
(function_definition "(" @open ")" @close)
(grouping_expression "(" @open ")" @close)
(if_statement "(" @open ")" @close)
(while_loop "(" @open ")" @close)
(for_loop "(" @open ")" @close)

; Square brackets
(array_literal "[" @open "]" @close)
(array_access "[" @open "]" @close)
(library_call "[" @open "]" @close)

; Curly braces
(block "{" @open "}" @close)
(function_body "{" @open "}" @close)
(if_body "{" @open "}" @close)
(else_body "{" @open "}" @close)
(while_body "{" @open "}" @close)
(for_body "{" @open "}" @close)
(try_block "{" @open "}" @close)
(catch_block "{" @open "}" @close)
(finally_block "{" @open "}" @close)

; String quotes
(string_literal "\"" @open "\"" @close)
(single_quoted_string "'" @open "'" @close)