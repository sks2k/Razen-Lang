# Razen Language IDE Extensions

This repository contains IDE extensions for the Razen programming language, providing syntax highlighting and custom file icons for `.rzn` files.

## Available Extensions

### 1. VS Code Extension

Located in the `razen-vscode-extension` directory, this extension provides:
- Syntax highlighting for Razen (`.rzn`) files
- Custom file icon for Razen files
- Language configuration for better editing experience

#### Installation

1. Copy the `razen-vscode-extension` folder to your VS Code extensions directory:
   - Windows: `%USERPROFILE%\.vscode\extensions`
   - macOS/Linux: `~/.vscode/extensions`
2. Restart VS Code

### 2. JetBrains Plugin

Located in the `razen-jetbrains-plugin` directory, this plugin provides:
- Syntax highlighting for Razen (`.rzn`) files
- Custom file icon for Razen files
- Support for all JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.)

#### Building the Plugin

```bash
cd razen-jetbrains-plugin
./gradlew buildPlugin
```

The plugin will be available in the `build/distributions/` directory.

#### Installation

1. Open your JetBrains IDE
2. Go to Settings/Preferences > Plugins
3. Click the gear icon and select "Install Plugin from Disk..."
4. Select the built `.jar` file
5. Restart the IDE

## Syntax Highlighting

Both extensions highlight the following Razen language elements:

- Keywords: `fun`, `if`, `else`, `while`, `return`, etc.
- Variables: `let`, `take`, `hold`, `put`, etc.
- Functions: `add`, `subtract`, `multiply`, etc.
- Strings, numbers, and operators
- Comments

## Customization

You can customize the syntax highlighting by modifying:
- VS Code: `razen-vscode-extension/syntaxes/razen.tmLanguage.json`
- JetBrains: `razen-jetbrains-plugin/src/main/kotlin/com/razen/ide/RazenSyntaxHighlighter.kt`

## License

MIT
