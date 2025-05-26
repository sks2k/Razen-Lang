# Changelog

All notable changes to the Razen Language Extension for Zed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- AI-powered code suggestions and debugging assistance
- IntelliSense with advanced context awareness
- Automated refactoring tools
- Code generation templates and scaffolding
- Package manager integration
- Mobile development support
- Built-in web development framework tools

### Changed
- Improved performance for large files
- Enhanced error messages and diagnostics
- Better memory management

### Fixed
- Performance issues with complex syntax highlighting
- Memory leaks in language server integration

## [0.1.0] - 2024-12-19

### Added
- Initial release of Razen Language Extension for Zed
- Comprehensive syntax highlighting for Razen programming language
- Support for all Razen file types (.rzn extension)
- Document type recognition (web, script, cli, freestyle)
- Variable declaration highlighting (let, take, hold, put, sum, diff, prod, div, mod)
- Function definition and call highlighting
- Library import recognition and bracket notation support
- Built-in function highlighting
- Comment support (line # and block /* */)
- String literal highlighting with interpolation support (${}})
- Number literal highlighting (integer, float, hex, binary)
- Operator highlighting (arithmetic, assignment, comparison, logical)
- Color constant support for console output
- Code structure and outline view
- Auto-indentation rules for blocks and control structures
- Bracket matching and auto-closing pairs
- Text object selection for functions, blocks, strings
- Code folding for functions, classes, and comment blocks
- Runnable code detection for main functions, tests, and demos
- Tree-sitter grammar integration
- Language server configuration and support
- Code injection for embedded languages (JavaScript, JSON, SQL, HTML, CSS)
- Redaction queries for sensitive data protection
- Custom "Razen Dark" theme optimized for Razen syntax
- Comprehensive library support for 25+ libraries:
  - Core: arrlib, strlib, mathlib, timelib, random, file, json
  - System: os, system, netlib, memlib, binlib, bitlib, syslib
  - Utilities: crypto, regex, uuid, validation, color, audio, image, date
  - Development: complib, lexerlib, parserlib, astlib, bolt, thrlib
- Rust extension API implementation
- Language server initialization and configuration
- Workspace configuration support
- Custom completion and symbol labeling
- Runnable configuration for different execution modes
- Extension icons and branding assets
- Comprehensive documentation and usage examples

### Language Features
- Full support for Razen syntax highlighting
- Document structure recognition
- Library bracket notation: `LibName[function]()`
- Variable type inference and highlighting
- Function signature recognition
- Control flow statement highlighting
- Error handling (try/catch/finally) support
- Compiler construction keyword support
- API and networking keyword recognition
- Mathematical operation highlighting
- String manipulation function support
- Array and list operation support
- Date and time function support
- System programming capabilities
- Performance optimization tools (Bolt library)

### Developer Experience
- Auto-completion for all language constructs
- Hover information for functions and variables
- Go-to-definition support
- Find references functionality
- Document symbols and workspace symbols
- Code actions and quick fixes
- Formatting support
- Rename symbol support
- Inlay hints for type information
- Semantic token highlighting
- Diagnostic reporting
- Signature help for function calls
- Code lens for runnable functions
- Debug configuration support
- Test runner integration
- Build system integration

### Documentation
- Comprehensive README with usage examples
- Language feature documentation
- Library reference guide
- Installation and setup instructions
- Configuration guide
- Troubleshooting section
- Contributing guidelines
- Keyboard shortcuts reference
- Theme customization guide

### Technical Implementation
- Tree-sitter grammar for precise syntax parsing
- Zed Extension API integration
- Rust implementation for performance
- Language Server Protocol (LSP) support
- WebAssembly compilation target
- JSON configuration files
- TOML metadata and settings
- Modular query system for different language features
- Extensible architecture for future enhancements

### Assets and Resources
- Custom Razen logo and icons
- SVG and PNG format support
- Dark theme optimization
- Color scheme definitions
- Font and typography guidelines

## [0.0.1] - 2024-12-18

### Added
- Project initialization
- Basic extension structure
- Initial Tree-sitter grammar setup
- Core syntax highlighting patterns
- Basic language configuration

---

## Release Notes

### v0.1.0 - "Foundation Release"

This is the inaugural release of the Razen Language Extension for Zed, bringing comprehensive support for the Razen programming language to the Zed editor ecosystem.

**Highlights:**
- **Complete Language Support**: Full syntax highlighting and language intelligence for Razen
- **Extensive Library Coverage**: Support for 25+ built-in libraries
- **Advanced Editor Features**: Code folding, auto-completion, and smart indentation
- **Developer Tools**: Language server integration, debugging support, and test runner
- **Professional Quality**: Production-ready with comprehensive documentation

**What's New:**
- Full Razen language syntax support with Tree-sitter grammar
- Intelligent code completion and hover information
- Support for all Razen document types (web, script, cli, freestyle)
- Library bracket notation recognition and highlighting
- Custom theme optimized for Razen development
- Extensive documentation and examples
- Language server integration for advanced features
- Code folding, text objects, and navigation features
- Runnable code detection and execution support
- Security features including sensitive data redaction

**Getting Started:**
1. Install the extension from the Zed Extensions Registry
2. Create a new `.rzn` file
3. Start coding with full syntax highlighting and auto-completion
4. Explore the comprehensive library ecosystem
5. Use built-in tools for testing, debugging, and code formatting

**Community:**
Join the Razen community at [razen-lang.org](https://razen-lang.org) and connect with other developers building amazing applications with Razen.

---

For more information about Razen language features and capabilities, visit the [official documentation](https://docs.razen-lang.org).