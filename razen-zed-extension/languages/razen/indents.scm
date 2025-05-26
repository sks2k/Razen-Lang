; Razen Language Indentation Rules
; Tree-sitter queries for auto-indentation in Razen

; Increase indentation after opening braces
(block "{" @indent)
(function_body "{" @indent)
(if_body "{" @indent)
(else_body "{" @indent)
(while_body "{" @indent)
(for_body "{" @indent)
(try_block "{" @indent)
(catch_block "{" @indent)
(finally_block "{" @indent)

; Decrease indentation before closing braces
(block "}" @outdent)
(function_body "}" @outdent)
(if_body "}" @outdent)
(else_body "}" @outdent)
(while_body "}" @outdent)
(for_body "}" @outdent)
(try_block "}" @outdent)
(catch_block "}" @outdent)
(finally_block "}" @outdent)

; Increase indentation after control flow keywords
(if_statement "if" @indent)
(while_loop "while" @indent)
(for_loop "for" @indent)
(function_definition "fun" @indent)

; Special indentation for else
(else_clause "else" @indent)

; Increase indentation after opening parentheses in multi-line contexts
(function_call "(" @indent)
(function_definition "(" @indent)

; Decrease indentation before closing parentheses
(function_call ")" @outdent)
(function_definition ")" @outdent)

; Increase indentation after opening square brackets in multi-line arrays
(array_literal "[" @indent)
(library_call "[" @indent)

; Decrease indentation before closing square brackets
(array_literal "]" @outdent)
(library_call "]" @outdent)

; Continue indentation for statement continuations
(binary_expression @indent.continue)
(string_concatenation @indent.continue)

; Handle line comments - don't change indentation
(comment @indent.none)

; Handle block comments - maintain current indentation
(block_comment @indent.none)