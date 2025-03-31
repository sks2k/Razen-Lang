# main.py
import argparse
import sys
import os
import traceback

# Ensure the src directory is in the Python path
project_root = os.path.dirname(os.path.abspath(__file__))
src_path = os.path.join(project_root, 'src')
if src_path not in sys.path:
    sys.path.insert(0, src_path)

# --- Imports ---
try:
    # --- MODIFICATION: Import the tokenize FUNCTION ---
    from lexer import tokenize as tokenize_code # Rename to avoid conflict if needed
    # --- MODIFICATION: Import the parse FUNCTION ---
    from parser import parse as parse_code
    # Keep Interpreter import
    from interpreter import Interpreter
except ImportError as e:
    print(f"Error importing modules from 'src': {e}", file=sys.stderr)
    print("Please ensure src/lexer.py, src/parser.py, src/interpreter.py exist and are correctly structured.", file=sys.stderr)
    # Add details about expected exports if helpful
    print("Expected: tokenize() in lexer.py, parse() in parser.py, Interpreter class in interpreter.py", file=sys.stderr)
    sys.exit(1)
except Exception as e: # Catch potential errors during import (like parser build failure)
     print(f"Error during initial module loading: {e}", file=sys.stderr)
     sys.exit(1)


# --- Execution Modes ---
MODE_RUN = 'run'
MODE_DEBUG = 'debug'
MODE_TEST = 'test'

