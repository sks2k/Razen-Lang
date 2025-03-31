# src/parser.py
# Enhanced Parser for RAZEN (Revised for Interpolation, Optional Semicolons, and All Variable Types)

import os
import ply.yacc as yacc
import sys
from lexer import tokens, lexer as razel_lexer

# --- AST Node Definitions (Using tuples for simplicity) ---
# Program: ('program', [statements])
# Statement: Various ('var_decl', 'show', 'if', 'assign', 'call', etc.)
# Expressions: Various ('binop', 'literal', 'identifier', 'call', 'interpolated_string', etc.)
# Interpolated String: ('interpolated_string', [parts]) where parts are ('literal', str) or expression nodes

# --- Grammar Rules ---

def p_program(p):
    '''program : statements'''
    p[0] = ('program', p[1] if p[1] else [])

def p_statements_list(p):
    '''statements : statements statement
                 | statements block_stmt'''
    if p[2]:
        p[0] = p[1] + [p[2]]
    else:
        p[0] = p[1]

def p_statements_single(p):
    '''statements : statement
                 | block_stmt'''
    p[0] = [p[1]] if p[1] else []

def p_statements_empty(p):
    '''statements : empty'''
    p[0] = []

def p_block_stmt(p):
    '''block_stmt : LBRACE statements RBRACE'''
    p[0] = ('block', p[2])

# --- Statement Types ---
def p_statement(p):
    '''statement : variable_decl
                 | reference_decl
                 | function_decl
                 | show_stmt
                 | print_stmt
                 | read_stmt
                 | if_stmt
                 | when_stmt
                 | while_stmt
                 | return_stmt
                 | expression_stmt'''
    p[0] = p[1]

# --- Variable Declaration ---
def p_variable_decl(p):
    '''variable_decl : LET ID ASSIGN expression
                     | TAKE ID ASSIGN expression
                     | HOLD ID ASSIGN expression
                     | PUT ID ASSIGN expression
                     | SUM ID ASSIGN expression
                     | DIFF ID ASSIGN expression
                     | PROD ID ASSIGN expression
                     | DIV ID ASSIGN expression
                     | MOD ID ASSIGN expression
                     | TEXT ID ASSIGN expression
                     | CONCAT ID ASSIGN expression
                     | SLICE ID ASSIGN expression
                     | LEN ID ASSIGN expression
                     | LIST ID ASSIGN expression
                     | ARR ID ASSIGN expression
                     | APPEND ID ASSIGN expression
                     | REMOVE ID ASSIGN expression
                     | MAP ID ASSIGN expression
                     | KEY ID ASSIGN expression
                     | VALUE ID ASSIGN expression
                     | CURRENT ID ASSIGN expression
                     | NOW ID ASSIGN expression
                     | YEAR ID ASSIGN expression
                     | MONTH ID ASSIGN expression
                     | DAY ID ASSIGN expression
                     | HOUR ID ASSIGN expression
                     | MINUTE ID ASSIGN expression
                     | SECOND ID ASSIGN expression
                     | STORE ID ASSIGN expression
                     | BOX ID ASSIGN expression
                     | REF ID ASSIGN ref_expression'''
    if p[1] == 'ref' and len(p) == 5:
        p[0] = ('var_decl', p[1], p[2], p[4])
    else:
        p[0] = ('var_decl', p[1], p[2], p[4])

def p_ref_expression(p):
    '''ref_expression : AMPERSAND ID'''
    p[0] = ('reference', p[2])

# --- Function Declaration ---
def p_function_decl(p):
    '''function_decl : FUN ID LPAREN params_opt RPAREN block_stmt'''
    p[0] = ('fun_decl', p[2], p[4], p[6])

def p_params_opt(p):
    '''params_opt : param_list
                 | empty'''
    p[0] = p[1] if p[1] is not None else []

def p_param_list_multi(p):
    '''param_list : param_list COMMA param'''
    p[0] = p[1] + [p[3]]

def p_param_list_single(p):
    '''param_list : param'''
    p[0] = [p[1]]

def p_param(p):
    '''param : ID'''
    p[0] = p[1]

# --- Input/Output Statements ---
def p_show_stmt(p):
    '''show_stmt : SHOW expression opt_colon_expression
                | SHOW expression'''
    if len(p) == 4:  # Includes colon expression
        p[0] = ('show', p[2], p[3])
    else:
        p[0] = ('show', p[2], None)

