# Razen Language Plugin for JetBrains IDEs

This plugin provides syntax highlighting and custom file icons for the Razen programming language in JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.).

## Features

- Syntax highlighting for Razen (`.rzn`) files
- Custom file icon for Razen files

## Installation

### From JetBrains Marketplace

1. Open your JetBrains IDE
2. Go to Settings/Preferences > Plugins
3. Click "Browse repositories..."
4. Search for "Razen Language"
5. Install the plugin and restart the IDE

### Manual Installation

1. Download the plugin `.jar` file
2. Open your JetBrains IDE
3. Go to Settings/Preferences > Plugins
4. Click the gear icon and select "Install Plugin from Disk..."
5. Select the downloaded `.jar` file
6. Restart the IDE

## Building from Source

```bash
# Clone the repository
git clone https://github.com/razen-lang/razen-jetbrains-plugin.git
cd razen-jetbrains-plugin

# Build the plugin
./gradlew buildPlugin

# The plugin will be in build/distributions/
```

## License

MIT
