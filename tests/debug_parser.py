#!/usr/bin/env python3

import sys
import os
import logging
from typing import List, Dict, Any, Optional

# Add the parent directory to sys.path to import from src
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.lexer import tokenize, Token
from src.parser import Parser

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def debug_parse(code: str):
    """Parse with extra debug information."""
    print("Tokenizing code...")
    tokens = tokenize(code)
    
    print("\nTokens:")
    for i, token in enumerate(tokens):
        print(f"{i}: {token.type} '{token.value}' at line {token.line}, column {token.column}")
    
    # Create a parser with very limited recursion depth
    parser = Parser(tokens)
    parser.max_recursion_depth = 25  # Set a low limit to catch recursion earlier
    
    print("\nParsing with modified Parser class...")
    
    # Original methods that we will monkey patch
    original_equality = parser.equality
    original_comparison = parser.comparison
    original_term = parser.term
    original_factor = parser.factor
    original_unary = parser.unary
    original_primary = parser.primary
    original_assignment = parser.assignment
    
    # Tracking call stack
    call_stack = []
    
    # Wrapper functions with debugging
    def debug_wrapper(f, name):
        def wrapped(*args, **kwargs):
            indent = "  " * len(call_stack)
            call_stack.append(name)
            print(f"{indent}Entering {name}: current token = {parser.peek().type} '{parser.peek().value}'")
            
            try:
                result = f(*args, **kwargs)
                indent = "  " * len(call_stack)
                print(f"{indent}Exiting {name}: result = {result}")
                call_stack.pop()
                return result
            except Exception as e:
                indent = "  " * len(call_stack)
                print(f"{indent}ERROR in {name}: {e}")
                call_stack.pop()
                raise
        return wrapped
    
    # Patch methods with debug wrappers
    parser.equality = debug_wrapper(original_equality, "equality")
    parser.comparison = debug_wrapper(original_comparison, "comparison")
    parser.term = debug_wrapper(original_term, "term")
    parser.factor = debug_wrapper(original_factor, "factor")
    parser.unary = debug_wrapper(original_unary, "unary")
    parser.primary = debug_wrapper(original_primary, "primary")
    parser.assignment = debug_wrapper(original_assignment, "assignment")
    
    try:
        ast = parser.parse()
        if ast:
            print("\nParsed AST:")
            print(ast)
        else:
            print("\nFailed to parse AST")
    except Exception as e:
        print(f"\nError during parsing: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            code = f.read()
            debug_parse(code)
    else:
        # Simple test code
        code = """
// Simple test code
let x = 42
show "Hello, world!"
"""
        debug_parse(code) 