# src/lexer.py
# Enhanced Lexer for RAZEN (Revised for Interpolation and Optional Semicolons)

import ply.lex as lex
import os
import sys
import re

# --- Read Variable Definitions from properties/variables.rzn ---
def read_variables_from_file():
    try:
        # Try to find the variables.rzn file in multiple locations
        possible_paths = [
            os.path.join(os.path.dirname(os.path.dirname(__file__)), 'properties', 'variables.rzn'),
            os.path.join('/usr/local/lib/razen', 'properties', 'variables.rzn'),
            os.path.join(os.path.dirname(__file__), '..', 'properties', 'variables.rzn'),
            os.path.join(os.getcwd(), 'properties', 'variables.rzn')
        ]
        
        variables_file = None
        for path in possible_paths:
            if os.path.exists(path):
                variables_file = path
                break
        
        if not variables_file:
            raise FileNotFoundError("Could not find variables.rzn in any of the expected locations")
        
        with open(variables_file, 'r') as f:
            content = f.read()
        
        # Parse the file to extract variable definitions
        keywords = {}
        token_list = []
        
        # Add basic tokens that aren't variable types
        standard_tokens = [
            # Literals
            'FLOAT', 'INTEGER', 'STRING_LITERAL',
            'TRUE', 'FALSE', 'NULL',
            # Identifiers
            'ID',
            
            # Additional keywords
            'WHILE', 'FUN', 'RETURN',
            
            # Operators / Delimiters
            'ASSIGN', 'EQ', 'NE', 'LE', 'GE', 'LT', 'GT',
            'PLUS', 'MINUS', 'MULTIPLY', 'DIVIDE', 'MODULO',
            'AND', 'OR',
            'LPAREN', 'RPAREN',
            'LBRACE', 'RBRACE',
            'LBRACKET', 'RBRACKET',
            'COMMA', 'COLON',
            'DOT',
            'AMPERSAND',
            'SEMICOLON',
            
            # Interpolation Tokens
            'STRING_START', 'STRING_END', 'INTERPOL_START', 'INTERPOL_END',
        ]
        token_list.extend(standard_tokens)
        
        # Add basic keywords not in the variables.rzn file
        basic_keywords = {
            'true': 'TRUE', 'false': 'FALSE', 'null': 'NULL',
            'while': 'WHILE', 'fun': 'FUN', 'return': 'RETURN'
        }
        keywords.update(basic_keywords)
        
        # Extract variable types from variables.rzn
        pattern = r'(\w+)\s*=>\s*for\s*.*?\.?'
        matches = re.findall(pattern, content)
        
        # Add special cases that don't follow the pattern
        if 'if' not in matches:
            matches.extend(['if', 'else', 'is', 'when', 'not'])
        if 'show' not in matches:
            matches.extend(['show', 'read'])
            
        for var in matches:
            token_name = var.strip().upper()
            if token_name and token_name not in token_list:
                token_list.append(token_name)
                keywords[var.strip().lower()] = token_name
        
        print(f"Loaded {len(keywords)} keywords from variables.rzn")
        return token_list, keywords
    except Exception as e:
        print(f"Error loading variables from file: {e}. Using default values.")
        return None, None

# Get tokens and keywords from variables.rzn
loaded_tokens, loaded_keywords = read_variables_from_file()

# --- Token Definition ---
if loaded_tokens:
    tokens = tuple(loaded_tokens)
