const {
  createConnection,
  TextDocuments,
  Diagnostic,
  DiagnosticSeverity,
  ProposedFeatures,
  InitializeParams,
  DidChangeConfigurationNotification,
  CompletionItem,
  TextDocumentPositionParams,
  TextDocumentSyncKind,
  InitializeResult
} = require('vscode-languageserver/node');

const { TextDocument } = require('vscode-languageserver-textdocument');

// Create a connection for the server
const connection = createConnection(ProposedFeatures.all);

// Create a document manager
const documents = new TextDocuments(TextDocument);

// Token type definitions with expected value types
const TOKEN_TYPES = {
  'let': { 
    expectedType: 'number', 
    description: 'Numeric variable declaration - should only be used with numbers'
  },
  'take': { 
    expectedType: 'string', 
    description: 'String variable declaration - should only be used with strings'
  },
  'hold': { 
    expectedType: 'boolean', 
    description: 'Boolean variable declaration - should only be used with booleans or boolean expressions'
  },
  'put': { 
    expectedType: 'any', 
    description: 'General variable declaration - can be used with any type'
  },
  'sum': { 
    expectedType: 'number', 
    description: 'Sum calculation - should only be used with numeric expressions'
  },
  'diff': { 
    expectedType: 'number', 
    description: 'Difference calculation - should only be used with numeric expressions'
  },
  'prod': { 
    expectedType: 'number', 
    description: 'Product calculation - should only be used with numeric expressions'
  },
  'div': { 
    expectedType: 'number', 
    description: 'Division calculation - should only be used with numeric expressions'
  },
  'mod': { 
    expectedType: 'number', 
    description: 'Modulus calculation - should only be used with numeric expressions'
  },
  'text': { 
    expectedType: 'string', 
    description: 'String data storage - should only be used with strings'
  },
  'concat': { 
    expectedType: 'string', 
    description: 'String concatenation - should only be used with strings'
  },
  'slice': { 
    expectedType: 'string', 
    description: 'Substring extraction - should only be used with strings'
  },
  'len': { 
    expectedType: 'string', 
    description: 'String length - should only be used with strings'
  },
  'list': { 
    expectedType: 'array', 
    description: 'Dynamic array - should be used with array literals'
  },
  'arr': { 
    expectedType: 'array', 
    description: 'Fixed-size array - should be used with array literals'
  }
};