def p_print_stmt(p):
    '''print_stmt : PRINT expression opt_colon_expression
                 | PRINT expression'''
    if len(p) == 4:
        p[0] = ('print', p[2], p[3])
    else:
        p[0] = ('print', p[2], None)

def p_read_stmt(p):
    '''read_stmt : READ ID opt_assign_expression
                | READ ID'''
    if len(p) == 4:
        p[0] = ('read', p[2], p[3])
    else:
        p[0] = ('read', p[2], None)

def p_opt_colon_expression(p):
    '''opt_colon_expression : COLON expression'''
    p[0] = p[2]

def p_opt_assign_expression(p):
    '''opt_assign_expression : ASSIGN expression'''
    p[0] = p[2]

# --- Control Flow Statements ---
def p_if_stmt(p):
    '''if_stmt : IF expression block_stmt else_opt'''
    p[0] = ('if', p[2], p[3], p[4])

def p_when_stmt(p):
    '''when_stmt : WHEN expression IS expression block_stmt else_opt'''
    p[0] = ('when', p[2], p[4], p[5], p[6])

def p_else_opt(p):
    '''else_opt : ELSE block_stmt
               | ELSE if_stmt
               | ELSE when_stmt
               | empty'''
    if len(p) == 3:
        p[0] = p[2]
    else:
        p[0] = None

def p_while_stmt(p):
    '''while_stmt : WHILE expression block_stmt'''
    p[0] = ('while', p[2], p[3])

def p_return_stmt(p):
    '''return_stmt : RETURN expression
                  | RETURN'''
    if len(p) == 3:
        p[0] = ('return', p[2])
    else:
        p[0] = ('return', None)

# --- Expression Statement ---
def p_expression_stmt(p):
    '''expression_stmt : expression'''
    if isinstance(p[1], tuple) and p[1][0] in ('assign', 'call', 'member'):
        p[0] = p[1]
    else:
        p[0] = ('expression_stmt', p[1])

# --- Expressions ---
precedence = (
    ('left', 'OR'),
    ('left', 'AND'),
    ('nonassoc', 'EQ', 'NE', 'LT', 'LE', 'GT', 'GE'),
    ('left', 'PLUS', 'MINUS'),
    ('left', 'MULTIPLY', 'DIVIDE', 'MODULO'),
    ('right', 'NOT', 'IS'),
    ('right', 'UMINUS'),
    ('right', 'AMPERSAND'),  # Add precedence for reference operator
    ('left', 'LPAREN', 'RPAREN', 'LBRACKET', 'RBRACKET'),
)

def p_expression_assign(p):
    '''expression : ID ASSIGN expression'''
    p[0] = ('assign', p[1], p[3])

def p_expression_binop(p):
    '''expression : expression PLUS expression
                 | expression MINUS expression
                 | expression MULTIPLY expression
                 | expression DIVIDE expression
                 | expression MODULO expression
                 | expression EQ expression
                 | expression NE expression
                 | expression LT expression
                 | expression LE expression
                 | expression GT expression
                 | expression GE expression
                 | expression AND expression
                 | expression OR expression'''
    p[0] = ('binop', p[2], p[1], p[3])

def p_expression_comparison(p):
    '''expression : expression IS expression'''
    p[0] = ('is', p[1], p[3])

def p_expression_unary_minus(p):
    '''expression : MINUS expression %prec UMINUS'''
    p[0] = ('unary_minus', p[2])

def p_expression_not(p):
    '''expression : NOT expression'''
    p[0] = ('not', p[2])

def p_expression_group(p):
    '''expression : LPAREN expression RPAREN'''
    p[0] = p[2]

def p_expression_terminals(p):
    '''expression : literal
                 | ID
                 | function_call
                 | interpolated_string
                 | list_expression
                 | map_expression
                 | member_expression
                 | index_expression
                 | slice_expression'''
    p[0] = p[1]

def p_member_expression(p):
    '''member_expression : expression DOT ID'''
    p[0] = ('member', p[1], p[3])

def p_member_call(p):
    '''member_expression : expression DOT ID LPAREN args_opt RPAREN'''
    p[0] = ('call', ('member', p[1], p[3]), p[5])

