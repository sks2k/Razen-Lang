; Razen Language Text Objects
; Tree-sitter queries for text object selection in Razen

; Function text objects
(function_definition
  body: (_) @function.inside) @function.around

(function_call) @function.around

; Class text objects (if supported)
(class_definition
  body: (_) @class.inside) @class.around

; Block text objects
(block) @block.around
(block (_) @block.inside)

; Conditional text objects
(if_statement
  condition: (_) @conditional.inside
  body: (_) @conditional.inside) @conditional.around

(if_statement
  body: (_) @conditional.inside) @conditional.around

; Loop text objects
(while_loop
  condition: (_) @loop.inside
  body: (_) @loop.inside) @loop.around

(for_loop
  body: (_) @loop.inside) @loop.around

; Parameter text objects
(parameter_list) @parameter.around
(parameter_list (_) @parameter.inside)

(argument_list) @parameter.around
(argument_list (_) @parameter.inside)

; String text objects
(string_literal) @string.around
(string_literal (_) @string.inside)

(single_quoted_string) @string.around
(single_quoted_string (_) @string.inside)

; Array/List text objects
(array_literal) @list.around
(array_literal (_) @list.inside)

; Library call text objects
(library_call) @call.around
(library_call
  function: (_) @call.inside
  arguments: (_) @call.inside)

; Comment text objects
(comment) @comment.around
(block_comment) @comment.around
(comment (_) @comment.inside)
(block_comment (_) @comment.inside)

; Variable declaration text objects
(variable_declaration
  value: (_) @assignment.inside) @assignment.around

; Binary expression text objects
(binary_expression) @expression.around
(binary_expression
  left: (_) @expression.inside
  right: (_) @expression.inside)

; Map/Dictionary text objects
(map_literal) @map.around
(map_literal (_) @map.inside)

; Return statement text objects
(return_statement
  value: (_) @return.inside) @return.around

; Try-catch text objects
(try_statement
  body: (_) @exception.inside
  catch_clause: (_) @exception.inside) @exception.around

; Document type text objects
(document_type) @type.around

; Import/Library text objects
(library_import) @import.around

; Number text objects
(integer_literal) @number.around
(float_literal) @number.around
(hex_literal) @number.around
(binary_literal) @number.around