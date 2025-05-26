; Razen Language Tree-sitter Highlights
; Syntax highlighting queries for the Razen programming language

; Comments
(comment) @comment.line
(block_comment) @comment.block

; Document type declarations
(document_type 
  "type" @keyword.control
  (document_kind) @constant.language)

; Keywords
[
  "if"
  "else" 
  "elif"
  "while"
  "for"
  "return"
  "break"
  "continue"
  "when"
  "try"
  "catch"
  "throw"
  "finally"
  "in"
  "not"
  "and"
  "or"
] @keyword.control

; Function keyword
"fun" @keyword.function

; Variable declaration keywords
[
  "let"
  "take"
  "hold"
  "put"
  "sum"
  "diff"
  "prod"
  "div"
  "mod"
  "power"
  "is"
  "text"
  "concat"
  "slice"
  "len"
  "split"
  "trim"
  "replace"
  "find"
  "list"
  "arr"
  "append"
  "remove"
  "size"
  "clear"
  "map"
  "key"
  "value"
  "get"
  "set"
  "contains"
  "keys"
  "values"
  "current"
  "now"
  "year"
  "month"
  "day"
  "hour"
  "minute"
  "second"
  "store"
  "box"
  "ref"
  "show"
  "read"
  "write"
  "read_file"
] @storage.type

; Library import
(library_import
  "lib" @keyword.control.import
  (identifier) @entity.name.class)

; Constants
[
  "true"
  "false"
  "null"
] @constant.language

; Built-in functions
[
  "plus"
  "minus"
  "times"
  "by"
  "mod"
  "power"
  "round"
  "sqrt"
  "abs"
  "size"
  "join"
  "big"
  "small"
  "split"
  "replace"
  "trim"
  "find"
  "count"
  "add"
  "take"
  "clear"
  "sort"
  "reverse"
  "keys"
  "values"
  "contains"
  "remove"
  "get"
  "time"
  "date"
  "timestamp"
  "sleep"
  "say"
  "ask"
  "write"
  "read_file"
] @function.builtin

; Function definitions
(function_definition
  "fun" @keyword.function
  name: (identifier) @entity.name.function)

; Function calls
(function_call
  name: (identifier) @entity.name.function)

; Library function calls with bracket notation
(library_call
  library: (identifier) @entity.name.class
  "[" @punctuation.bracket
  function: (identifier) @entity.name.function
  "]" @punctuation.bracket)

; Variable names
(variable_declaration
  name: (identifier) @variable.other.definition)

(identifier) @variable.other

; Strings
(string_literal) @string.quoted.double
(single_quoted_string) @string.quoted.single

; String interpolation
(string_interpolation
  "${" @punctuation.special
  "}" @punctuation.special) @string.interpolated

; Numbers
(integer_literal) @constant.numeric.integer
(float_literal) @constant.numeric.float
(hex_literal) @constant.numeric.hex
(binary_literal) @constant.numeric.binary

; Operators
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "**"
  "//"
] @operator.arithmetic

[
  "="
  "+="
  "-="
  "*="
  "/="
  "%="
] @operator.assignment

[
  "=="
  "!="
  ">"
  "<"
  ">="
  "<="
] @operator.comparison

[
  "&&"
  "||"
  "!"
] @operator.logical

; Punctuation
[
  "("
  ")"
] @punctuation.bracket

[
  "["
  "]"
] @punctuation.bracket

[
  "{"
  "}"
] @punctuation.bracket

[
  ";"
  ","
  "."
] @punctuation.delimiter

; Color constants for colored output
[
  "red"
  "green"
  "blue"
  "yellow"
  "magenta"
  "cyan"
  "white"
  "bright_red"
  "bright_green"
  "bright_blue"
  "bright_yellow"
  "bright_magenta"
  "bright_cyan"
  "bright_white"
] @support.constant.color

; Compiler construction keywords
[
  "token"
  "lexer"
  "parser"
  "ast"
  "node"
  "visitor"
  "symbol"
  "scope"
  "typesys"
  "ir"
  "codegen"
  "optimize"
  "target"
  "grammar"
  "rule"
  "attribute"
  "const"
  "enum"
  "inline"
  "final"
  "volatile"
] @keyword.other

; Library names
[
  "arrlib"
  "strlib"
  "mathlib"
  "random"
  "file"
  "json"
  "bolt"
  "seed"
  "color"
  "crypto"
  "regex"
  "uuid"
  "os"
  "validation"
  "system"
  "boxlib"
  "loglib"
  "htlib"
  "netlib"
  "audio"
  "image"
  "date"
  "memlib"
  "binlib"
  "bitlib"
  "syslib"
  "complib"
  "thrlib"
  "timelib"
] @entity.name.class

; API keywords
[
  "api"
  "call"
  "post"
  "connect"
  "from"
  "to"
  "import"
  "export"
  "use"
  "class"
  "ping"
] @keyword.other

; Type annotations and document types
[
  "web"
  "script"
  "cli"
] @constant.language.document-type