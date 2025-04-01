#!/usr/bin/env python3
# Debug script to examine tokens produced by the lexer

import sys
from src.lexer import tokenize

def main():
    # Get input from file or use a simple example
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r') as f:
            code = f.read()
    else:
        code = """
// Simple test
let num = 42
show "The number is: 42"
"""
    
    print("Input code:")
    print("=" * 50)
    print(code)
    print("=" * 50)
    
    # Tokenize the code
    tokens = tokenize(code)
    
    # Display tokens with details
    print("\nTokens:")
    print("=" * 50)
    for i, token in enumerate(tokens):
        print(f"{i}: {token.type} '{token.value}' at line {token.line}, column {token.column}")
    print("=" * 50)
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 