else:
    # Fallback to hardcoded tokens
    tokens = (
        # Literals
        'FLOAT', 'INTEGER', 'STRING_LITERAL',
        'TRUE', 'FALSE', 'NULL',
        # Identifiers
        'ID',
        
        # 1️⃣ General Purpose Variables
        'LET', 'TAKE', 'HOLD', 'PUT',
        
        # 2️⃣ Mathematical Variables
        'SUM', 'DIFF', 'PROD', 'DIV', 'MOD',
        
        # 3️⃣ Logical Variables
        'IF', 'ELSE', 'IS', 'WHEN', 'NOT',
        
        # 4️⃣ String Variables
        'TEXT', 'CONCAT', 'SLICE', 'LEN',
        
        # 5️⃣ List & Array Variables
        'LIST', 'ARR', 'APPEND', 'REMOVE',
        
        # 6️⃣ Dictionary/Map Variables
        'MAP', 'KEY', 'VALUE',
        
        # 7️⃣ Date & Time Variables
        'CURRENT', 'NOW', 'YEAR', 'MONTH', 'DAY',
        'HOUR', 'MINUTE', 'SECOND',
        
        # 8️⃣ User-Defined Variables
        'STORE', 'BOX', 'REF',
        
        # 9️⃣ Input/Output Variables
        'SHOW', 'READ',
        
        # Additional keywords (from original implementation)
        'WHILE', 'FUN', 'RETURN',
        
        # Operators / Delimiters
        'ASSIGN', 'EQ', 'NE', 'LE', 'GE', 'LT', 'GT', # Comparison / Assignment
        'PLUS', 'MINUS', 'MULTIPLY', 'DIVIDE', 'MODULO', # Arithmetic
        'AND', 'OR',                 # Logical (Binary)
        'LPAREN', 'RPAREN',          # Grouping
        'LBRACE', 'RBRACE',          # Blocks
        'LBRACKET', 'RBRACKET',      # Lists/arrays
        'COMMA', 'COLON',            # Separators
        'DOT',                       # Property access
        'AMPERSAND',                 # Reference operator
        'SEMICOLON',                 # Newly added semicolon
        
        # Interpolation Tokens
        'STRING_START',  # "
        'STRING_END',    # "
        'INTERPOL_START',# ${
        'INTERPOL_END',  # }
    )

# Keywords mapping (use loaded_keywords or fallback to hardcoded)
if loaded_keywords:
    keywords = loaded_keywords
else:
    # Fallback to hardcoded keywords
    keywords = {
        # 1️⃣ General Purpose Variables
        'let': 'LET', 'take': 'TAKE', 'hold': 'HOLD', 'put': 'PUT',
        
        # 2️⃣ Mathematical Variables
        'sum': 'SUM', 'diff': 'DIFF', 'prod': 'PROD', 'div': 'DIV', 'mod': 'MOD',
        
        # 3️⃣ Logical Variables
        'if': 'IF', 'else': 'ELSE', 'is': 'IS', 'when': 'WHEN', 'not': 'NOT',
        
        # 4️⃣ String Variables
        'text': 'TEXT', 'concat': 'CONCAT', 'slice': 'SLICE', 'len': 'LEN',
        
        # 5️⃣ List & Array Variables
        'list': 'LIST', 'arr': 'ARR', 'append': 'APPEND', 'remove': 'REMOVE',
        
        # 6️⃣ Dictionary/Map Variables
        'map': 'MAP', 'key': 'KEY', 'value': 'VALUE',
        
        # 7️⃣ Date & Time Variables
        'current': 'CURRENT', 'now': 'NOW', 'year': 'YEAR', 'month': 'MONTH', 'day': 'DAY',
        'hour': 'HOUR', 'minute': 'MINUTE', 'second': 'SECOND',
        
        # 8️⃣ User-Defined Variables
        'store': 'STORE', 'box': 'BOX', 'ref': 'REF',
        
        # 9️⃣ Input/Output Variables
        'show': 'SHOW', 'read': 'READ',
        
        # Additional keywords (from original implementation)
        'while': 'WHILE', 'fun': 'FUN', 'return': 'RETURN',
        
        # Boolean/Null literals
        'true': 'TRUE', 'false': 'FALSE', 'null': 'NULL',
    }

