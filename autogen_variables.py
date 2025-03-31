# autogen_variables.py
import os
import re
import textwrap

# --- Configuration ---
VARIABLES_FILE = os.path.join('properties', 'variables.rzn')
SRC_DIR = 'src'
LEXER_FILE = os.path.join(SRC_DIR, 'lexer.py')
PARSER_FILE = os.path.join(SRC_DIR, 'parser.py')
INTERPRETER_FILE = os.path.join(SRC_DIR, 'interpreter.py')

# --- Markers for code injection ---
LEXER_MARKER_START = '# AUTOGEN: LEXER_VARIABLES START'
LEXER_MARKER_END = '# AUTOGEN: LEXER_VARIABLES END'
PARSER_MARKER_START = '# AUTOGEN: PARSER_VARIABLES START'
PARSER_MARKER_END = '# AUTOGEN: PARSER_VARIABLES END'
INTERPRETER_MARKER_START = '# AUTOGEN: INTERPRETER_VARIABLES START'
INTERPRETER_MARKER_END = '# AUTOGEN: INTERPRETER_VARIABLES END'

# --- Helper Functions ---

def parse_variables_file(filepath):
    """Reads the variables file and returns a dictionary {name: description}, ignoring # and // comments."""
    variables = {}
    try:
        # Specify encoding for wider compatibility
        with open(filepath, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                # Skip empty lines and lines starting with # or //
                if not line or line.startswith('#') or line.startswith('//'):
                    continue

                # Match the variable => description format
                # Allows slightly more flexible spacing
                match = re.match(r'^\s*(\w+)\s*=>\s*(.*)$', line)
                if match:
                    var_name = match.group(1)
                    description = match.group(2).strip()
                    variables[var_name] = description
                else:
                    # Only warn for lines that are not comments/empty but don't match the format
                    print(f"Warning: Skipping malformed line {line_num} in {filepath}: {line}")
    except FileNotFoundError:
        print(f"Error: Variables file not found at {filepath}")
        return None
    except Exception as e:
        print(f"Error reading variables file {filepath}: {e}")
        return None
    # Sort variables alphabetically for consistent code generation order
    return dict(sorted(variables.items()))

def infer_semantic_type(description):
    """Attempts to infer a more semantic type/purpose hint from the description."""
    desc_lower = description.lower()
    # Order checks from more specific to more general
    if 'boolean' in desc_lower or 'true/false' in desc_lower: return 'BOOLEAN_DEF'
    if 'conditional' in desc_lower or 'if ' in desc_lower: return 'CONDITIONAL_IF'
    if 'alternative' in desc_lower or 'else ' in desc_lower: return 'CONDITIONAL_ELSE'
    if 'condition' in desc_lower or ' is ' in desc_lower: return 'COMPARISON_OP' # like 'is'
    if 'check' in desc_lower or ' when ' in desc_lower: return 'CHECK_OP' # like 'when'
    if 'negation' in desc_lower or 'not ' in desc_lower: return 'LOGICAL_NOT'

    if 'total' in desc_lower or ' sum ' in desc_lower: return 'MATH_SUM'
    if 'difference' in desc_lower: return 'MATH_DIFF'
    if 'multiplication' in desc_lower or 'prod' in desc_lower: return 'MATH_PROD'
    if 'division' in desc_lower or ' div ' in desc_lower: return 'MATH_DIV'
    if 'modulus' in desc_lower or ' mod ' in desc_lower: return 'MATH_MOD'
    if 'number' in desc_lower or 'integer' in desc_lower or 'float' in desc_lower: return 'NUMBER_DEF' # General number assignment like 'let'

    if 'joining strings' in desc_lower or 'concat' in desc_lower: return 'STRING_CONCAT'
    if 'cutting strings' in desc_lower or 'slice' in desc_lower: return 'STRING_SLICE'
    if 'string length' in desc_lower or ('len' in desc_lower and 'string' in desc_lower): return 'STRING_LENGTH'
    if 'string data' in desc_lower or 'text ' in desc_lower: return 'STRING_DEF' # like 'text'
    if 'string' in desc_lower or 'take ' in desc_lower: return 'STRING_DEF' # General string assignment like 'take'

    if 'adding elements' in desc_lower or 'append' in desc_lower: return 'LIST_APPEND'
    if 'deleting elements' in desc_lower or 'remove' in desc_lower: return 'LIST_REMOVE'
    if 'fixed-size arrays' in desc_lower or ' arr ' in desc_lower: return 'ARRAY_DEF'
    if 'simple arrays' in desc_lower or 'list ' in desc_lower: return 'LIST_DEF'

    if 'dictionaries' in desc_lower or ' map ' in desc_lower: return 'MAP_DEF'
    if 'access keys' in desc_lower or ' key ' in desc_lower: return 'MAP_ACCESS_KEY'
    if 'access values' in desc_lower or ' value ' in desc_lower: return 'MAP_ACCESS_VALUE'

    if 'timestamp' in desc_lower or ' now ' in desc_lower: return 'TIME_NOW'
    if 'current time' in desc_lower or ' current ' in desc_lower: return 'TIME_CURRENT'
    if ' year ' in desc_lower: return 'TIME_YEAR'
    if ' month ' in desc_lower: return 'TIME_MONTH'
    if ' day ' in desc_lower: return 'TIME_DAY'
    # etc. for other time parts

    if 'reusable values' in desc_lower or 'store ' in desc_lower: return 'VAR_STORE'
    if 'temporary data' in desc_lower or 'box ' in desc_lower: return 'VAR_TEMP'
    if 'reference' in desc_lower or 'ref ' in desc_lower: return 'VAR_REF'

    if 'output' in desc_lower or 'print' in desc_lower: return 'ACTION_PRINT'
    if 'input' in desc_lower or 'read' in desc_lower: return 'ACTION_READ'

    if 'mixed types' in desc_lower or ' put ' in desc_lower: return 'MIXED_DEF'

    return 'GENERIC_KEYWORD' # Default fallback

def generate_lexer_code(variables, indent_str):
    """Generates Python code snippet for the lexer."""
    code_lines = [f"{indent_str}# Added by autogen_variables.py"]
    if not variables:
        code_lines.append(f"{indent_str}# No variables found in {VARIABLES_FILE}")
        return "\n".join(code_lines)

    # Create the set of keywords
    keywords_set = "{" + ", ".join(f'"{name}"' for name in variables.keys()) + "}"
    code_lines.append(f"{indent_str}# --- Autogenerated Keywords ---")
    code_lines.append(f"{indent_str}# Purpose: Contains all keywords defined in {VARIABLES_FILE}")
    code_lines.append(f"{indent_str}# Usage: Check if an identifier token's value is in this set.")
    code_lines.append(f"{indent_str}KEYWORDS = {keywords_set}")
    code_lines.append("") # Blank line for readability

    # Create the tokenization logic (if/elif)
    code_lines.append(f"{indent_str}# --- Autogenerated Keyword Tokenization Logic ---")
    code_lines.append(f"{indent_str}# Purpose: Assigns specific token types to recognized keywords.")
    code_lines.append(f"{indent_str}# Usage: Place this block where you check if an identifier is a keyword.")
    code_lines.append(f"{indent_str}# Action Required: Ensure 'Token' class and token type names are consistent with your lexer.")
    code_lines.append(f"{indent_str}if token_value in KEYWORDS:")
    first = True
    for name, desc in variables.items():
        semantic_type = infer_semantic_type(desc)
        # Use the variable name in uppercase + _KEYWORD as the token type convention
        token_type_name = f"{name.upper()}_KEYWORD"

        # Start if/elif block
        if first:
            code_lines.append(f"{indent_str}    if token_value == '{name}':")
            first = False
        else:
            code_lines.append(f"{indent_str}    elif token_value == '{name}':")

        # Add comments and the return statement
        code_lines.append(f"{indent_str}        # Description: {desc}")
        code_lines.append(f"{indent_str}        # Inferred Type: {semantic_type}")
        code_lines.append(f"{indent_str}        return Token('{token_type_name}', '{name}')")

    # Add a fallback within the keyword check (optional but good practice)
    code_lines.append(f"{indent_str}    else:")
    code_lines.append(f"{indent_str}        # This path should logically not be reached if token_value is in KEYWORDS")
    code_lines.append(f"{indent_str}        # but provides a fallback just in case.")
    code_lines.append(f"{indent_str}        # You might want to raise an internal error here.")
    code_lines.append(f"{indent_str}        return Token('UNKNOWN_KEYWORD', token_value)")


    code_lines.append(f"{indent_str}# --- End Autogenerated Code ---")
    return "\n".join(code_lines)


def generate_parser_code(variables, indent_str):
    """Generates Python code snippet for the parser."""
    code_lines = [f"{indent_str}# Added by autogen_variables.py"]
    if not variables:
        code_lines.append(f"{indent_str}# No variables found in {VARIABLES_FILE}")
        return "\n".join(code_lines)

    code_lines.append(f"{indent_str}# --- Autogenerated Keyword Parsing Logic ---")
    code_lines.append(f"{indent_str}# Purpose: Provides parsing entry points for statements starting with keywords.")
    code_lines.append(f"{indent_str}# Usage: Integrate this into your parser's main statement parsing method.")
    code_lines.append(f"{indent_str}# Action Required: Replace 'pass' and comments with calls to your specific parsing functions")
    code_lines.append(f"{indent_str}#                (e.g., self.parse_let_statement(), self.parse_if_statement())")
    code_lines.append(f"{indent_str}#                Ensure the condition checks `current_token.type` correctly matches your lexer's output.")

    first = True
    for name, desc in variables.items():
        semantic_type = infer_semantic_type(desc)
        token_type_name = f"{name.upper()}_KEYWORD"
        # Suggest a potential parsing method name based on the keyword
        suggested_method = f"self.parse_{name}_statement()"

        # Check the token type generated by the lexer
        condition = f"current_token.type == '{token_type_name}'"

        if first:
            code_lines.append(f"{indent_str}if {condition}:")
            first = False
        else:
            code_lines.append(f"{indent_str}elif {condition}:")

        code_lines.append(f"{indent_str}    # Keyword: {name}")
        code_lines.append(f"{indent_str}    # Description: {desc}")
        code_lines.append(f"{indent_str}    # Inferred Type: {semantic_type}")
        code_lines.append(f"{indent_str}    # TODO: Implement the parsing logic for '{name}'")
        code_lines.append(f"{indent_str}    # Example: return {suggested_method}")
        code_lines.append(f"{indent_str}    pass # Replace this with your actual parsing call")

    # Add a final else to catch unexpected token types if this block is exhaustive
    # Or remove if this block is just part of a larger statement parsing logic
    code_lines.append(f"{indent_str}else:")
    code_lines.append(f"{indent_str}    # This token type is not one of the known keywords defined in variables.rzn")
    code_lines.append(f"{indent_str}    # Handle as an error or attempt other parsing rules (e.g., expression statement).")
    code_lines.append(f"{indent_str}    pass # Replace with error handling or other parsing logic")


    code_lines.append(f"{indent_str}# --- End Autogenerated Code ---")
    return "\n".join(code_lines)


def generate_interpreter_code(variables, indent_str):
    """Generates Python code snippet for the interpreter."""
    code_lines = [f"{indent_str}# Added by autogen_variables.py"]
    if not variables:
        code_lines.append(f"{indent_str}# No variables found in {VARIABLES_FILE}")
        return "\n".join(code_lines)

    code_lines.append(f"{indent_str}# --- Autogenerated Keyword Interpretation Logic ---")
    code_lines.append(f"{indent_str}# Purpose: Provides interpretation dispatch based on AST node types related to keywords.")
    code_lines.append(f"{indent_str}# Usage: Integrate this into your interpreter's main visit/dispatch method.")
    code_lines.append(f"{indent_str}# Action Required: Replace 'pass' and comments with calls to your specific visitor methods")
    code_lines.append(f"{indent_str}#                (e.g., self.visit_LetNode(node), self.visit_IfNode(node)).")
    code_lines.append(f"{indent_str}#                Ensure the condition checks match the AST node classes your parser generates.")

    first = True
    for name, desc in variables.items():
        semantic_type = infer_semantic_type(desc)
        # Assume parser creates specific node types like LetNode, IfNode, SumNode etc.
        # Convention: Capitalize the keyword name and append 'Node'
        node_class_name = f"{name.capitalize()}Node"
        # Suggest a potential visitor method name
        suggested_method = f"self.visit_{name.capitalize()}Node(node)" # e.g., visit_LetNode

        # Check the type of the AST node passed to the visitor
        condition = f"isinstance(node, {node_class_name})"

        if first:
            code_lines.append(f"{indent_str}# Assuming 'node' is the current AST node being visited")
            code_lines.append(f"{indent_str}# TODO: Ensure your parser creates node classes like '{node_class_name}' for these keywords.")
            code_lines.append(f"{indent_str}if {condition}:")
            first = False
        else:
            code_lines.append(f"{indent_str}elif {condition}:")

        code_lines.append(f"{indent_str}    # Keyword: {name}")
        code_lines.append(f"{indent_str}    # Description: {desc}")
        code_lines.append(f"{indent_str}    # Inferred Type: {semantic_type}")
        code_lines.append(f"{indent_str}    # TODO: Implement the interpretation logic for '{name}' nodes.")
        code_lines.append(f"{indent_str}    # Example: return {suggested_method}")
        code_lines.append(f"{indent_str}    pass # Replace this with your actual interpretation call")

    # Add a final else to catch unhandled node types if this logic is intended
    # to handle all keyword-related nodes processed by this part of the interpreter.
    code_lines.append(f"{indent_str}else:")
    code_lines.append(f"{indent_str}    # This node type doesn't correspond to a known keyword node from variables.rzn")
    code_lines.append(f"{indent_str}    # Handle as an error or delegate to other visitor methods.")
    code_lines.append(f"{indent_str}    # Example: return self.visit_expression(node) or raise error")
    code_lines.append(f"{indent_str}    pass # Replace with error handling or delegation")

    code_lines.append(f"{indent_str}# --- End Autogenerated Code ---")
    return "\n".join(code_lines)


def update_file(filepath, start_marker, end_marker, generated_code):
    """Updates the file by replacing content between markers, preserving indentation."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        start_index = content.find(start_marker)
        end_index = content.find(end_marker)

        if start_index == -1 or end_index == -1 or end_index <= start_index:
            print(f"Error: Markers not found or invalid in {filepath}.")
            print(f"       Ensure '{start_marker}' and '{end_marker}' exist, are in order,")
            print(f"       and are on their own lines (potentially with leading whitespace).")
            return False

        # Find the start of the line containing the start marker
        start_line_pos = content.rfind('\n', 0, start_index) + 1
        # Extract the leading whitespace (indentation) from that line
        indent_str = ""
        for char in content[start_line_pos : start_index]:
            if char.isspace():
                indent_str += char
            else:
                # Should not happen if marker is at the start of its line content
                print(f"Warning: Non-whitespace characters found before start marker on line in {filepath}")
                indent_str = "" # Reset indent if format is unexpected
                break

        # The code generation functions now receive and use the indent_str
        # No need to re-indent here if functions handle it internally

        # Construct the new content
        # Ensure newline after start marker and before end marker
        new_content = (
            content[:start_index + len(start_marker)] +
            '\n' +
            generated_code +  # Already indented by generator functions
            '\n' + indent_str + # Add indentation before the end marker
            content[end_index:]
        )

        # Avoid unnecessary writes if content hasn't changed
        # Find the existing code block to compare accurately
        existing_code_block = content[start_index + len(start_marker) : end_index]
        # Normalize whitespace for comparison (optional, but can reduce false positives)
        # For simplicity, we compare directly now, assuming generator is deterministic
        new_code_block = '\n' + generated_code + '\n' + indent_str

        if existing_code_block == new_code_block:
             print(f"No changes detected for the generated block in {filepath}. Skipping write.")
             return True


        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Successfully updated {filepath}")
        return True

    except FileNotFoundError:
        print(f"Error: Target file not found at {filepath}")
        return False
    except Exception as e:
        print(f"Error updating file {filepath}: {e}")
        return False

# --- Main Execution ---
if __name__ == "__main__":
    print("--- Starting Variable Autogeneration ---")

    # --- Basic Setup Checks ---
    if not os.path.exists(SRC_DIR):
        print(f"Error: Source directory '{SRC_DIR}' not found.")
        exit(1)
    properties_dir = os.path.dirname(VARIABLES_FILE)
    if not properties_dir: properties_dir = '.' # Handle root case
    if not os.path.exists(properties_dir):
         print(f"Error: Properties directory '{properties_dir}' not found.")
         exit(1)
    if not os.path.isfile(VARIABLES_FILE):
         print(f"Error: Variables file '{VARIABLES_FILE}' not found or is not a file.")
         exit(1)
    if not os.path.isfile(LEXER_FILE):
         print(f"Warning: Target file '{LEXER_FILE}' not found. Skipping update.")
    if not os.path.isfile(PARSER_FILE):
         print(f"Warning: Target file '{PARSER_FILE}' not found. Skipping update.")
    if not os.path.isfile(INTERPRETER_FILE):
         print(f"Warning: Target file '{INTERPRETER_FILE}' not found. Skipping update.")

    # --- Parse Variables ---
    print(f"\nParsing variables from: {VARIABLES_FILE}")
    variable_data = parse_variables_file(VARIABLES_FILE)

    if variable_data:
        print(f"Found {len(variable_data)} variables.")
        # print("Variables found:", ", ".join(variable_data.keys())) # Uncomment for details

        all_successful = True # Track if all updates succeed

        # --- Generate and Update Lexer ---
        if os.path.isfile(LEXER_FILE):
            print(f"\nProcessing {LEXER_FILE}...")
            indent_level = 4 # Default indent assumption, update_file determines actual
            indent_str = " " * indent_level
            lexer_code = generate_lexer_code(variable_data, indent_str) # Pass indent here
            if not update_file(LEXER_FILE, LEXER_MARKER_START, LEXER_MARKER_END, lexer_code):
                all_successful = False
        else:
             print(f"\nSkipping {LEXER_FILE} (Not found).")


        # --- Generate and Update Parser ---
        if os.path.isfile(PARSER_FILE):
            print(f"\nProcessing {PARSER_FILE}...")
            indent_level = 4 # Default indent assumption
            indent_str = " " * indent_level
            parser_code = generate_parser_code(variable_data, indent_str) # Pass indent here
            if not update_file(PARSER_FILE, PARSER_MARKER_START, PARSER_MARKER_END, parser_code):
                 all_successful = False
        else:
             print(f"\nSkipping {PARSER_FILE} (Not found).")

        # --- Generate and Update Interpreter ---
        if os.path.isfile(INTERPRETER_FILE):
            print(f"\nProcessing {INTERPRETER_FILE}...")
            indent_level = 4 # Default indent assumption
            indent_str = " " * indent_level
            interpreter_code = generate_interpreter_code(variable_data, indent_str) # Pass indent here
            if not update_file(INTERPRETER_FILE, INTERPRETER_MARKER_START, INTERPRETER_MARKER_END, interpreter_code):
                 all_successful = False
        else:
            print(f"\nSkipping {INTERPRETER_FILE} (Not found).")


        print("\n--- Autogeneration Finished ---")
        if not all_successful:
             print("Note: One or more files failed to update. Please check errors above.")
             exit(1)

    else:
        print("\n--- Autogeneration Failed ---")
        print("Reason: No valid variables found or error reading the variables file.")
        exit(1)