// Library function return types
const LIBRARY_RETURN_TYPES = {
  // Filesystem library return types
  'filesystem': {
    'exists': 'boolean',      // Returns true/false if path exists
    'is_file': 'boolean',     // Returns true/false if path is a file
    'is_dir': 'boolean',      // Returns true/false if path is a directory
    'create_dir': 'boolean',  // Returns true/false if directory was created
    'remove': 'boolean',      // Returns true/false if file/directory was removed
    'read_file': 'string',    // Returns file contents as string
    'write_file': 'boolean',  // Returns true/false if file was written
    'list_dir': 'array',      // Returns array of files/directories
    'metadata': 'object',     // Returns object with file metadata
    'absolute_path': 'string', // Returns absolute path as string
    'copy': 'boolean',        // Returns true/false if file was copied
    'move': 'boolean',        // Returns true/false if file was moved
    'extension': 'string',    // Returns file extension as string
    'file_stem': 'string',    // Returns file name without extension
    'parent_dir': 'string',   // Returns parent directory as string
    'join_path': 'string',    // Returns joined path as string
    'change_dir': 'boolean',  // Returns true/false if directory was changed
    'current_dir': 'string',  // Returns current directory as string
    'temp_file': 'string',    // Returns temporary file path as string
    'temp_dir': 'string'      // Returns temporary directory path as string
  },
  
  // String library return types
  'strlib': {
    'upper': 'string',        // Returns uppercase string
    'lower': 'string',        // Returns lowercase string
    'substring': 'string',    // Returns substring
    'replace': 'string',      // Returns string with replacements
    'length': 'number',       // Returns string length as number
    'split': 'array',         // Returns array of substrings
    'trim': 'string',         // Returns trimmed string
    'starts_with': 'boolean', // Returns true/false if string starts with prefix
    'ends_with': 'boolean',   // Returns true/false if string ends with suffix
    'contains': 'boolean',    // Returns true/false if string contains substring
    'repeat': 'string'        // Returns repeated string
  },
  
  // Array library return types
  'arrlib': {
    'push': 'number',         // Returns new array length
    'pop': 'any',             // Returns popped element
    'join': 'string',         // Returns joined string
    'length': 'number',       // Returns array length
    'unique': 'array'         // Returns array with unique elements
  },
  
  // Math library return types
  'mathlib': {
    'add': 'number',          // Returns sum
    'subtract': 'number',     // Returns difference
    'multiply': 'number',     // Returns product
    'divide': 'number',       // Returns quotient
    'power': 'number',        // Returns power
    'sqrt': 'number',         // Returns square root
    'abs': 'number',          // Returns absolute value
    'round': 'number',        // Returns rounded value
    'floor': 'number',        // Returns floor value
    'ceil': 'number',         // Returns ceiling value
    'sin': 'number',          // Returns sine
    'cos': 'number',          // Returns cosine
    'tan': 'number',          // Returns tangent
    'log': 'number',          // Returns logarithm
    'exp': 'number',          // Returns exponential
    'random': 'number',       // Returns random number
    'max': 'number',          // Returns maximum value
    'min': 'number',          // Returns minimum value
    'modulo': 'number'        // Returns modulo
  },
  
  // Random library return types
  'random': {
    'int': 'number',          // Returns random integer
    'float': 'number',        // Returns random float
    'choice': 'any',          // Returns random element from array
    'shuffle': 'array'        // Returns shuffled array
  },
  
  // File library (legacy) return types
  'file': {
    'read': 'string',         // Returns file contents as string
    'write': 'boolean',       // Returns true/false if file was written
    'append': 'boolean',      // Returns true/false if content was appended
    'exists': 'boolean',      // Returns true/false if file exists
    'delete': 'boolean'       // Returns true/false if file was deleted
  },
  
  // JSON library return types
  'json': {
    'parse': 'object',        // Returns parsed JSON object
    'stringify': 'string'     // Returns JSON string
  },
  
  // Bolt library return types
  'bolt': {
    'run': 'any',             // Returns the result of the executed function
    'parallel': 'array'       // Returns array of results from parallel execution
  },
  
  // Seed library return types
  'seed': {
    'generate': 'number',     // Returns generated seed value
    'map': 'array'            // Returns mapped array based on seed
  },
  
  // Memory library return types
  'memorylib': {
    'addressof': 'number',    // Returns memory address as number
    'deref': 'any',           // Returns dereferenced value
    'add_offset': 'number',   // Returns new memory address
    'alloc': 'number',        // Returns allocated memory address
    'free': 'boolean',        // Returns true/false if memory was freed
    'write_byte': 'boolean',  // Returns true/false if byte was written
    'read_byte': 'number',    // Returns byte value
    'create_buffer': 'number', // Returns buffer address
    'free_buffer': 'boolean', // Returns true/false if buffer was freed
    'buffer_write_string': 'boolean', // Returns true/false if string was written
    'buffer_read_string': 'string',   // Returns string from buffer
    'buffer_copy': 'boolean', // Returns true/false if buffer was copied
    'stats': 'object'         // Returns memory stats object
  },
  
  // Binary library return types
  'binarylib': {
    'create': 'number',       // Returns file handle
    'open': 'number',         // Returns file handle
    'close': 'boolean',       // Returns true/false if file was closed
    'write_bytes': 'number',  // Returns number of bytes written
    'read_bytes': 'array',    // Returns byte array
    'seek': 'boolean',        // Returns true/false if seek was successful
    'tell': 'number',         // Returns current position
    'bytes_to_string': 'string', // Returns string from bytes
    'string_to_bytes': 'array',  // Returns byte array from string
    'stats': 'object'         // Returns file stats object
  },
  
  // Bitwise library return types
  'bitwiselib': {
    'and': 'number',          // Returns bitwise AND result
    'or': 'number',           // Returns bitwise OR result
    'xor': 'number',          // Returns bitwise XOR result
    'not': 'number',          // Returns bitwise NOT result
    'left_shift': 'number',   // Returns left shifted value
    'right_shift': 'number',  // Returns right shifted value
    'unsigned_right_shift': 'number', // Returns unsigned right shifted value
    'get_bit': 'number',      // Returns bit value (0 or 1)
    'set_bit': 'number',      // Returns new value with bit set
    'count_bits': 'number',   // Returns number of set bits
    'to_binary': 'string',    // Returns binary string representation
    'to_hex': 'string',       // Returns hex string representation
    'from_binary': 'number',  // Returns number from binary string
    'from_hex': 'number'      // Returns number from hex string
  },
  
  // System library return types
  'systemlib': {
    'getpid': 'number',       // Returns process ID
    'getcwd': 'string',       // Returns current working directory
    'execute': 'object',      // Returns execution result object
    'getenv': 'string',       // Returns environment variable value
    'setenv': 'boolean',      // Returns true/false if env var was set
    'environ': 'object',      // Returns environment variables object
    'args': 'array',          // Returns command line arguments array
    'path_exists': 'boolean', // Returns true/false if path exists
    'realpath': 'string',     // Returns resolved path
    'exit': 'number',         // Returns exit code
    'sleep': 'boolean',       // Returns true after sleeping
    'hostname': 'string',     // Returns hostname
    'username': 'string',     // Returns username
    'current_time': 'string', // Returns current time string
    'system_name': 'string'   // Returns system name
  },
  
  // System library (alias) return types
  'system': {
    'exec': 'object',         // Returns execution result object
    'uptime': 'number',       // Returns system uptime in seconds
    'info': 'object',         // Returns system info object
    'current_time': 'string', // Returns current time string
    'system_name': 'string'   // Returns system name
  },
  
  // Process library return types
  'processlib': {
    'create': 'number',       // Returns process ID
    'wait': 'object',         // Returns process exit info
    'is_running': 'boolean',  // Returns true/false if process is running
    'kill': 'boolean',        // Returns true/false if process was killed
    'signal': 'boolean',      // Returns true/false if signal was sent
    'info': 'object',         // Returns process info object
    'read_stdout': 'string',  // Returns process stdout
    'read_stderr': 'string',  // Returns process stderr
    'write_stdin': 'boolean'  // Returns true/false if write was successful
  },
  
  // Thread library return types
  'threadlib': {
    'create': 'number',       // Returns thread ID
    'join': 'any',            // Returns thread result
    'is_running': 'boolean',  // Returns true/false if thread is running
    'sleep': 'boolean',       // Returns true after sleeping
    'mutex_create': 'number', // Returns mutex ID
    'mutex_lock': 'boolean',  // Returns true/false if mutex was locked
    'mutex_unlock': 'boolean', // Returns true/false if mutex was unlocked
    'mutex_destroy': 'boolean', // Returns true/false if mutex was destroyed
    'current': 'number',      // Returns current thread ID
    'cpu_count': 'number',    // Returns number of CPU cores
    'thread_id': 'number',    // Returns thread ID
    'thread_count': 'number'  // Returns number of active threads
  },
  
  // Compiler library return types
  'compilerlib': {
    'create_node': 'object',  // Returns node object
    'add_child': 'boolean',   // Returns true/false if child was added
    'node_to_string': 'string', // Returns string representation of node
    'create_symbol_table': 'object', // Returns symbol table object
    'add_symbol': 'boolean',  // Returns true/false if symbol was added
    'lookup_symbol': 'object', // Returns symbol object or null
    'generate_ir': 'string',  // Returns IR code as string
    'optimize_ir': 'string',  // Returns optimized IR code
    'generate_assembly': 'string', // Returns assembly code
    'parse': 'object',        // Returns AST object
    'tokenize': 'array',      // Returns array of tokens
    'compile': 'boolean'      // Returns true/false if compilation succeeded
  },
  
  // Lexer library return types
  'lexerlib': {
    'create_lexer': 'object', // Returns lexer object
    'tokenize': 'array',      // Returns array of tokens
    'define_token': 'boolean' // Returns true/false if token was defined
  },
  
  // Parser library return types
  'parserlib': {
    'create_parser': 'object', // Returns parser object
    'parse': 'object',        // Returns AST object
    'define_rule': 'boolean', // Returns true/false if rule was defined
    'create_grammar': 'object' // Returns grammar object
  },
  
  // AST library return types
  'astlib': {
    'create_node': 'object',  // Returns node object
    'define_node_type': 'boolean', // Returns true/false if node type was defined
    'traverse': 'array',      // Returns array of visited nodes
    'create_visitor': 'object' // Returns visitor object
  },
  
  // Symbol library return types
  'symbollib': {
    'create_symbol_table': 'object', // Returns symbol table object
    'define_symbol': 'boolean', // Returns true/false if symbol was defined
    'add_symbol': 'boolean',  // Returns true/false if symbol was added
    'lookup_symbol': 'object' // Returns symbol object or null
  },
  
  // Type library return types
  'typelib': {
    'define_type': 'boolean', // Returns true/false if type was defined
    'check_type': 'boolean',  // Returns true/false if type check passed
    'create_type_system': 'object', // Returns type system object
    'infer_type': 'string'    // Returns inferred type name
  },
  
  // IR library return types
  'irlib': {
    'create_instruction': 'object', // Returns instruction object
    'generate': 'string',     // Returns generated IR code
    'optimize': 'string',     // Returns optimized IR code
    'to_string': 'string'     // Returns string representation of IR
  },
  
  // CodeGen library return types
  'codegenlib': {
    'create_generator': 'object', // Returns generator object
    'generate': 'string',     // Returns generated code
    'define_target': 'boolean', // Returns true/false if target was defined
    'emit_code': 'boolean'    // Returns true/false if code was emitted
  },
  
  // Optimize library return types
  'optimizelib': {
    'create_pass': 'object',  // Returns optimization pass object
    'apply': 'object',        // Returns optimized object
    'analyze': 'object',      // Returns analysis result
    'create_pipeline': 'object' // Returns pipeline object
  },
  
  // Color library return types
  'color': {
    'hex_to_rgb': 'array',    // Returns RGB array [r, g, b]
    'rgb_to_hex': 'string',   // Returns hex color string
    'lighten': 'string',      // Returns lightened color
    'darken': 'string',       // Returns darkened color
    'get_ansi_color': 'string' // Returns ANSI color code
  },
  
  // Crypto library return types
  'crypto': {
    'hash': 'string',         // Returns hash string
    'encrypt': 'string',      // Returns encrypted string
    'decrypt': 'string'       // Returns decrypted string
  },
  
  // Regex library return types
  'regex': {
    'match': 'boolean',       // Returns true/false if pattern matches
    'search': 'array',        // Returns array of matches
    'replace': 'string'       // Returns string with replacements
  },
  
  // UUID library return types
  'uuid': {
    'generate': 'string',     // Returns UUID string
    'parse': 'object',        // Returns UUID components
    'is_valid': 'boolean'     // Returns true/false if UUID is valid
  },
  
  // OS library return types
  'os': {
    'env': 'string',          // Returns environment variable value
    'cwd': 'string',          // Returns current working directory
    'platform': 'string'      // Returns platform name
  },
  
  // Validation library return types
  'validation': {
    'email': 'boolean',       // Returns true/false if email is valid
    'phone': 'boolean',       // Returns true/false if phone is valid
    'required': 'boolean',    // Returns true/false if value is not empty
    'min_length': 'boolean'   // Returns true/false if length is >= min
  },
  
  // Box library return types
  'boxlib': {
    'put': 'object',          // Returns box object
    'get': 'any',             // Returns value from box
    'is_box': 'boolean'       // Returns true/false if value is a box
  },
  
  // Log library return types
  'loglib': {
    'info': 'boolean',        // Returns true if logged successfully
    'warn': 'boolean',        // Returns true if logged successfully
    'error': 'boolean',       // Returns true if logged successfully
    'debug': 'boolean'        // Returns true if logged successfully
  },
  
  // HT library return types
  'htlib': {
    'coin': 'boolean',        // Returns true/false (heads/tails)
    'bool': 'boolean'         // Returns random boolean
  },
  
  // Net library return types
  'netlib': {
    'ping': 'boolean',        // Returns true/false if ping succeeded
    'get': 'string',          // Returns response body
    'post': 'string'          // Returns response body
  },
  
  // Audio library return types
  'audio': {
    'play': 'boolean',        // Returns true/false if playback started
    'pause': 'boolean',       // Returns true/false if playback paused
    'stop': 'boolean',        // Returns true/false if playback stopped
    'record': 'string'        // Returns path to recorded audio file
  },
  
  // Image library return types
  'image': {
    'load': 'object',         // Returns image object
    'save': 'boolean',        // Returns true/false if image was saved
    'resize': 'object',       // Returns resized image object
    'crop': 'object'          // Returns cropped image object
  },
  
  // Date library return types
  'date': {
    'now': 'string',          // Returns current date/time string
    'year': 'number',         // Returns year
    'month': 'number',        // Returns month
    'day': 'number',          // Returns day
    'format': 'string',       // Returns formatted date string
    'parse': 'object',        // Returns date object
    'add_days': 'string',     // Returns new date string
    'add_months': 'string',   // Returns new date string
    'add_years': 'string',    // Returns new date string
    'weekday': 'number',      // Returns weekday number
    'weekday_name': 'string', // Returns weekday name
    'days_in_month': 'number', // Returns number of days in month
    'is_leap_year': 'boolean', // Returns true/false if leap year
    'diff_days': 'number'     // Returns difference in days
  },
  
  // Time library return types
  'timelib': {
    'now': 'string',          // Returns current time string
    'format': 'string',       // Returns formatted time string
    'parse': 'object',        // Returns time object
    'add': 'string',          // Returns new time string
    'year': 'number',         // Returns year
    'month': 'number',        // Returns month
    'day': 'number'           // Returns day
  }
};