# --- Lexer Class with States for Interpolation ---
class Lexer:
    tokens = tokens

    # Lexer states: INITIAL for normal code, interpolation inside strings
    states = (
        ('interpolation', 'exclusive'),
    )

    def __init__(self):
        self.ply_lexer = lex.lex(module=self, errorlog=lex.NullLogger())
        self._code = ""
        # Stack to handle nested interpolations (e.g., "${ "Hello ${name}" }")
        self.interpolation_stack = []
        self.bracket_count = 0  # For tracking nested curly braces within interpolations

    # --- Shared Token Rules ---
    t_ignore = ' \t' # Ignore spaces and tabs in all states
    t_ignore_COMMENT = r'//.*' # Ignore // comments in all states

    # --- INITIAL State Rules ---
    t_EQ = r'=='
    t_NE = r'!='
    t_LE = r'<='
    t_GE = r'>='
    t_AND = r'&&'
    t_OR = r'\|\|'
    t_ASSIGN = r'='
    t_PLUS = r'\+'
    t_MINUS = r'-'
    t_MULTIPLY = r'\*'
    t_DIVIDE = r'/'
    t_MODULO = r'%'
    t_LT = r'<'
    t_GT = r'>'
    t_LPAREN = r'\('
    t_RPAREN = r'\)'
    t_LBRACE = r'{'
    t_RBRACE = r'}'
    t_LBRACKET = r'\['
    t_RBRACKET = r'\]'
    t_COMMA = r','
    t_COLON = r':'
    t_DOT = r'\.'
    t_AMPERSAND = r'&'
    t_SEMICOLON = r';'

    def t_FLOAT(self, t):
        r'\d+\.\d*([eE][-+]?\d+)?|\.\d+([eE][-+]?\d+)?'
        t.value = float(t.value)
        return t

    def t_INTEGER(self, t):
        r'\d+'
        t.value = int(t.value)
        return t

    def t_ID(self, t):
        r'[a-zA-Z_][a-zA-Z_0-9]*'
        t.type = keywords.get(t.value, 'ID')
        return t

    # Rule for starting a string literal
    def t_STRING_START(self, t):
        r'"'
        self.interpolation_stack.append(0)
        return t

    def t_newline(self, t):
        r'\n+'
        t.lexer.lineno += len(t.value)

    # Error handling in INITIAL state
    def t_error(self, t):
        print(f"Illegal character '{t.value[0]}' at line {t.lineno}, position {t.lexpos}")
        t.lexer.skip(1)

    # --- interpolation State Rules ---

    # Match the start of an interpolation expression ${
    def t_INTERPOL_START(self, t):
        r'\$\{'
        if self.interpolation_stack:
            self.interpolation_stack[-1] += 1
            self.lexer.push_state('interpolation')
        return t

    # Match the literal text part inside the string
    def t_STRING_LITERAL(self, t):
        r'"[^"]*"'
        t.value = t.value[1:-1]  # Remove quotes
        return t

    # Match the end of the string "
    def t_STRING_END(self, t):
        r'"'
        if self.interpolation_stack:
            self.interpolation_stack.pop()
        return t

    def t_interpolation_newline(self, t):
        r'\n+'
        t.lexer.lineno += len(t.value)

    # Error handling in interpolation state
    def t_interpolation_error(self, t):
        print(f"Illegal character in interpolation '{t.value[0]}' at line {t.lineno}, position {t.lexpos}")
        t.lexer.skip(1)

    # --- INITIAL State (Resumed inside ${...}) ---

    # Track nested braces to handle complex interpolation expressions
    def t_INITIAL_LBRACE(self, t):
        r'{'
        if self.interpolation_stack:
            self.bracket_count += 1
        return t

    # Rule for ending an interpolation expression }
    def t_INITIAL_INTERPOL_END(self, t):
        r'}'
        if not self.interpolation_stack:
            # This is a normal closing brace outside of any interpolation
            t.type = 'RBRACE'
            return t
            
        self.bracket_count -= 1
        if self.bracket_count == 0:
            # This is actually the end of the interpolation
            t.lexer.pop_state() # Return to 'interpolation' state
            return t
        else:
            # This is a nested closing brace inside the interpolation expression
            t.type = 'RBRACE'
            return t

    # --- Helper method for column calculation ---
    def _find_column(self, lexpos):
        if not hasattr(self.ply_lexer, 'lexdata'): return -1
        last_cr = self.ply_lexer.lexdata.rfind('\n', 0, lexpos)
        if last_cr < 0:
            last_cr = -1
        column = (lexpos - last_cr)
        return column

    # --- Public Interface ---
    def tokenize(self, code):
        self._code = code
        self.ply_lexer.paren_count = 0 # Reset potential state variables
        self.interpolation_stack = [] # Reset stack
        self.bracket_count = 0 # Reset bracket counter
        self.ply_lexer.begin('INITIAL') # Ensure starting in INITIAL state
        self.ply_lexer.input(code)
        self.ply_lexer.lineno = 1 # Reset line number
        tok_list = []
        while True:
            ply_token = self.ply_lexer.token()
            if not ply_token:
                break
            tok_list.append(ply_token)
        # Check for unterminated string
        if self.ply_lexer.current_state() == 'interpolation':
            start_line = self.interpolation_stack[0] if self.interpolation_stack else '?'
            print(f"Lexer Error: Unterminated string literal (started on line {start_line})", file=sys.stderr)
        return tok_list

