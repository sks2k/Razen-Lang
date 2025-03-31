# scripts.py
import subprocess
import os
import sys
import shutil

# --- Configuration ---
# Determine project root relative to this script's location
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR = os.path.join(PROJECT_ROOT, 'scripts') # Assumes scripts.py is in project root

# --- Helper to find executable ---
def find_script(name):
    """Finds the full path to an executable script in the scripts dir."""
    script_path = os.path.join(SCRIPTS_DIR, name)
    # Use shutil.which to check if it's executable and find it (handles PATH too, though less relevant here)
    # Or simply check existence and basic executable bit on non-Windows
    if sys.platform != "win32":
        if os.path.isfile(script_path) and os.access(script_path, os.X_OK):
             return script_path
    else:
         # On Windows, check for .bat or .cmd if needed, or just if file exists
         if os.path.isfile(script_path) or os.path.isfile(script_path + ".bat") or os.path.isfile(script_path + ".cmd"):
              # May need to adjust how command is called on Windows if not using bash/WSL
              return script_path # Assuming direct execution works or bash is available

    # Fallback: check using shutil.which if it happens to be in PATH
    found_path = shutil.which(name, path=SCRIPTS_DIR)
    if found_path:
        return found_path

    return None # Not found or not executable

# --- Execution Functions ---

def execute_razen_script(script_name, filename, *args):
    """
    Executes one of the Razen shell scripts ('razen', 'razen-debug', 'razen-test').

    Args:
        script_name (str): The name of the script (e.g., 'razen').
        filename (str): The path to the .rzn file.
        *args: Additional arguments to pass to the script (e.g., '--show-tokens').

    Returns:
        dict: A dictionary containing {'return_code', 'stdout', 'stderr', 'success'}.
    """
    script_path = find_script(script_name)
    if not script_path:
        return {
            'success': False,
            'return_code': -1,
            'stdout': '',
            'stderr': f"Error: Script '{script_name}' not found or not executable in '{SCRIPTS_DIR}'.",
        }

    if not os.path.isabs(filename):
        abs_filename = os.path.abspath(filename)
    else:
        abs_filename = filename

    if not os.path.isfile(abs_filename):
         return {
            'success': False,
            'return_code': -1,
            'stdout': '',
            'stderr': f"Error: Input file not found: '{abs_filename}'.",
        }

    command = [script_path, abs_filename] + list(args)
    print(f"--- Running Command from scripts.py: {' '.join(command)} ---", file=sys.stderr)

    try:
        # On Windows, if using bash scripts, might need 'bash' prefix or use WSL
        # For simplicity, assuming direct execution or compatible environment
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding='utf-8',
            check=False # Don't raise exception on non-zero exit code
        )

        success = (result.returncode == 0)
        print(f"--- Command Finished (Return Code: {result.returncode}) ---", file=sys.stderr)

        return {
            'success': success,
            'return_code': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
        }
    except Exception as e:
         print(f"--- Failed to execute command: {' '.join(command)} ---", file=sys.stderr)
         return {
            'success': False,
            'return_code': -1,
            'stdout': '',
            'stderr': f"Error executing script '{script_name}': {e}",
        }

def run_razen(filename):
    """Runs the 'razen' script for the given file."""
    return execute_razen_script('razen', filename)

def run_razen_debug(filename, *args):
    """Runs the 'razen-debug' script for the given file with optional flags."""
    return execute_razen_script('razen-debug', filename, *args)

def run_razen_test(filename, *args):
    """Runs the 'razen-test' script for the given file with optional flags."""
    return execute_razen_script('razen-test', filename, *args)

# --- Example Usage ---
if __name__ == "__main__":
    print("--- Testing Razen Script Execution via scripts.py ---")

    # Create a dummy Razen file for testing
    test_filename = "test_example.rzn"
    try:
        with open(test_filename, "w", encoding="utf-8") as f:
            f.write('# Example Razen Code\n')
            f.write('let my_var = 100\n')
            f.write('show "Variable value: "\n') # Assuming show handles concatenation or multiple args
            f.write('show my_var\n')
            f.write('show "Test Complete."\n')
            # Add a line that might cause an error for debug/test testing
            # f.write('let error_var = my_var + undefined_var\n')
    except IOError as e:
        print(f"Failed to create test file '{test_filename}': {e}")
        sys.exit(1)

    print(f"\n>>> Running: run_razen('{test_filename}')")
    result_run = run_razen(test_filename)
    print("--- Run Output ---")
    print("Success:", result_run['success'])
    print("Return Code:", result_run['return_code'])
    print("STDOUT:\n" + result_run['stdout'])
    print("STDERR:\n" + result_run['stderr'])
    print("------------------")

    print(f"\n>>> Running: run_razen_debug('{test_filename}', '--show-tokens')")
    result_debug = run_razen_debug(test_filename, '--show-tokens') # Pass extra arg
    print("--- Debug Output ---")
    print("Success:", result_debug['success'])
    print("Return Code:", result_debug['return_code'])
    print("STDOUT:\n" + result_debug['stdout'])
    print("STDERR:\n" + result_debug['stderr'])
    print("--------------------")

    print(f"\n>>> Running: run_razen_test('{test_filename}')")
    result_test = run_razen_test(test_filename)
    print("--- Test Output ---")
    print("Success:", result_test['success'])
    print("Return Code:", result_test['return_code'])
    print("STDOUT:\n" + result_test['stdout'])
    print("STDERR:\n" + result_test['stderr'])
    print("-------------------")

    # Clean up dummy file
    try:
        os.remove(test_filename)
        print(f"\nRemoved test file: {test_filename}")
    except OSError as e:
        print(f"Warning: Could not remove test file '{test_filename}': {e}")