// Library definitions
const LIBRARIES = {
  // Array library
  'arrlib': ['push', 'pop', 'join', 'length', 'unique'],
  
  // String library
  'strlib': ['upper', 'lower', 'substring', 'replace', 'length', 'split', 'trim', 'starts_with', 'ends_with', 'contains', 'repeat'],
  
  // Math library
  'mathlib': ['add', 'subtract', 'multiply', 'divide', 'power', 'sqrt', 'abs', 'round', 'floor', 'ceil', 'sin', 'cos', 'tan', 'log', 'exp', 'random', 'max', 'min', 'modulo'],
  
  // Time library
  'timelib': ['now', 'format', 'parse', 'add', 'year', 'month', 'day'],
  
  // Random library
  'random': ['int', 'float', 'choice', 'shuffle'],
  
  // File library (legacy)
  'file': ['read', 'write', 'append', 'exists', 'delete'],
  
  // Filesystem library (extended)
  'filesystem': ['exists', 'is_file', 'is_dir', 'create_dir', 'remove', 'read_file', 'write_file', 'list_dir', 'metadata', 'absolute_path', 'copy', 'move', 'extension', 'file_stem', 'parent_dir', 'join_path', 'change_dir', 'current_dir', 'temp_file', 'temp_dir'],
  
  // JSON library
  'json': ['parse', 'stringify'],
  
  // Bolt library
  'bolt': ['run', 'parallel'],
  
  // Seed library
  'seed': ['generate', 'map'],
  
  // Memory library
  'memorylib': ['addressof', 'deref', 'add_offset', 'alloc', 'free', 'write_byte', 'read_byte', 'create_buffer', 'free_buffer', 'buffer_write_string', 'buffer_read_string', 'buffer_copy', 'stats'],
  
  // Binary library
  'binarylib': ['create', 'open', 'close', 'write_bytes', 'read_bytes', 'seek', 'tell', 'bytes_to_string', 'string_to_bytes', 'stats'],
  
  // Bitwise library
  'bitwiselib': ['and', 'or', 'xor', 'not', 'left_shift', 'right_shift', 'unsigned_right_shift', 'get_bit', 'set_bit', 'count_bits', 'to_binary', 'to_hex', 'from_binary', 'from_hex'],
  
  // System library
  'systemlib': ['getpid', 'getcwd', 'execute', 'getenv', 'setenv', 'environ', 'args', 'path_exists', 'realpath', 'exit', 'sleep', 'hostname', 'username', 'current_time', 'system_name'],
  
  // Process library
  'processlib': ['create', 'wait', 'is_running', 'kill', 'signal', 'info', 'read_stdout', 'read_stderr', 'write_stdin'],
  
  // Thread library
  'threadlib': ['create', 'join', 'is_running', 'sleep', 'mutex_create', 'mutex_lock', 'mutex_unlock', 'mutex_destroy', 'current', 'cpu_count', 'thread_id', 'thread_count'],
  
  // Compiler library
  'compilerlib': ['create_node', 'add_child', 'node_to_string', 'create_symbol_table', 'add_symbol', 'lookup_symbol', 'generate_ir', 'optimize_ir', 'generate_assembly', 'parse', 'tokenize', 'compile'],
  
  // Lexer library
  'lexerlib': ['create_lexer', 'tokenize', 'define_token'],
  
  // Parser library
  'parserlib': ['create_parser', 'parse', 'define_rule', 'create_grammar'],
  
  // AST library
  'astlib': ['create_node', 'define_node_type', 'traverse', 'create_visitor'],
  
  // Symbol library
  'symbollib': ['create_symbol_table', 'define_symbol', 'add_symbol', 'lookup_symbol'],
  
  // Type library
  'typelib': ['define_type', 'check_type', 'create_type_system', 'infer_type'],
  
  // IR library
  'irlib': ['create_instruction', 'generate', 'optimize', 'to_string'],
  
  // CodeGen library
  'codegenlib': ['create_generator', 'generate', 'define_target', 'emit_code'],
  
  // Optimize library
  'optimizelib': ['create_pass', 'apply', 'analyze', 'create_pipeline'],
  
  // Color library
  'color': ['hex_to_rgb', 'rgb_to_hex', 'lighten', 'darken', 'get_ansi_color'],
  
  // Crypto library
  'crypto': ['hash', 'encrypt', 'decrypt'],
  
  // Regex library
  'regex': ['match', 'search', 'replace'],
  
  // UUID library
  'uuid': ['generate', 'parse', 'is_valid'],
  
  // OS library
  'os': ['env', 'cwd', 'platform'],
  
  // Validation library
  'validation': ['email', 'phone', 'required', 'min_length'],
  
  // System library
  'system': ['exec', 'uptime', 'info', 'current_time', 'system_name'],
  
  // Box library
  'boxlib': ['put', 'get', 'is_box'],
  
  // Log library
  'loglib': ['info', 'warn', 'error', 'debug'],
  
  // HT library
  'htlib': ['coin', 'bool'],
  
  // Net library
  'netlib': ['ping', 'get', 'post'],
  
  // Audio library
  'audio': ['play', 'pause', 'stop', 'record'],
  
  // Image library
  'image': ['load', 'save', 'resize', 'crop'],
  
  // Date library
  'date': ['now', 'year', 'month', 'day', 'format', 'parse', 'add_days', 'add_months', 'add_years', 'weekday', 'weekday_name', 'days_in_month', 'is_leap_year', 'diff_days']
};