def p_index_expression(p):
    '''index_expression : expression LBRACKET expression RBRACKET'''
    p[0] = ('index', p[1], p[3])

def p_slice_expression(p):
    '''slice_expression : expression LBRACKET expression COLON expression RBRACKET'''
    p[0] = ('slice', p[1], p[3], p[5])

def p_list_expression(p):
    '''list_expression : LBRACKET list_items RBRACKET'''
    p[0] = ('list', p[2])

def p_list_items(p):
    '''list_items : list_items COMMA expression
                 | expression
                 | empty'''
    if len(p) == 4:
        p[0] = p[1] + [p[3]]
    elif len(p) == 2 and p[1] is not None:
        p[0] = [p[1]]
    else:
        p[0] = []

def p_map_expression(p):
    '''map_expression : LBRACE map_items RBRACE'''
    p[0] = ('map', p[2])

def p_map_items(p):
    '''map_items : map_items COMMA map_item
                | map_item
                | empty'''
    if len(p) == 4:
        p[0] = p[1] + [p[3]]
    elif len(p) == 2 and p[1] is not None:
        p[0] = [p[1]]
    else:
        p[0] = []

def p_map_item(p):
    '''map_item : expression COLON expression'''
    p[0] = (p[1], p[3])

def p_literal(p):
    '''literal : INTEGER
               | FLOAT
               | TRUE
               | FALSE
               | NULL
               | STRING_LITERAL'''
    if isinstance(p[1], str) and p.slice[1].type == 'STRING_LITERAL':
        p[0] = ('literal', p[1])
    else:
        p[0] = ('literal', p[1])

def p_function_call(p):
    '''function_call : ID LPAREN args_opt RPAREN'''
    p[0] = ('call', p[1], p[3])

def p_args_opt(p):
    '''args_opt : arg_list
               | empty'''
    p[0] = p[1] if p[1] is not None else []

def p_arg_list_multi(p):
    '''arg_list : arg_list COMMA expression'''
    p[0] = p[1] + [p[3]]

def p_arg_list_single(p):
    '''arg_list : expression'''
    p[0] = [p[1]]

def p_interpolated_string(p):
    '''interpolated_string : STRING_START string_contents STRING_END'''
    p[0] = ('interpolated_string', p[2])

def p_string_contents_list(p):
    '''string_contents : string_contents string_part'''
    p[0] = p[1] + [p[2]]

def p_string_contents_single(p):
    '''string_contents : string_part'''
    p[0] = [p[1]]

def p_string_contents_empty(p):
    '''string_contents : empty'''
    p[0] = []

def p_string_part(p):
    '''string_part : STRING_LITERAL
                  | INTERPOL_START expression INTERPOL_END'''
    if len(p) == 2:
        p[0] = ('literal', p[1])
    else:
        p[0] = p[2]

def p_empty(p):
    '''empty :'''
    p[0] = None

def p_expression_reference(p):
    '''expression : AMPERSAND ID %prec AMPERSAND'''
    p[0] = ('reference', p[2])

# --- Error Rule ---
def p_error(p):
    if p:
        try:
            line = p.lineno
            col = razel_lexer._find_column(p.lexpos) if hasattr(razel_lexer, '_find_column') else '?'
            print(f"Syntax error at line {line}, column {col}: Unexpected token '{p.type}' ('{p.value}')", file=sys.stderr)
        except AttributeError:
            print(f"Syntax error: Unexpected token '{getattr(p, 'type', 'UNKNOWN')}' ('{getattr(p, 'value', 'UNKNOWN')}')", file=sys.stderr)
    else:
        print("Syntax error: Unexpected end of file (perhaps missing closing '}', ']', or '\"'?)", file=sys.stderr)

# --- Build the parser ---
try:
    output_dir = os.path.dirname(__file__) or '.'
    tabmodule_name = "razen_parsetab_interp"
    parser = yacc.yacc(
        module=sys.modules[__name__],
        outputdir=output_dir,
        tabmodule=tabmodule_name,
        debug=False,
        errorlog=yacc.NullLogger(),
        optimize=1,
        write_tables=True,
        picklefile=tabmodule_name + ".pickle"
    )
    print("Parser built successfully.")