# --- Create a reusable lexer instance ---
lexer = Lexer()

# --- Convenience function ---
def tokenize(code):
    return lexer.tokenize(code)

# --- Example Usage ---
if __name__ == '__main__':
    print("--- Razen Language Lexer Test ---")
    
    # If a file is provided, tokenize it
    if len(sys.argv) > 1:
        try:
            with open(sys.argv[1], 'r') as file:
                code = file.read()
            print(f"\n--- Tokenizing file: {sys.argv[1]} ---")
            print(f"Input Code:\n```razenscript\n{code}\n```")
            tokens_result = tokenize(code)
            print("\nTokens:")
            if not tokens_result:
                print("  (No tokens produced)")
            for t in tokens_result:
                print(f"  {t}")
        except Exception as e:
            print(f"Error reading or tokenizing file: {e}")
        sys.exit(0)
        
    # Otherwise run test cases
    code_samples = [
        # General purpose variables
        'let num = 123.45\nshow num',
        'take message = "Hello\\n${name}!"',
        'hold isActive = true',
        'put data = null',
        
        # Mathematical variables
        'sum total = a + b',
        'diff result = price - cost',
        'prod amount = quantity * price',
        'div average = total / count',
        'mod remainder = value % divisor',
        
        # Logical variables
        'if count >= 10 && isActive == true { show "OK" }',
        'else { show "Not OK" }',
        'is valid = length > 0',
        'when ready { perform_action() }',
        'not isEmpty = items.length > 0',
        
        # String variables
        'text greeting = "Hello World"',
        'concat fullName = firstName + " " + lastName',
        'slice part = text.substring(0, 5)',
        'len size = text.length',
        
        # List & Array variables
        'list numbers = [1, 2, 3, 4]',
        'arr fixed = new Array(10)',
        'append(numbers, 5)',
        'remove(numbers, 2)',
        
        # Dictionary/Map variables
        'map settings = {"theme": "dark", "fontSize": 14}',
        'key firstKey = Object.keys(settings)[0]',
        'value fontSize = settings["fontSize"]',
        
        # Date & Time variables
        'current date = new Date()',
        'now timestamp = Date.now()',
        'year currentYear = date.getFullYear()',
        'month currentMonth = date.getMonth()',
        'day today = date.getDate()',
        'hour currentHour = date.getHours()',
        'minute currentMinute = date.getMinutes()',
        'second currentSecond = date.getSeconds()',
        
        # User-defined variables
        'store cache = new Map()',
        'box temp = calculateValue()',
        'ref pointer = &originalValue',
        
        # Input/Output variables
        'show "Output: ${value}"',
        'read userInput = prompt("Enter value:")',
        
        # Special test cases
        'show "Nested interpolation: ${ concat("Value: ", "${value}") }"',
        'show "Escaped characters: \\\\ \\" \\$ \\n \\t"',
        'show "Complex interpolation: ${ if (x > 10) { return "big" } else { return "small" } }"',
    ]

    for i, sample in enumerate(code_samples):
        print(f"\n--- Test Case {i+1} ---")
        print(f"Input Code:\n```razenscript\n{sample}\n```")
        try:
            tokens_result = tokenize(sample)
            print("\nTokens:")
            if not tokens_result:
                print("  (No tokens produced)")
            for t in tokens_result:
                print(f"  {t}")
        except Exception as e:
            import traceback
            print(f"\nError during tokenization: {e}")
            traceback.print_exc()
        print("-" * 40)