// Helper function to determine value type
function getValueType(value) {
  if (value.match(/^[0-9]+(\.[0-9]+)?$/)) {
    return 'number';
  } else if (value.match(/^".*"$/) || value.match(/^'.*'$/)) {
    return 'string';
  } else if (value === 'true' || value === 'false') {
    return 'boolean';
  } else if (value.match(/^\[.*\]$/)) {
    return 'array';
  } else if (value.match(/^[a-zA-Z_][a-zA-Z0-9_]*$/)) {
    return 'identifier'; // Variable reference
  } else if (value.includes('+') || value.includes('-') || value.includes('*') || value.includes('/') || value.includes('%')) {
    return 'expression'; // Expression
  } else {
    return 'unknown';
  }
}

// Helper function to check if expression is likely to evaluate to a specific type
function expressionLikelyType(expression) {
  if (expression.includes('+') || expression.includes('-') || 
      expression.includes('*') || expression.includes('/') || 
      expression.includes('%') || expression.includes('**')) {
    return 'number'; // Mathematical expression
  } else if (expression.includes('==') || expression.includes('!=') || 
             expression.includes('>') || expression.includes('<') || 
             expression.includes('>=') || expression.includes('<=') ||
             expression.includes('&&') || expression.includes('||') ||
             expression.includes('!')) {
    return 'boolean'; // Comparison or logical expression
  } else if (expression.includes('"') || expression.includes("'")) {
    if (expression.includes('+')) {
      return 'string'; // String concatenation
    }
    return 'string'; // String literal
  }
  return 'unknown';
}

