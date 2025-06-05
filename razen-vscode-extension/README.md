# Razen Language Support for VS Code

**Version: 0.4.0**

Provides language support for the Razen programming language (`.rzn` files) in Visual Studio Code, including syntax highlighting, diagnostics, and quick fixes.

## Changelog (v0.4.0)

- **New Namespace Notation**: Introduced support for `library::function()` syntax for calling library functions (e.g., `arrlib::push()`).
- **Bracket Notation Deprecation**: Added warnings for the old `Library[function]()` syntax, guiding users to the new namespace notation.
- **Quick Fix**: Implemented a quick fix (Ctrl + . or Cmd + .) to automatically convert deprecated bracket notation to the new namespace notation.
- **Improved Syntax Highlighting**: Enhanced and unified syntax highlighting for both namespace and bracket library call notations.
- **Enhanced Language Server**:
    - Validates library calls made using the new namespace notation.
    - Tracks library usage (`using LibraryName;`) consistently for both notation styles.
    - Provides diagnostics for unknown libraries or functions.
- **Extension Icon**: Added a Razen language icon for better visibility in the marketplace and editor.

## Features

- **Comprehensive Syntax Highlighting**:
    - Keywords (`token`, `const`, `using`, `if`, `else`, `loop`, etc.)
    - Variables and Constants
    - Comments (`#`)
    - Strings (double-quoted)
    - Numbers (integers, floats)
    - Operators
    - Library calls (both `library::function()` and `Library[function]()`)
- **Diagnostics & Linting**:
    - Error reporting for syntax errors and invalid constructs.
    - Warnings for deprecated `Library[function]()` usage.
    - Detection of unknown libraries in `using` statements.
    - Detection of unknown libraries or functions in calls (both notations).
    - (Basic checks for unused variables and imported libraries - *work in progress for full robustness*).
- **Quick Fixes**:
    - Convert `Library[function](args)` to `library::function(args)`.
- **Custom File Icon**: Razen files (`.rzn`) get a unique icon in the file explorer.
- **Basic Completions**: Provides suggestions for some language keywords.

## Usage

### Library Usage

1.  **Importing Libraries (Recommended)**:
    ```razen
    using ArrLib;
    using StrLib;
    ```

2.  **Calling Library Functions (Namespace Notation - Recommended)**:
    ```razen
    token my_array = arrlib::new();
    arrlib::push(my_array, "hello");
    token upper_string = strlib::to_upper("world");
    ```

3.  **Calling Library Functions (Bracket Notation - Deprecated)**:
    ```razen
    // This syntax is deprecated and will show a warning.
    // Use the quick fix (Ctrl + .) to convert.
    token my_old_array = ArrLib[new]();
    ArrLib[push](my_old_array, 123);
    ```

## Installation

1.  Open Visual Studio Code.
2.  Go to the Extensions view (`Ctrl+Shift+X` or `Cmd+Shift+X`).
3.  Search for "Razen Language Support" (or the exact name if published).
4.  Click **Install**.

**Manual Installation (from `.vsix` file):**

1.  Download the `razen-language-0.4.0.vsix` file.
2.  Open VS Code.
3.  Go to the Extensions view.
4.  Click the **...** (More Actions) menu in the top-right corner of the Extensions view.
5.  Select **Install from VSIX...**
6.  Navigate to and select the downloaded `.vsix` file.
7.  Reload VS Code if prompted.

## Building from Source

If you want to build the extension yourself:

1.  Clone the repository (or ensure you have the `razen-vscode-extension` directory).
2.  Navigate to the `razen-vscode-extension` directory in your terminal.
3.  Install `vsce` (Visual Studio Code Extension Manager) globally if you haven't already:
    ```bash
    npm install --global vsce
    ```
4.  Package the extension:
    ```bash
    vsce package
    ```
    This will create a `.vsix` file (e.g., `razen-language-0.4.0.vsix`) in the current directory.

## License

MIT
