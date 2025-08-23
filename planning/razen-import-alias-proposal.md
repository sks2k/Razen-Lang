
# Proposal: Add `as` Keyword for Import Aliasing in Razen

> **Enhancing modularity, readability, and conflict resolution through intuitive import aliasing**

---

## 🎯 Purpose

Introduce the `as` keyword in **Razen** to allow **aliasing of imported functions, classes, and modules** during import. This improves code clarity, avoids naming conflicts, and aligns Razen with modern language design patterns.

---

## 🔧 Current Limitation

Razen currently supports module imports using:
```razen
import { User, Product } from "./models.rzn";
```

However, there is **no built-in way to rename** these identifiers upon import. This leads to issues when:

- Two modules export the same name (e.g., `User` from `admin/` and `customer/`)
- A name is too long or ambiguous for local use
- Developers want to use more context-appropriate names

Without aliasing, workarounds like manual reassignment are required:
```razen
import { DataProcessor } from "./core/processor.rzn";
var Processor = DataProcessor; # Clumsy and unnecessary
```

This hurts code elegance and maintainability.

---

## ✅ Proposed Enhancement: Introduce `as` for Aliasing

Add support for the `as` keyword to allow **direct renaming** during import:

### Syntax
```razen
import { OriginalName as NewName } from "path/to/module.rzn";
```

### Examples

#### 1. Resolve Naming Conflicts
```razen
import { User as AdminUser } from "./admin/models.rzn";
import { User as CustomerUser } from "./customer/models.rzn";

AdminUser admin = new AdminUser("Alice");
CustomerUser customer = new CustomerUser("Bob");
```

#### 2. Shorten Verbose Names
```razen
import { DataValidationHelper as Validator } from "./utils/validation.rzn";

if (Validator.isValid(email)) {
  show "Email is valid!";
}
```

#### 3. Improve Contextual Clarity
```razen
import { Logger } from "./app/logger.rzn" as AppLogger;
import { Logger } from "./db/logger.rzn" as DBLogger;

AppLogger.log("Starting server...");
DBLogger.log("Connecting to database...");
```

#### 4. Alias Entire Modules (Optional Extension)
```razen
import { APIHandler } from "./network/api.rzn" as API;
API.start();
```

---

## 🌍 Real-World Precedent

The `as` keyword is widely adopted across major languages:

| Language       | Example |
|----------------|--------|
| **Python**     | `from json import dumps as to_json` |
| **JavaScript** | `import { Component } from 'react' as UI;` *(TypeScript-style)* |
| **TypeScript** | `import { Service } from './service' as Svc;` |
| **Rust**       | `use std::collections::HashMap as Map;` |

✅ These languages prove that `as` is:
- **Intuitive**
- **Readable**
- **Essential for large-scale development**

---

## 💡 Benefits for Razen

| Benefit | Impact |
|-------|--------|
| **Avoids Name Collisions** | Enables safe use of same-named types from different modules |
| **Improves Readability** | Allows domain-specific naming (`User as Guest`, `Helper as Guard`) |
| **Supports Clean Refactoring** | Rename locally without changing source files |
| **Enhances Developer Experience** | Feels familiar to developers from other languages |
| **Scales to Large Projects** | Critical for enterprise-level codebases with deep module hierarchies |

---

## 🛠️ Implementation Details

### Grammar Addition (EBNF-style)
```ebnf
ImportSpecifier = Identifier | Identifier "as" Identifier ;
ImportClause    = "{" { ImportSpecifier } "}" ;
ImportStatement = "import", ImportClause, "from", StringLiteral, ";";
```

### Parser Impact
- Minimal change: only affects import parsing
- No runtime overhead
- Fully backward compatible

### Backward Compatibility
✅ **100% Compatible** — existing imports remain valid:
```razen
import { User } from "./models.rzn"; # Still works
```

---

## 📚 Documentation Example

Add this to the **Module Management** section of the Razen docs:

> ### Import Aliasing with `as`
>
> When importing symbols, you can give them a local alias using the `as` keyword:
>
> ```razen
> import { Router as WebRouter } from "./web/router.rzn";
> ```
>
> This allows multiple types with the same name to coexist, or lets you simplify long names for better readability.

---

## 🧩 Future-Proofing: Export Aliasing?

While not required now, supporting `as` in exports paves the way for future flexibility:

```razen
export { InternalHelper as PublicAPI } to "./public.rzn";
```

This could be part of a later enhancement.

---

## 🚀 Final Argument

> **"The `as` keyword is a small syntax addition with a massive impact. It makes Razen feel professional, scalable, and developer-friendly — without adding complexity."**

Without it, developers will invent inconsistent workarounds. With it, Razen embraces best practices from the start.

Let’s build a language that scales **from scripts to systems** — and `as` is a step in that direction.

---

## ✅ Recommendation

**Add the `as` keyword to the `import` statement syntax** to support aliasing:

```razen
import { Original as Alias } from "./module.rzn";
```

This change is:
- Simple to implement
- Easy to learn
- Powerful in practice

---

## 📣 Call to Action

> **"Make Razen not just expressive, but elegant. Accept `as` — a tiny token that unlocks clean, scalable code."**