// Helper function to validate token usage
function validateTokenUsage(tokenType, value) {
  const expectedType = TOKEN_TYPES[tokenType]?.expectedType;
  if (!expectedType) {
    return null; // Unknown token type
  }

  const valueType = getValueType(value);
  
  // Handle expressions
  if (valueType === 'expression') {
    const expressionType = expressionLikelyType(value);
    if (expressionType !== 'unknown' && expressionType !== expectedType && expectedType !== 'any') {
      return `Token '${tokenType}' expects ${expectedType} values, but got an expression that likely evaluates to ${expressionType}`;
    }
    return null;
  }

  // Handle variable references
  if (valueType === 'identifier') {
    return null; // We can't determine the type of a variable reference without symbol tracking
  }

  // Handle direct value types
  if (valueType !== expectedType && expectedType !== 'any') {
    return `Token '${tokenType}' expects ${expectedType} values, but got ${valueType}`;
  }

  return null;
}

// Helper function to validate library function usage
function validateLibraryUsage(library, functionName) {
  const libraryFunctions = LIBRARIES[library.toLowerCase()];
  if (!libraryFunctions) {
    return `Unknown library: '${library}'`;
  }

  if (!libraryFunctions.includes(functionName)) {
    return `Unknown function '${functionName}' in library '${library}'. Available functions: ${libraryFunctions.join(', ')}`;
  }

  return null;
}

