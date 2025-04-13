# Razen Language Extension for VS Code

This extension provides syntax highlighting, custom file icons, and language support for the Razen programming language.

## Features

- Syntax highlighting for Razen (`.rzn`) files
- Custom file icon for Razen files
- Language configuration for better editing experience
- Intelligent Autocomplete (IntelliSense)
  - Suggests language keywords, variables, and functions after typing just 1-2 characters
  - Provides context-aware suggestions based on the current code context
  - Scans the document for user-defined variables and functions
  - Includes detailed documentation and code snippets for each suggestion
  - Supports fuzzy matching for more flexible completions
  - Automatically triggers after typing specific characters (., space, (, {, =, ", ')

## Installation

1. Copy this folder to your VS Code extensions directory:
   - Windows: `%USERPROFILE%\.vscode\extensions`
   - macOS/Linux: `~/.vscode/extensions`

2. Restart VS Code

## Manual Installation

1. Open VS Code
2. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)
3. Type "Install from VSIX" and select the option
4. Navigate to the `.vsix` file and install

## Building the Extension

```bash
# Install vsce if you don't have it
npm install -g vsce

# Package the extension
vsce package
```

## License

MIT
