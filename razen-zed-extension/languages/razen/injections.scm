; Razen Language Code Injections
; Tree-sitter queries for injecting syntax highlighting into embedded code

; Inject JavaScript syntax into string literals that look like JavaScript code
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*function\\s*\\(.*\\).*[\"']$")
 (#set! injection.language "javascript"))

; Inject JSON syntax into string literals that look like JSON
((string_literal) @injection.content
 (#match? @injection.content "^[\"']\\s*[\\{\\[].*[\\}\\]]\\s*[\"']$")
 (#set! injection.language "json"))

; Inject SQL syntax into string literals that contain SQL keywords
((string_literal) @injection.content
 (#match? @injection.content "(?i)(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)")
 (#set! injection.language "sql"))

; Inject HTML syntax into string literals that look like HTML
((string_literal) @injection.content
 (#match? @injection.content "^[\"']\\s*<[^>]+>.*</[^>]+>\\s*[\"']$")
 (#set! injection.language "html"))

; Inject CSS syntax into string literals that look like CSS
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*\\{[^}]*:[^}]*\\}.*[\"']$")
 (#set! injection.language "css"))

; Inject regex syntax into string literals used with regex functions
((function_call
  name: (identifier) @function
  arguments: (argument_list (string_literal) @injection.content))
 (#any-of? @function "match" "search" "replace" "test")
 (#set! injection.language "regex"))

; Inject regex syntax into library calls that use regex
((library_call
  library: (identifier) @lib
  function: (identifier) @func
  arguments: (argument_list (string_literal) @injection.content))
 (#eq? @lib "Regex")
 (#any-of? @func "match" "search" "replace" "test")
 (#set! injection.language "regex"))

; Inject bash/shell syntax into system command strings
((function_call
  name: (identifier) @function
  arguments: (argument_list (string_literal) @injection.content))
 (#any-of? @function "execute" "system" "shell")
 (#set! injection.language "bash"))

; Inject bash syntax into system library calls
((library_call
  library: (identifier) @lib
  function: (identifier) @func
  arguments: (argument_list (string_literal) @injection.content))
 (#any-of? @lib "System" "SysLib" "OS")
 (#any-of? @func "execute" "command" "shell")
 (#set! injection.language "bash"))

; Inject markdown syntax into documentation strings
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*#{1,6}\\s+.*[\"']$")
 (#set! injection.language "markdown"))

; Inject YAML syntax into configuration strings
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*:\\s*.*[\"']$")
 (#set! injection.language "yaml"))

; Inject XML syntax into string literals that look like XML
((string_literal) @injection.content
 (#match? @injection.content "^[\"']\\s*<\\?xml.*\\?>.*[\"']$")
 (#set! injection.language "xml"))

; Support for embedded template languages
((string_literal) @injection.content
 (#match? @injection.content "\\$\\{.*\\}")
 (#set! injection.language "razen")
 (#set! injection.include-children))

; Inject appropriate syntax for file operations based on file extensions
((function_call
  name: (identifier) @function
  arguments: (argument_list 
    (string_literal) @filename
    (string_literal) @injection.content))
 (#eq? @function "write_file")
 (#match? @filename "\\.js[\"']$")
 (#set! injection.language "javascript"))

((function_call
  name: (identifier) @function
  arguments: (argument_list 
    (string_literal) @filename
    (string_literal) @injection.content))
 (#eq? @function "write_file")
 (#match? @filename "\\.json[\"']$")
 (#set! injection.language "json"))

((function_call
  name: (identifier) @function
  arguments: (argument_list 
    (string_literal) @filename
    (string_literal) @injection.content))
 (#eq? @function "write_file")
 (#match? @filename "\\.html?[\"']$")
 (#set! injection.language "html"))

((function_call
  name: (identifier) @function
  arguments: (argument_list 
    (string_literal) @filename
    (string_literal) @injection.content))
 (#eq? @function "write_file")
 (#match? @filename "\\.css[\"']$")
 (#set! injection.language "css"))

; Inject Python syntax for Python-like code blocks
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*def\\s+\\w+\\s*\\(.*\\):\\s*.*[\"']$")
 (#set! injection.language "python"))

; Inject Rust syntax for Rust-like code blocks
((string_literal) @injection.content
 (#match? @injection.content "^[\"'].*fn\\s+\\w+\\s*\\(.*\\).*\\{.*\\}.*[\"']$")
 (#set! injection.language "rust"))