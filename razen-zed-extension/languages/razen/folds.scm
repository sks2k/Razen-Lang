; Razen Language Code Folding
; Tree-sitter queries for code folding in Razen

; Function definitions
(function_definition
  body: (block) @fold)

; Control flow blocks
(if_statement
  body: (block) @fold)

(else_clause
  body: (block) @fold)

(while_loop
  body: (block) @fold)

(for_loop
  body: (block) @fold)

; Try-catch blocks
(try_statement
  body: (block) @fold)

(catch_clause
  body: (block) @fold)

(finally_block
  body: (block) @fold)

; Class definitions
(class_definition
  body: (block) @fold)

; Object literals
(object_literal) @fold

; Array literals (multi-line)
(array_literal) @fold
(#set! fold.threshold 3)

; Block comments
(block_comment) @fold

; Multi-line strings
(string_literal) @fold
(#match? @fold "^[\"'].*\n.*[\"']$")

; Import/library blocks
(library_import) @fold
(#set! fold.threshold 2)

; Conditional blocks
(when_expression
  body: (block) @fold)

; Structure definitions
(struct_definition
  body: (block) @fold)

; Enum definitions
(enum_definition
  body: (block) @fold)

; Match expressions
(match_expression
  body: (block) @fold)

; Region markers (custom folding regions)
(comment) @fold.region.start
(#match? @fold.region.start "^#\\s*region\\b")

(comment) @fold.region.end
(#match? @fold.region.end "^#\\s*endregion\\b")