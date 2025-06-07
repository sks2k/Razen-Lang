# Razen v0.1.76 - Performance Boost & Enhanced Tooling

**Release Date**: June 7, 2025  
**Status**: Beta

---

> **Notice:**
> Razen's logging functions have been renamed to avoid naming conflicts.
>
> For more details and ongoing updates, visit our main website: [https://razen-lang.vercel.app/](https://razen-lang.vercel.app/)
>
> Changelog page: [https://razen-lang.vercel.app/changelogs](https://razen-lang.vercel.app/changelogs)

## What's New

### Performance & Installation Improvements
- **Faster Installation**: Completely revamped the installation process to be significantly faster and more lightweight
- **LLVM Integration**: Added experimental LLVM support, enabling more powerful optimizations and capabilities
- **Reduced Footprint**: Optimized binary size and runtime memory usage for better performance

### Logging Library Updates
- **Renamed Log Functions**: Updated logging function names to avoid conflicts and improve clarity:
  - `info` → `infolog`
  - `warn` → `warnlog`
  - `error` → `errorlog`
  - `debug` → `debuglog`
- **Backward Compatibility**: Added deprecation warnings for old function names

### VS Code Extension Updates
- **Improved Syntax Highlighting**: Better support for new language features
- **Enhanced Code Completion**: Smarter suggestions based on context
- **Performance Optimizations**: Faster parsing and analysis

---

## Technical Improvements
- **Compiler Optimizations**: New optimization passes for better runtime performance
- **Memory Management**: Reduced memory usage across the board
- **Build System**: Streamlined build process with better dependency management
- **LLVM Backend**: Experimental support for LLVM-based compilation

---

## Migration Guide
Update any code using the old logging function names to use the new names:

```razen
lib loglib;

# Old way (deprecated)
# loglib::info("This is a message");
# loglib::warn("This is a warning");
# loglib::error("This is an error");
# loglib::debug("Debug information");

# New way
show "Info log: " + loglib::infolog("This is an info message");
show "Warning log: " + loglib::warnlog("This is a warning message");
show "Error log: " + loglib::errorlog("This is an error message");
show "Debug log: " + loglib::debuglog("This is a debug message");
```

---

## Example: Testing Log Library
```razen
lib loglib;

show "Testing Log Library:";
show "Info log: " + loglib::infolog("This is an info message");
show "Warning log: " + loglib::warnlog("This is a warning message");
show "Error log: " + loglib::errorlog("This is an error message");
show "Debug log: " + loglib::debuglog("This is a debug message");
```

---

## Special Thanks
Thanks to the Razen community for your continued support and feedback!

---

## Full Changelog
- Added: Experimental LLVM backend support
- Changed: Logging function names updated to avoid conflicts
- Improved: Installation process is now faster and more reliable
- Improved: Memory usage and performance optimizations
- Updated: VS Code extension with better tooling support
- Fixed: Various minor bugs and stability issues
- Maintained: Backward compatibility with deprecation warnings/errors for old function names
