# Changelog

All notable changes to the "Razen Language Support" extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- *Future features will be listed here.*

### Changed
- *Future changes will be listed here.*

### Deprecated
- *Future deprecations will be listed here.*

### Removed
- *Future removals will be listed here.*

### Fixed
- *Future bug fixes will be listed here.*

### Security
- *Future security updates will be listed here.*

## [0.4.0] - 2025-06-05

### Added
- **Full Namespace Notation Support (`library::function()`):**
    - Introduced `library::function()` (e.g., `arrlib::push()`) as the new standard for library calls.
    - Complete syntax highlighting for the namespace, library name (scoped as `entity.name.class.library.razen`), `::` operator (scoped as `keyword.operator.namespace.razen`), and function name (scoped as `entity.name.function.library.razen`).
    - Language server (`razenServer.js`) validation for namespace calls, checking for known libraries and functions within them.
    - Accurate usage tracking in the language server for libraries called via namespace notation.
- **Bracket Notation Deprecation (`Library[function]()`):
    - Implemented diagnostics (warnings) in `razenServer.js` for deprecated `Library[function]()` usage, guiding users to the new syntax.
    - Added a quick fix (Ctrl + . or Cmd + .) to automatically convert `Library[function](args)` to `library::function(args)`. This conversion includes lowercasing the library name part for the new namespace syntax.
- **Extension Icon**: Added a Razen language icon (`icons/razen-icon.png`) to `package.json` for better visibility in the VS Code marketplace and editor.
- **Language Server Capabilities**: Enabled `codeActionProvider: true` in `razenServer.js` to support the new quick fix functionality.

### Changed
- **Syntax Highlighting Consistency (`razen.tmLanguage.json`):**
    - Unified TextMate grammar scopes for library calls. Namespace calls (`library::function()`) now precisely match the styling of the (now deprecated) bracket notation for both the library and function names.
- **Internal Library Name Handling (`razenServer.js`):**
    - Implemented a `toPascalCase` helper function in the language server for canonical library name resolution (e.g., 'arrlib' to 'ArrLib').
    - Refactored all library tracking logic in `validateRazenDocument` (for `using` statements, bracket calls, and namespace calls) to consistently use PascalCase keys in the internal `libraryMap`. This aligns with the `LIBRARIES` definition and ensures robust used/unused tracking.
- **Documentation:**
    - Overhauled `README.md` with comprehensive details on version 0.4.0 features, updated usage examples for new and deprecated syntax, and clearer installation/build instructions.
    - Created this dedicated `CHANGELOG.md` file for detailed version history.
- **Extension Version**: Updated from `0.3.0` to `0.4.0` in `package.json`.

### Fixed
- **`using` Statement Validation (`razenServer.js`):** Ensured `using LibraryName;` statements correctly validate the specified library name (case-insensitively, resolved to PascalCase) against the list of known `LIBRARIES` and provide accurate warning diagnostics for unknown libraries.