// Helper function to get the appropriate token type for a library function return type
function getTokenTypeForReturnType(library, functionName) {
  // Check if we have return type information for this library and function
  if (LIBRARY_RETURN_TYPES[library] && LIBRARY_RETURN_TYPES[library][functionName]) {
    const returnType = LIBRARY_RETURN_TYPES[library][functionName];
    
    switch (returnType) {
      case 'number':
        return 'let'; // Use 'let' for numeric values
      case 'string':
        return 'take'; // Use 'take' for string values
      case 'boolean':
        return 'hold'; // Use 'hold' for boolean values
      case 'array':
      case 'object':
        return 'list'; // Use 'list' for arrays and objects
      default:
        return 'put'; // Use 'put' for any other type
    }
  }
  
  return null; // Return null if we don't have return type information
}

// Helper function to validate library function return type with token type
function validateLibraryFunctionReturnType(tokenType, library, functionName) {
  const expectedTokenType = getTokenTypeForReturnType(library, functionName);
  
  if (!expectedTokenType) {
    return null; // No validation possible if we don't have return type information
  }
  
  if (tokenType !== expectedTokenType && tokenType !== 'put') { // 'put' can be used with any type
    return `Token '${tokenType}' is not appropriate for ${library}[${functionName}] which returns ${LIBRARY_RETURN_TYPES[library][functionName]}. Use '${expectedTokenType}' instead.`;
  }
  
  return null;
}