def run_razen_code(filename, mode=MODE_RUN, debug_flags=None):
    """
    Reads, lexes, parses, and interprets a Razen file.
    Handles different execution modes.
    Uses imported tokenize and parse functions.
    """
    if debug_flags is None:
        debug_flags = {}

    try:
        if not os.path.isfile(filename):
            print(f"Error: File not found: {filename}", file=sys.stderr)
            return 1 # Return error code

        print(f"--- Running Razen ({mode} mode) on: {filename} ---", file=sys.stderr if mode != MODE_RUN else sys.stdout)

        with open(filename, 'r', encoding='utf-8') as f:
            code = f.read()

        # 1. Lexing (using the imported tokenize function)
        # --- MODIFICATION ---
        try:
            tokens = tokenize_code(code) # Call the function
        except Exception as lex_err: # Catch potential lexer errors early
             print(f"\n--- Lexer Error ---", file=sys.stderr)
             print(f"{lex_err}", file=sys.stderr)
             if mode == MODE_DEBUG:
                  traceback.print_exc(file=sys.stderr)
             return 1
        # --- END MODIFICATION ---

        if mode == MODE_DEBUG or debug_flags.get('show_tokens'):
            print("\n--- Tokens ---", file=sys.stderr)
            if tokens:
                for token in tokens:
                    # Use PLY token's default repr or customize
                    print(f"  {token}", file=sys.stderr)
            else:
                 print("  (No tokens generated)", file=sys.stderr)
            print("--------------", file=sys.stderr)


        # 2. Parsing (using the imported parse function)
        # --- MODIFICATION ---
        try:
             # Pass the original code string to the PLY parser function
             # Pass debug flag if parser supports it
             parse_debug_mode = (mode == MODE_DEBUG or debug_flags.get('show_ast')) # Pass debug if showing AST
             ast = parse_code(code, debug=parse_debug_mode)
        except Exception as parse_err: # Catch potential parser build or runtime errors
             print(f"\n--- Parser Error ---", file=sys.stderr)
             print(f"{parse_err}", file=sys.stderr)
             if mode == MODE_DEBUG:
                  traceback.print_exc(file=sys.stderr)
             return 1

        # Check if parsing failed (parser might return None or raise error)
        if ast is None and mode != MODE_RUN: # Parser often returns None on root error without raising
             print("\nParsing failed (Parser returned None). Check for Syntax Errors.", file=sys.stderr)
             return 1 # Indicate error
        # --- END MODIFICATION ---


        if mode == MODE_DEBUG or debug_flags.get('show_ast'):
             print("\n--- AST ---", file=sys.stderr)
             from pprint import pprint # Using pprint for basic AST view
             if ast is not None:
                 # Assuming AST is a list of statements from parser
                 if isinstance(ast, list):
                      for i, node in enumerate(ast):
                          print(f"Node {i}:", file=sys.stderr)
                          pprint(node, indent=2, stream=sys.stderr)
                 else: # Or maybe a single root node
                      pprint(ast, indent=2, stream=sys.stderr)
             else:
                  print("  (AST is None - Parsing likely failed)", file=sys.stderr)
             print("-----------", file=sys.stderr)

        # If parsing failed, don't attempt interpretation
        if ast is None:
             print("\nSkipping interpretation due to parsing failure.", file=sys.stderr)
             return 1

        # 3. Interpretation
        interpreter = Interpreter()
        # Pass debug flags to interpreter if it uses them
        # interpreter.debug_mode = (mode == MODE_DEBUG) # Example flag

        print(f"\n--- Output ({mode} mode) ---", file=sys.stderr if mode != MODE_RUN else sys.stdout)
        # The interpreter should handle printing output via 'show'/'print' itself.
        result = interpreter.interpret(ast) # Assuming interpret handles the AST root/list

        # Print the *final returned value* of the program only in debug/test for inspection
        if mode != MODE_RUN and result is not None:
             print(f"\n--- Final Result ({mode} mode) ---", file=sys.stderr)
             print(repr(result), file=sys.stderr)
             print("--------------------------", file=sys.stderr)

        if mode == MODE_TEST:
             print("\n--- Test Mode Checks ---", file=sys.stderr)
             print("Execution completed without fatal errors reported by main.py.", file=sys.stderr)
             print("(Further checks might be needed based on interpreter state or output)", file=sys.stderr)
             print("------------------------", file=sys.stderr)

        print(f"\n--- Finished Razen ({mode} mode) ---", file=sys.stderr if mode != MODE_RUN else sys.stdout)
        return 0 # Success code

    # --- Error Handling ---
    # Catch specific errors if needed, otherwise general Exception
    except SyntaxError as e: # Catch potential syntax errors missed by parser? Unlikely with PLY.
        print(f"\n--- Syntax Error ---", file=sys.stderr)
        print(f"{e}", file=sys.stderr)
        if mode == MODE_DEBUG:
            traceback.print_exc(file=sys.stderr)
        return 1
    except NameError as e: # From Interpreter (undefined variable)
         print(f"\n--- Name Error ---", file=sys.stderr)
         print(f"{e}", file=sys.stderr)
         if mode == MODE_DEBUG:
             traceback.print_exc(file=sys.stderr)
         return 1
    except Exception as e: # Catch all other runtime errors (Interpreter, etc.)
        print(f"\n--- Runtime Error ---", file=sys.stderr)
        print(f"An unexpected error occurred: {type(e).__name__}: {e}", file=sys.stderr)
        if mode == MODE_DEBUG:
            traceback.print_exc(file=sys.stderr)
        else:
            print("(Run in debug mode for full traceback)", file=sys.stderr)
        return 1


# --- Main Execution Block ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Razen Language Runner")
    parser.add_argument("filename", help="Path to the Razen (.rzn) file to execute.")
    parser.add_argument(
        "--mode",
        choices=[MODE_RUN, MODE_DEBUG, MODE_TEST],
        default=MODE_RUN,
        help="Execution mode (run, debug, test)."
    )
    parser.add_argument("--show-tokens", action="store_true", help="Show tokens (useful with debug/test mode)")
    parser.add_argument("--show-ast", action="store_true", help="Show AST (useful with debug/test mode)")

    args = parser.parse_args()

    debug_flags = {
        'show_tokens': args.show_tokens,
        'show_ast': args.show_ast,
    }

    exit_code = run_razen_code(args.filename, args.mode, debug_flags)
    sys.exit(exit_code)