; Razen Language Runnable Code Detection
; Tree-sitter queries for identifying runnable code blocks in Razen

; Main function detection
(function_definition
  name: (identifier) @run
  (#eq? @run "main")) @runnable

; Test functions
(function_definition
  name: (identifier) @run
  (#match? @run "^test_.*")) @runnable

; Functions with specific runnable patterns
(function_definition
  name: (identifier) @run
  (#match? @run "^(run|execute|start|demo).*")) @runnable

; Script entry points based on document type
(document_type
  "type" @_type
  (document_kind) @kind
  (#any-of? @kind "script" "cli")) @runnable

; Functions that contain show statements (likely demo/example functions)
(function_definition
  body: (block
    (expression_statement
      (function_call
        name: (identifier) @show
        (#eq? @show "show"))))) @runnable

; Functions that read user input (interactive scripts)
(function_definition
  body: (block
    (expression_statement
      (function_call
        name: (identifier) @ask
        (#eq? @ask "ask"))))) @runnable

; Functions that perform file operations
(function_definition
  body: (block
    (expression_statement
      (function_call
        name: (identifier) @file_op
        (#any-of? @file_op "write_file" "read_file"))))) @runnable

; Functions that contain system calls
(function_definition
  body: (block
    (expression_statement
      (library_call
        library: (identifier) @lib
        function: (identifier) @func
        (#any-of? @lib "System" "SysLib" "OS")
        (#any-of? @func "execute" "command" "shell"))))) @runnable

; Functions that contain network operations
(function_definition
  body: (block
    (expression_statement
      (library_call
        library: (identifier) @lib
        function: (identifier) @func
        (#any-of? @lib "NetLib" "Http")
        (#any-of? @func "get" "post" "ping"))))) @runnable

; Standalone executable statements at top level
(expression_statement
  (function_call
    name: (identifier) @exec
    (#any-of? @exec "show" "ask" "write_file" "read_file"))) @runnable

; Top-level library calls that perform actions
(expression_statement
  (library_call
    library: (identifier) @lib
    function: (identifier) @func
    (#any-of? @func "execute" "run" "start" "play" "record"))) @runnable

; Functions that contain loops (likely processing functions)
(function_definition
  body: (block
    (while_loop))) @runnable

(function_definition
  body: (block
    (for_loop))) @runnable

; Functions that contain API calls
(function_definition
  body: (block
    (expression_statement
      (function_call
        name: (identifier) @api
        (#match? @api "^(api|call|get|post|connect).*"))))) @runnable

; Functions that work with audio/media
(function_definition
  body: (block
    (expression_statement
      (library_call
        library: (identifier) @lib
        function: (identifier) @func
        (#any-of? @lib "Audio" "Image")
        (#any-of? @func "play" "record" "load" "save"))))) @runnable

; Compiler/interpreter functions
(function_definition
  body: (block
    (expression_statement
      (library_call
        library: (identifier) @lib
        function: (identifier) @func
        (#any-of? @lib "CompLib" "Lexer" "Parser")
        (#any-of? @func "compile" "parse" "tokenize"))))) @runnable

; Functions that perform mathematical calculations
(function_definition
  body: (block
    (expression_statement
      (library_call
        library: (identifier) @lib
        function: (identifier) @func
        (#eq? @lib "MathLib")
        (#any-of? @func "calculate" "compute" "solve"))))) @runnable

; Database operation functions
(function_definition
  body: (block
    (expression_statement
      (function_call
        name: (identifier) @db
        (#match? @db "^(db|database|query|insert|update|delete).*"))))) @runnable

; Utility functions that are commonly run standalone
(function_definition
  name: (identifier) @util
  (#any-of? @util "setup" "init" "configure" "install" "build" "deploy")) @runnable