except Exception as e:
    print(f"CRITICAL ERROR: Failed to build parser: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()
    raise SystemExit("Parser construction failed.")

def parse(code_string, debug=False):
    """Parses a Razen code string."""
    if not code_string:
        return ('program', [])

    # Reset lexer state before parsing
    razel_lexer.ply_lexer.lineno = 1
    razel_lexer.ply_lexer.lexpos = 0
    razel_lexer.interpolation_stack = []
    razel_lexer.ply_lexer.begin('INITIAL')

    # Debugging for ref operator
    if '&' in code_string:
        print("Code contains reference operator. Adding special handling...")
        # Replace reference expressions with a temporary placeholder
        code_string = code_string.replace("&", "__REF__")
        def restore_reference(tokens):
            new_tokens = []
            for t in tokens:
                if t.type == 'ID' and t.value == '__REF__':
                    t.type = 'AMPERSAND'
                    t.value = '&'
                new_tokens.append(t)
            return new_tokens
    else:
        def restore_reference(tokens):
            return tokens

    try:
        result = parser.parse(code_string, lexer=razel_lexer.ply_lexer, debug=debug)
        if result is None and code_string.strip():
            print("Parsing failed to produce a valid AST.", file=sys.stderr)
            return None
        return result
    except Exception as e:
        print(f"Parser Exception during parse(): {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return None

# --- Example Usage ---
if __name__ == '__main__':
    from lexer import tokenize as razel_tokenize

    test_code = """
    // Example Razen code showcasing all variable types
    let number = 150000
    take product = "iPhone"
    hold is_available = true
    put mixed_data = "Can store any type"

    sum total = 1000 + 500
    diff remaining = 2000 - 1500
    prod result = 25 * 4
    div quotient = 100 / 5
    mod remainder = 10 % 3

    text message = "Hello, world!"
    concat full_name = "John " + "Doe"
    slice first_name = "John Doe"[0:4]
    len name_length = full_name.length()

    list numbers = [1, 2, 3, 4, 5]
    arr fixed_size = [10, 20, 30]
    append updated_list = numbers.push(6)
    remove filtered_list = numbers.pop()

    map user = {"name": "John", "age": 30}
    key user_keys = user.keys()
    value user_values = user.values()

    current current_time = getCurrentTime()
    now timestamp = getTimestamp()
    year current_year = 2025
    month current_month = 3
    day current_day = 30
    hour current_hour = 14
    minute current_minute = 30
    second current_second = 45

    store cached_value = "This will be reused"
    box temp_data = {"temporary": true}
    ref reference_value = &another_value

    if number > 100000 {
        show "Expensive product: ${product}" : true
    } else {
        show "Affordable product: ${product}" : false
    }

    when is_available is true {
        show "Product is available!"
    }

    show "Welcome to the store!"
    print "Debug information: ${mixed_data}"
    read user_input = "Enter your name: "
    read simple_input

    fun calculate_total(price, quantity) {
        return price * quantity
    }

    let final_price = calculate_total(500, 3)
    show "Final price: ${final_price}"
    """

    print("\n--- Input Code ---")
    print(test_code)

    print("\n--- Tokens ---")
    tokens_list = razel_tokenize(test_code)
    if tokens_list:
        for tok in tokens_list:
            print(tok)
    else:
        print("(Lexing might have failed)")

    print("\n--- AST ---")
    ast = parse(test_code, debug=False)

    if ast:
        import pprint
        pprint.pprint(ast)
    else:
        print("Parsing failed or produced no result.")

    print("\n--- Testing Error Cases ---")
    error_codes = [
        'let a = "unterminated string',  # Unterminated string
        'if x { show "ok" } else { show "no" }',  # Corrected syntax
        'show "${var}"',  # Correct interpolation
        'map invalid = {"key": "value"}',  # Complete map
        'list unclosed = [1, 2, 3]',  # Complete list
    ]
    for i, err_code in enumerate(error_codes):
        print(f"\n--- Error Test {i+1} ---")
        print(f"Code:\n```\n{err_code}\n```")
        parse(err_code)

# Add a new rule for reference declarations
def p_reference_decl(p):
    '''reference_decl : REF ID ASSIGN AMPERSAND ID'''
    p[0] = ('var_decl', p[1], p[2], ('reference', p[5]))