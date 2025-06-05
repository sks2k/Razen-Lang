# Razen v0.1.75 - Library Call Update & Namespace Notation

**Release Date**: June 5, 2025  
**Status**: Beta

---

> **Notice:**
> Razen previously supported only the bracket notation for library calls (e.g., `Lib[func](...)`). This notation is **still valid and will continue to work until the release of beta v0.1.80**. After that, only the modern namespace notation (`lib::function(...)`) will be supported. Please update your code accordingly.
>
> For more details and ongoing updates, visit our main website: [https://razen-lang.vercel.app/](https://razen-lang.vercel.app/)
>
> Changelog page: [https://razen-lang.vercel.app/changelogs](https://razen-lang.vercel.app/changelogs)

## What's New

### Powerful Library Call System
- **Namespace Notation (`lib::function`)**: You can now call library functions using the modern `namespace::function(args...)` syntax, in addition to the classic `Library[function](args...)` bracket notation.
- **Full Parity**: Both bracket and namespace notations are fully supported and interchangeable for all standard and custom libraries.
- **Improved Parser & Compiler**: The parser and compiler have been enhanced to robustly handle complex library calls, including nested and chained calls, across all supported libraries.

### Modernized Library Experience
- **Consistent Metadata Extraction**: All documentation and sidebars now display function difficulty and version badges, auto-updated from library sources.
- **Color-coded Difficulty & Version Badges**: Instantly see the complexity and stability of each library function.
- **Semantic Sorting**: Changelogs and docs are now sorted by version and difficulty for easier navigation.

### Usability & Error Handling
- **Better Error Messages**: Parser errors now include precise line and column info, making debugging easier.
- **Graceful Handling of Invalid Calls**: Unhandled or invalid library calls now produce clear, actionable error messages.
- **Backward Compatibility**: All previous scripts using bracket notation continue to work without changes.

---

## Technical Improvements
- **Namespace Operator Registered**: The `::` operator is now a first-class infix operator in the parser, enabling robust namespaced calls.
- **Unified Expression Handling**: Library calls, whether via brackets or namespace, are parsed into a unified AST structure for consistent compilation.
- **Test Coverage**: New and extended tests ensure both notations work identically for all libraries.

---

## Migration Guide

No migration needed immediately! All previous code using `Library[function](...)` still works. However, **bracket notation will be deprecated after beta v0.1.80**. Please migrate your code to use `lib::function(...)` for future compatibility.

---

## Example
```razen
lib arrlib;
lib strlib;

show arrlib::push([1,2,3], 4);     # Namespace notation
show ArrLib[push]([1,2,3], 4);     # Bracket notation (still supported)
show strlib::upper("hello");      # Namespace notation
show StrLib[upper]("hello");      # Bracket notation
```

---

## Documentation & Sidebar Updates
- Docs, examples, and changelogs now auto-update from library metadata.
- Difficulty and version badges are displayed everywhere for clarity.

---

## Special Thanks
Thanks to the Razen community for feedback and bug reports!

---

## Full Changelog
- Added: Namespace notation (`lib::function`) for all library calls
- Improved: Parser and compiler robustness for all library call forms
- Improved: Error reporting for invalid library calls
- Improved: Documentation and sidebar metadata extraction
- Fixed: Legacy bugs with chained and nested library calls
- Fixed: Sorting and badge display in docs and changelogs
- Maintained: Full backward compatibility with bracket notation
