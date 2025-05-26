; Razen Language Redactions
; Tree-sitter queries for redacting sensitive data in Razen

; Redact password-related strings
(string_literal) @redact
(#match? @redact "(?i)(password|passwd|pwd|secret|token|key|api_key|auth)")

; Redact connection strings and database URLs
(string_literal) @redact
(#match? @redact "(mysql://|postgresql://|mongodb://|redis://|sqlite://)")

; Redact email addresses in strings
(string_literal) @redact
(#match? @redact "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")

; Redact phone numbers
(string_literal) @redact
(#match? @redact "\\+?[1-9]\\d{1,14}")

; Redact credit card numbers
(string_literal) @redact
(#match? @redact "\\b(?:\\d{4}[\\s-]?){3}\\d{4}\\b")

; Redact Social Security Numbers
(string_literal) @redact
(#match? @redact "\\b\\d{3}-\\d{2}-\\d{4}\\b")

; Redact IP addresses
(string_literal) @redact
(#match? @redact "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b")

; Redact URLs with sensitive paths
(string_literal) @redact
(#match? @redact "(?i)(admin|private|internal|secret|confidential)")

; Redact JWT tokens
(string_literal) @redact
(#match? @redact "^[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_=]+\\.[A-Za-z0-9-_.+/=]*$")

; Redact hexadecimal hashes (potential API keys or secrets)
(string_literal) @redact
(#match? @redact "^[a-fA-F0-9]{32,}$")

; Redact variables that likely contain sensitive data
(variable_declaration
  name: (identifier) @redact
  (#match? @redact "(?i)(password|secret|token|key|auth|private|credential)"))

; Redact sensitive environment variables
(function_call
  name: (identifier) @func
  arguments: (argument_list
    (string_literal) @redact)
  (#eq? @func "getenv")
  (#match? @redact "(?i)(password|secret|token|key|auth|private)"))

; Redact database configuration values
(object_literal
  (property
    key: (identifier) @key
    value: (string_literal) @redact)
  (#any-of? @key "password" "secret" "token" "key" "auth"))

; Redact crypto function arguments
(library_call
  library: (identifier) @lib
  function: (identifier) @func
  arguments: (argument_list
    (string_literal) @redact)
  (#eq? @lib "Crypto")
  (#any-of? @func "encrypt" "decrypt" "hash" "sign"))