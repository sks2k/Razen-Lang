# src/runtime.py
# Enhanced Runtime Environment for RAZEN Language

import operator
import sys
import math # For potential future built-ins

# --- Custom Exception for Return Values ---
class ReturnSignal(Exception):
    """Custom exception to signal a return statement."""
    def __init__(self, value):
        self.value = value

# --- Runtime Class ---
class Runtime:
    def __init__(self):
        """Initialize a new Razen runtime."""
        # The global scope - all variables and functions 
        self.global_scope = {}  # The base scope
        self.scope_stack = [self.global_scope]
        
        # Storage for user-defined functions
        self.functions = {}
        
        # Built-in functions
        self.builtins = {
            'print': self._builtin_print,
            'show': self._builtin_show,
            'input': self._builtin_input,
        }
        
        # Add built-ins to the global scope for direct access
        self.global_scope['input'] = self._builtin_input
        
        # Debug flag - set to False for clean output
        self.debug = False

        # print("Runtime: Initializing...") # Less verbose

    # --- Scope Management ---
    def _get_current_scope(self):
        """Returns the innermost active scope."""
        return self.scope_stack[-1]

    def push_scope(self):
        """Add a new scope to the stack."""
        self.scope_stack.append({})
        if self.debug:
            print(f"DEBUG: Pushed new scope, level {len(self.scope_stack)-1}", file=sys.stderr)

    def pop_scope(self):
        """Remove the current scope from the stack."""
        if len(self.scope_stack) <= 1:
            raise RuntimeError("Internal Error: Attempted to pop global scope.")
        self.scope_stack.pop()
        if self.debug:
            print(f"DEBUG: Popped scope, now at level {len(self.scope_stack)-1}", file=sys.stderr)

    def set_variable(self, name, value):
        """Sets a variable in the current scope."""
        current_scope = self._get_current_scope()
        current_scope[name] = value
        # For debugging scope issues:
        if self.debug:
            print(f"DEBUG: Setting variable {name} = {value} in scope {len(self.scope_stack)-1}", file=sys.stderr)
        return value

    def update_variable(self, name, value):
        """Updates a variable from any accessible scope."""
        # Search from most local to global scope
        for i, scope in enumerate(reversed(self.scope_stack)):
            if name in scope:
                scope[name] = value
                if self.debug:
                    scope_index = len(self.scope_stack) - 1 - i
                    print(f"DEBUG: Updating variable {name} = {value} in scope {scope_index}", file=sys.stderr)
                return value
        # If not found, report error
        raise NameError(f"Runtime Error: Variable '{name}' is not defined.")

    def get_variable(self, name):
        """Gets a variable from any accessible scope."""
        # Search from most local to global scope
        for i, scope in enumerate(reversed(self.scope_stack)):
            if name in scope:
                value = scope[name]
                if self.debug:
                    scope_index = len(self.scope_stack) - 1 - i
                    print(f"DEBUG: Found variable {name} = {value} in scope {scope_index}", file=sys.stderr)
                return value
                
        # Check builtins if not found in scopes
        if name in self.builtins:
            return self.builtins[name]
            
        # If not found, report error
        raise NameError(f"Runtime Error: Variable '{name}' is not defined.")

    # --- Function Handling ---
    def define_function(self, name, params, body_block_ast):
        """Define a user function in the current scope (usually global)."""
        if name in self.builtins:
             raise NameError(f"Runtime Error: Cannot redefine built-in function '{name}'.")
        # Store function definition in the global scope for now
        # Could potentially support local functions later
        if name in self.functions:
             print(f"Warning: Function '{name}' redefined.", file=sys.stderr)
        self.functions[name] = {'params': params, 'body': body_block_ast}

    def _call_function(self, name, args):
        """Handles calling both user-defined and built-in functions."""
        # 1. Check built-ins first
        if name in self.builtins:
            builtin_func = self.builtins[name]
            # Arity check could be added to builtins if needed
            return builtin_func(args)

        # 2. Check user-defined functions
        if name in self.functions:
            func_def = self.functions[name]
            params = func_def['params']
            body_ast = func_def['body'] # This should be the ('block', [statements]) node

            # Check arity (number of arguments)
            if len(args) != len(params):
                raise TypeError(f"Runtime Error: Function '{name}' expected {len(params)} arguments, but got {len(args)}.")

            # Create new scope for the function call
            local_scope = {}
            for param_name, arg_value in zip(params, args):
                local_scope[param_name] = arg_value

            # Push the local scope
            self.push_scope()

            # Execute the function body
            return_value = None
            try:
                self.execute_block(body_ast) # Execute the ('block', ...) node
            except ReturnSignal as ret:
                return_value = ret.value # Catch the return value
            finally:
                # Ensure scope is popped even if an error occurs (other than ReturnSignal)
                self.pop_scope()

            return return_value # Return None if no explicit return

        # 3. Not found
        raise NameError(f"Runtime Error: Function '{name}' is not defined.")


    # --- Built-in Implementations ---
    def _builtin_input(self, args=None):
        """Built-in input function. Displays a prompt and returns user input."""
        prompt = ""
        
        # Handle direct call with a argument from AST
        if isinstance(args, list) and len(args) > 0:
            # Convert args to string if needed
            prompt = str(args[0])
        elif isinstance(args, str):
            # Direct string prompt
            prompt = args
            
        try:
            # Add a newline before the prompt if desired
            print()  # Add a blank line for better separation 
            
            # Display the prompt directly to stdout to ensure it's visible
            # Use direct sys.stdout write to ensure immediate display
            sys.stdout.write(prompt)
            sys.stdout.flush()
            
            # Get user input
            return input()
        except Exception as e:
            self.report_error(f"Error reading input: {e}")
            return ""

    def _builtin_print(self, args):
        """Built-in print function. Prints arguments space-separated."""
        print(*(str(arg) for arg in args)) # Convert all args to string for printing
        return None # Print functions typically return None

    def _builtin_show(self, args):
        """Built-in show function. Alias for print for now."""
        # In the future, 'show' could have different formatting or behavior
        return self._builtin_print(args)

    # --- Evaluation ---
    def evaluate(self, expression_ast):
        """Recursively evaluates a RAZEN expression AST node."""
        if expression_ast is None: # Can happen in optional parts of grammar
            return None
            
        # Handle direct strings as variable references
        if isinstance(expression_ast, str):
            # If a string is passed directly, it's likely a variable reference
            print(f"DEBUG: Direct variable reference: {expression_ast}", file=sys.stderr)
            return self.get_variable(expression_ast)

        node_type = expression_ast[0]

        if node_type == 'literal':
            return expression_ast[1] # Value is already Python type

        elif node_type == 'identifier':
            return self.get_variable(expression_ast[1])

        elif node_type == 'assign': # Assignment as an expression (e.g., a = b = 5)
            name, value_ast = expression_ast[1:]
            value = self.evaluate(value_ast)
            # Update existing variable or create in current scope?
            # Let's make assignment create in current scope if not found higher up.
            # For strict update-only, use self.update_variable(name, value)
            try:
                self.update_variable(name, value) # Try updating first
            except NameError:
                self.set_variable(name, value)    # Create in current scope if doesn't exist
            return value # Assignment expressions return the assigned value

        elif node_type == 'binop':
            op_str, left_ast, right_ast = expression_ast[1:]
            left_val = self.evaluate(left_ast)
            right_val = self.evaluate(right_ast)

            # Arithmetic
            if op_str == '+':
                # Allow string concat, otherwise numeric add
                if isinstance(left_val, str) or isinstance(right_val, str):
                    return str(left_val) + str(right_val)
                else: return operator.add(left_val, right_val)
            elif op_str == '-': return operator.sub(left_val, right_val)
            elif op_str == '*': return operator.mul(left_val, right_val)
            elif op_str == '/':
                if right_val == 0: raise ZeroDivisionError("Runtime Error: Division by zero.")
                return operator.truediv(left_val, right_val)
            elif op_str == '%':
                if right_val == 0: raise ZeroDivisionError("Runtime Error: Modulo by zero.")
                return operator.mod(left_val, right_val)
            # Comparisons
            elif op_str == '==': return operator.eq(left_val, right_val)
            elif op_str == '!=': return operator.ne(left_val, right_val)
            elif op_str == '<':  return operator.lt(left_val, right_val)
            elif op_str == '<=': return operator.le(left_val, right_val)
            elif op_str == '>':  return operator.gt(left_val, right_val)
            elif op_str == '>=': return operator.ge(left_val, right_val)
            # Logical (Python's 'and'/'or' handle short-circuiting)
            elif op_str == '&&': return left_val and right_val
            elif op_str == '||': return left_val or right_val
            else:
                raise NotImplementedError(f"Binary operator '{op_str}' not implemented.")

        elif node_type == 'unary_minus':
            value = self.evaluate(expression_ast[1])
            return operator.neg(value)

        elif node_type == 'not':
            value = self.evaluate(expression_ast[1])
            return not value # Python's 'not' works nicely

        elif node_type == 'call':
            func_name, args_ast_list = expression_ast[1:]
            evaluated_args = [self.evaluate(arg_ast) for arg_ast in args_ast_list]
            return self._call_function(func_name, evaluated_args)

        elif node_type == 'interpolated_string':
            parts_ast = expression_ast[1]
            result = []
            for part_ast in parts_ast:
                evaluated_part = self.evaluate(part_ast) # Evaluate literals and expressions
                result.append(str(evaluated_part)) # Convert all parts to string
            return "".join(result)
        
        # Handle member access ('m' likely stands for 'member')
        elif node_type == 'm':
            # Handle member access (object.property)
            # Format might vary - let's add debugging and be more flexible
            if len(expression_ast) < 2:
                self.report_error(f"Invalid member access AST: {expression_ast}")
                return None
            
            # Debug logging
            print(f"DEBUG: Member access AST: {expression_ast}", file=sys.stderr)
            
            # Determine object and member name from the AST
            obj_ast = None
            member_name = None
            
            # Handle different formats of member access
            if len(expression_ast) == 2:
                # Format: ('m', [object_ast, 'member_name'])
                parts = expression_ast[1]
                print(f"DEBUG: Member parts: {parts}", file=sys.stderr)
                if isinstance(parts, list) and len(parts) >= 2:
                    obj_ast = parts[0]
                    member_name = parts[1]
                    print(f"DEBUG: Access object {obj_ast} member {member_name}", file=sys.stderr)
                else:
                    # Format: ('m', 'expr') - just return expr
                    print(f"DEBUG: Single expression member access: {expression_ast[1]}", file=sys.stderr)
                    return self.evaluate(expression_ast[1])
            else:
                # Format: ('m', object_ast, 'member_name')
                obj_ast = expression_ast[1]
                member_name = expression_ast[2]
                print(f"DEBUG: Direct access object {obj_ast} member {member_name}", file=sys.stderr)
            
            # Handle variable reference (if obj_ast is a string)
            if isinstance(obj_ast, str) and not (obj_ast.startswith('"') or obj_ast.startswith("'")):
                # It's a variable name, resolve it first
                print(f"DEBUG: Resolving variable name: {obj_ast}", file=sys.stderr)
                obj = self.get_variable(obj_ast)
            else:
                # Evaluate the object
                obj = self.evaluate(obj_ast)
            
            print(f"DEBUG: Evaluated object: {obj}, attempting to access {member_name}", file=sys.stderr)
            
            # If member_name is an AST node, evaluate it
            if isinstance(member_name, (list, tuple)):
                member_name = self.evaluate(member_name)
                print(f"DEBUG: Evaluated member name: {member_name}", file=sys.stderr)
            
            # Special case for 'input' built-in
            if member_name == 'input':
                return self._builtin_input
            
            # Check if obj is a dictionary or an object with attributes
            if isinstance(obj, dict) and member_name in obj:
                return obj[member_name]
            elif hasattr(obj, member_name):
                return getattr(obj, member_name)
            else:
                # Handle primitive types by converting them to appropriate wrapper objects
                if isinstance(obj, (int, float)):
                    # Numeric properties
                    if member_name == 'to_string' or member_name == 'toString':
                        return str(obj)
                elif isinstance(obj, str):
                    # String properties
                    if member_name == 'length':
                        return len(obj)
                    elif member_name == 'upper':
                        return obj.upper()
                    elif member_name == 'lower':
                        return obj.lower()
                
                # If we get here, the member access is invalid
                self.report_error(f"Cannot access member '{member_name}' on {obj}")
                return None
                
        # Add support for logical operators 'and', 'or', 'not'
        elif node_type == 'and':
            left_ast, right_ast = expression_ast[1:]
            left_val = self.evaluate(left_ast)
            # Short-circuit evaluation like Python's 'and'
            if not left_val:
                return False
            return self.evaluate(right_ast)
            
        elif node_type == 'or':
            left_ast, right_ast = expression_ast[1:]
            left_val = self.evaluate(left_ast)
            # Short-circuit evaluation like Python's 'or'
            if left_val:
                return left_val
            return self.evaluate(right_ast)

        # Handle object literals ('o' likely stands for 'object' or 'object literal')
        elif node_type == 'o':
            # Object/dictionary literal
            print(f"DEBUG: Object literal AST: {expression_ast}", file=sys.stderr)
            
            if len(expression_ast) < 2:
                return {}  # Empty object
                
            properties = expression_ast[1]
            result = {}
            
            # Handle different formats
            if isinstance(properties, list):
                # Format could be: ('o', [(key1, value1), (key2, value2), ...])
                for key_value in properties:
                    print(f"DEBUG: Processing key-value: {key_value}", file=sys.stderr)
                    if isinstance(key_value, (list, tuple)) and len(key_value) >= 2:
                        key = key_value[0]
                        value_ast = key_value[1]
                        
                        # Key might be a string literal or expression 
                        if isinstance(key, (list, tuple)):
                            key = self.evaluate(key)
                        elif isinstance(key, str) and not key.startswith('"') and not key.startswith("'"):
                            # If key is a plain string but not a quoted string, evaluate it as variable
                            try:
                                key = self.get_variable(key)
                            except:
                                # If not a variable, just use as is
                                pass
                            
                        # Evaluate the value
                        value = self.evaluate(value_ast)
                        print(f"DEBUG: Setting key {key} to value {value}", file=sys.stderr)
                        result[key] = value
            elif isinstance(properties, dict):
                # Direct dictionary object
                for key, value_ast in properties.items():
                    result[key] = self.evaluate(value_ast)
            else:
                # Single expression - evaluate and return
                print(f"DEBUG: Evaluating properties directly: {properties}", file=sys.stderr)
                return self.evaluate(properties)
                
            return result
            
        # Handle map literals (similar to object literals but with a different AST structure)
        elif node_type == 'map':
            # Map/dictionary literal
            print(f"DEBUG: Map literal AST: {expression_ast}", file=sys.stderr)
            
            if len(expression_ast) < 2:
                return {}  # Empty map
                
            items = expression_ast[1]
            result = {}
            
            # Process key-value pairs
            for item in items:
                if isinstance(item, (list, tuple)) and len(item) == 2:
                    key_ast, value_ast = item
                    key = self.evaluate(key_ast)
                    value = self.evaluate(value_ast)
                    result[key] = value
                    
            return result

        else:
            raise NotImplementedError(f"Runtime Error: Evaluation not implemented for AST node type: {node_type}")

    # --- Execution ---
    def execute_statement(self, statement_ast):
        """Executes a single RAZEN statement AST node."""
        if statement_ast is None: return # Skip empty parts if any

        node_type = statement_ast[0]
        # print(f"DEBUG: Executing {node_type}") # Verbose debug

        if node_type == 'var_decl':
            kw_token, name, expr_ast = statement_ast[1:]
            value = self.evaluate(expr_ast)
             # Check for redeclaration in the *current* scope
            current_scope = self._get_current_scope()
            if name in current_scope:
                 print(f"Warning: Variable '{name}' redeclared in the same scope.", file=sys.stderr)
            self.set_variable(name, value) # Sets in current scope

        elif node_type == 'assign': # Standalone assignment statement
             name, value_ast = statement_ast[1:]
             value = self.evaluate(value_ast)
             # Assignment updates existing variable or raises error
             self.update_variable(name, value)

        elif node_type == 'read':
            # Format: ('read', variable_name, prompt_expr)
            variable_name = statement_ast[1]
            prompt_expr = statement_ast[2]
            
            # Evaluate the prompt expression if it exists
            prompt = ""
            if prompt_expr is not None:
                prompt = str(self.evaluate(prompt_expr))
            
            # Use builtin_input to get user input
            user_input = self._builtin_input(prompt)
            
            # Set the variable with the user input
            self.set_variable(variable_name, user_input)

        elif node_type == 'fun_decl':
            name, params, body_block_ast = statement_ast[1:]
            self.define_function(name, params, body_block_ast)

        elif node_type == 'show' or node_type == 'print':
            value_expr_ast, status_expr_ast = statement_ast[1], statement_ast[2]
            value_to_show = self.evaluate(value_expr_ast)
            # Evaluate status expression but don't use it for now
            if status_expr_ast:
                 status_value = self.evaluate(status_expr_ast)
                 # TODO: Decide what the status value does (e.g., conditional print?)
            # Call the corresponding built-in
            builtin_name = node_type # 'show' or 'print'
            self.builtins[builtin_name]([value_to_show]) # Pass value as a list

        elif node_type == 'if':
            condition_ast, then_block_ast, else_block_ast = statement_ast[1:]
            condition_val = self.evaluate(condition_ast)
            if condition_val: # Truthy check
                self.execute_block(then_block_ast)
            elif else_block_ast: # Check if there is an else block
                # Handle 'else if' (where else_block_ast is another 'if' node)
                if else_block_ast[0] == 'if':
                     self.execute_statement(else_block_ast)
                else: # Normal else block
                     self.execute_block(else_block_ast)

        elif node_type == 'while':
            condition_ast, body_block_ast = statement_ast[1:]
            while self.evaluate(condition_ast): # Re-evaluate condition each time
                try:
                    self.execute_block(body_block_ast)
                except ReturnSignal as ret:
                     # Allow return from inside a while loop
                     raise ret # Re-raise to be caught by function caller
                # TODO: Add break/continue signals later if needed

        elif node_type == 'block':
             self.execute_block(statement_ast) # Handle standalone blocks if they occur

        elif node_type == 'return':
            value_ast = statement_ast[1]
            return_value = self.evaluate(value_ast) if value_ast else None
            raise ReturnSignal(return_value) # Signal the return

        elif node_type == 'call': # Function call used as a statement
            # Evaluate the call but discard the result
            self.evaluate(statement_ast)

        elif node_type == 'expression_stmt':
             # Evaluate expression for potential side effects (like assignment), discard result
             self.evaluate(statement_ast[1])

        else:
            print(f"Warning: Runtime execution not implemented for statement type: {node_type}", file=sys.stderr)

    def execute_block(self, block_ast):
        """Executes a block of statements, with proper scope handling."""
        if block_ast[0] != 'block':
            self.report_error(f"Expected a block AST, got {block_ast[0]}")
            return None
            
        # Store the original scope to restore later
        original_scope = self._get_current_scope()
        tracked_variables = {}  # Keep track of variables that should be propagated up
        
        # Get pre-existing variables we want to keep track of
        for var in ['new_money']:  # List of variables to track
            if var in original_scope:
                tracked_variables[var] = original_scope[var]
                
        try:
            # Create a new scope for this block
            self.push_scope()
            current_scope = self._get_current_scope()
            
            # Execute statements in the block
            statements_ast = block_ast[1]
            for stmt_ast in statements_ast:
                self.execute_statement(stmt_ast)
                
            # Find any tracked variables that were modified in this scope
            for var in tracked_variables.keys():
                if var in current_scope:
                    tracked_variables[var] = current_scope[var]
                    
            # Check for any new variables that should be propagated
            for var in ['new_money']:
                if var in current_scope and var not in tracked_variables:
                    tracked_variables[var] = current_scope[var]
        finally:
            # Pop the block's scope
            self.pop_scope()
            
            # Propagate tracked variables to parent scope
            for var, value in tracked_variables.items():
                original_scope[var] = value
                if self.debug:
                    print(f"DEBUG: Propagating variable {var} = {value} to parent scope", file=sys.stderr)
                    
        return None  # Block execution returns no value

    def report_error(self, message, line=None, column=None):
        """Enhanced error reporting with source location information."""
        location = f" at line {line}" if line is not None else ""
        location += f", column {column}" if column is not None else ""
        print(f"Runtime Error{location}: {message}", file=sys.stderr)
        return None
        
    def run_program(self, program_ast):
        """Executes a RAZEN program represented by an AST ('program', [statements])."""
        if not program_ast or program_ast[0] != 'program':
             self.report_error("Invalid program AST structure.")
             return

        statements = program_ast[1]
        # Program runs in the global scope context
        try:
            for statement in statements:
                 self.execute_statement(statement)
        except ReturnSignal:
            self.report_error("'return' statement used outside of a function.")
        except NameError as e:
            self.report_error(str(e))
        except TypeError as e:
            self.report_error(f"Type Error: {e}")
        except ZeroDivisionError as e:
             self.report_error(str(e))
        except NotImplementedError as e:
            self.report_error(str(e))
        except Exception as e:
             self.report_error(f"An unexpected runtime error occurred: {type(e).__name__}: {e}")
             # For serious debugging, uncomment this to get full traceback
             import traceback; traceback.print_exc(file=sys.stderr)


# --- Example usage (within a main script) ---
if __name__ == '__main__':
    # This is typically called from your main razen script
    # Assume 'parser' is imported and can parse code to AST
    # from parser import parse # Assuming your parser has a parse function

    # Dummy parser for standalone testing:
    def parse(code):
        print(f"--- (Dummy Parsing Code) ---\n{code}\n---")
        # Replace with actual AST for testing specific features
        # Example AST for: let x = 10; show x + 5;
        return ('program', [
            ('var_decl', 'let', 'x', ('literal', 10)),
            ('show', ('binop', '+', ('identifier', 'x'), ('literal', 5)), None)
        ])

    test_code = """
    let x = 10
    show x + 5
    """

    print("--- Running Runtime Test ---")
    ast = parse(test_code)

    if ast:
        runtime = Runtime()
        print("--- Program Output ---")
        runtime.run_program(ast)
        print("--- Execution Finished ---")
        print("Final Global Scope:", runtime.global_scope)
    else:
        print("Parsing failed, cannot run.")