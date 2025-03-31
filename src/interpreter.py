# Auto-generated Interpreter Frontend for RAZEN
# Generated on: 2025-03-30 18:50:42

import sys
import os
from runtime import Runtime
from parser import parse

class Interpreter:
    def __init__(self):
        self.runtime = Runtime()

    def interpret_file(self, file_path):
        """Parse and run a RAZEN file."""
        print(f"--- Interpreting File: {file_path} ---")
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                code = f.read()
            if not code.strip():
                print("(File is empty)")
                return
            ast = parse(code) # Call the parser
            if ast:
                 # print("--- AST ---") # Debug: Print AST
                 # from pprint import pprint; pprint(ast)
                 # print("--- Execution ---")
                 self.runtime.run_program(ast) # Execute using runtime
            else:
                 print(f"Parsing failed for {file_path}. No AST generated.", file=sys.stderr)
        except FileNotFoundError:
            print(f"Error: File not found '{file_path}'", file=sys.stderr)
        except Exception as e:
            print(f"An error occurred during file interpretation: {e}", file=sys.stderr)
        finally:
            print(f"--- Finished Interpreting: {file_path} ---")

    def interpret_string(self, code):
        """Parse and run a RAZEN code string."""
        try:
            if not code.strip(): return
            ast = parse(code)
            if ast:
                 self.runtime.run_program(ast)
            else:
                 print("Parsing failed. No AST generated.", file=sys.stderr)
        except Exception as e:
            print(f"An error occurred during string interpretation: {e}", file=sys.stderr)

    def start_repl(self):
        """Start a basic Read-Eval-Print Loop."""
        print("RAZEN REPL v0.1 (Experimental)")
        print("Enter 'exit' or press Ctrl+D to quit.")
        while True:
            try:
                line = input("razen> ")
                line_strip = line.strip()
                if line_strip.lower() == 'exit':
                    break
                if line_strip:
                    self.interpret_string(line)
            except EOFError:
                print("\nExiting REPL.")
                break
            except KeyboardInterrupt:
                print("\nInterrupted. Type 'exit' to quit.")
            except Exception as e:
                print(f"REPL Error: {e}", file=sys.stderr)
        print("REPL session ended.")

    def interpret(self, ast):
        """Execute an already parsed AST."""
        try:
            if ast:
                return self.runtime.run_program(ast)
            else:
                print("No valid AST to interpret.", file=sys.stderr)
                return None
        except Exception as e:
            print(f"An error occurred during AST interpretation: {e}", file=sys.stderr)
            return None