// Validate a Razen document and return diagnostics
function validateRazenDocument(textDocument) {
  const text = textDocument.getText();
  const lines = text.split(/\r?\n/g);
  const diagnostics = [];

  // Regular expressions for token usage and library calls
  const tokenRegex = /\b(let|take|hold|put|sum|diff|prod|div|mod|text|concat|slice|len|list|arr)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([^;]+)/g;
  const libraryRegex = /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*\[\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\]\s*\(/g;
  const libraryAssignmentRegex = /\b(let|take|hold|put|sum|diff|prod|div|mod|text|concat|slice|len|list|arr)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\[\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\]\s*\(/g;

  // Check each line for token usage
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Skip comment lines
    if (line.trim().startsWith('#')) {
      continue;
    }

    // Check library function assignment with token type
    let libraryAssignmentMatch;
    const lineLibraryAssignmentRegex = new RegExp(libraryAssignmentRegex.source, libraryAssignmentRegex.flags);
    while ((libraryAssignmentMatch = lineLibraryAssignmentRegex.exec(line)) !== null) {
      const [fullMatch, tokenType, variableName, library, functionName] = libraryAssignmentMatch;
      const error = validateLibraryFunctionReturnType(tokenType, library, functionName);
      
      if (error) {
        const diagnostic = {
          severity: DiagnosticSeverity.Warning,
          range: {
            start: { line: i, character: libraryAssignmentMatch.index },
            end: { line: i, character: libraryAssignmentMatch.index + fullMatch.length }
          },
          message: error,
          source: 'razen-language-server'
        };
        diagnostics.push(diagnostic);
      }
    }

    // Check token usage
    let tokenMatch;
    const lineTokenRegex = new RegExp(tokenRegex.source, tokenRegex.flags);
    while ((tokenMatch = lineTokenRegex.exec(line)) !== null) {
      // Skip if this was already handled by the library assignment regex
      if (line.substring(tokenMatch.index).match(/[a-zA-Z_][a-zA-Z0-9_]*\s*\[\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\]\s*\(/)) {
        continue;
      }
      
      const [fullMatch, tokenType, variableName, value] = tokenMatch;
      const error = validateTokenUsage(tokenType, value.trim());
      
      if (error) {
        const diagnostic = {
          severity: DiagnosticSeverity.Warning,
          range: {
            start: { line: i, character: tokenMatch.index },
            end: { line: i, character: tokenMatch.index + fullMatch.length }
          },
          message: error,
          source: 'razen-language-server'
        };
        diagnostics.push(diagnostic);
      }
    }

    // Check library usage
    let libraryMatch;
    const lineLibraryRegex = new RegExp(libraryRegex.source, libraryRegex.flags);
    while ((libraryMatch = lineLibraryRegex.exec(line)) !== null) {
      const [fullMatch, library, functionName] = libraryMatch;
      const error = validateLibraryUsage(library, functionName);
      
      if (error) {
        const diagnostic = {
          severity: DiagnosticSeverity.Warning,
          range: {
            start: { line: i, character: libraryMatch.index },
            end: { line: i, character: libraryMatch.index + fullMatch.length }
          },
          message: error,
          source: 'razen-language-server'
        };
        diagnostics.push(diagnostic);
      }
    }
  }

  return diagnostics;
}

// Initialize connection
connection.onInitialize((params) => {
  return {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      // Tell the client that this server supports code completion.
      completionProvider: {
        resolveProvider: true
      }
    }
  };
});

connection.onInitialized(() => {
  connection.console.log('Razen Language Server initialized');
});

// The content of a text document has changed.
documents.onDidChangeContent(change => {
  validateTextDocument(change.document);
});

// Validate a text document
async function validateTextDocument(textDocument) {
  const diagnostics = validateRazenDocument(textDocument);
  connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
}

// Make the text document manager listen on the connection
documents.listen(connection);

// Listen on the connection
connection.listen();
