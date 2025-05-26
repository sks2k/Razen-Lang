; Razen Language Code Outline
; Tree-sitter queries for code outline/structure in Razen

; Function definitions
(function_definition
  name: (identifier) @name) @item
(#set! tag "function")

; Variable declarations
(variable_declaration
  type: (_) @context
  name: (identifier) @name) @item
(#set! tag "variable")

; Library imports
(library_import
  "lib" @context
  (identifier) @name) @item
(#set! tag "module")

; Document type declarations
(document_type
  "type" @context
  (document_kind) @name) @item
(#set! tag "type")

; Class definitions (if supported)
(class_definition
  name: (identifier) @name) @item
(#set! tag "class")

; API definitions
(api_definition
  name: (identifier) @name) @item
(#set! tag "interface")

; Constants
(constant_declaration
  name: (identifier) @name) @item
(#set! tag "constant")

; Enum definitions
(enum_definition
  name: (identifier) @name) @item
(#set! tag "enum")

; Comments that look like section headers
(comment) @item
(#match? @item "^#\\s*={3,}.*={3,}$")
(#set! tag "section")

; Top-level assignments that could be configuration
(assignment_expression
  left: (identifier) @name
  right: (_)) @item
(#set! tag "property")