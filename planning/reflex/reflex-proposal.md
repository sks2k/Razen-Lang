
# `reflex`: Reactive State System for Domain Modeling in Razen v3

## Overview

This document proposes `reflex`, a **keyword-safe**, **rule-driven**, and **effect-aware** reactive system for **Razen Lang** — designed as a **replacement for `use.XXX` patterns** that may conflict with future language features.

`reflex` enables developers to build **self-regulating domain models** (e.g., ecosystems, agents, simulations) using a clean, intuitive API rooted in **explicit reactivity**, **compile-time optimization**, and **safe mutation guards**.

> ✅ **No more `use.state()`** — instead: `reflex.state()`, `reflex.effect()`, `reflex.rule()`

---

## Motivation

The `use` keyword is semantically overloaded across languages (React, Rust, PHP, etc.) and may be reserved for core language features in future versions of Razen. To avoid naming collisions and improve long-term extensibility, we introduce `reflex` — a **domain-appropriate, unambiguous namespace** for reactive programming.

Additionally:
- `use` implies magic; `reflex` implies **intentional behavior**
- We want **fine-grained control**, not syntactic sugar
- Domain models (simulations, agents, games) need **rules + effects + observability**

`reflex` delivers all this — without runtime bloat.

---

## Core Design Principles

| Principle | Explanation |
|--------|-------------|
| **Explicit Over Implicit** | No hidden reactivity — all signals and effects are declared |
| **Rules First** | Every state change must pass validation |
| **Effects Are Reactions** | Side effects respond to changes, never drive them |
| **Compile-Time Graph** | Dependency tracking happens at compile time → O(1) updates |
| **No Proxies, No Getters** | Fast, predictable, debuggable |

---

## Core API

| Function | Description |
|--------|-------------|
| `reflex.state(value)` | Creates a reactive, rule-governed signal |
| `reflex.set(var, value)` | Safely updates state; triggers rules/effects |
| `reflex.effect([deps], fn)` | Runs when dependencies change and conditions pass |
| `reflex.rule(state, condition, fallback?)` | Guards mutations with validation logic |
| `reflex.fallback(fn)` | Optional handler for blocked mutations |
| `reflex.compute([deps], fn)` | Derived, read-only reactive value |
| `reflex.batch(fn)` | Groups updates to prevent redundant effects |

> 💡 All `reflex.*` calls are **tree-shakable**, **optimizable**, and **linkable at compile time**.

---

## Execution Flow

```text
1. reflex.set(state, newValue)
   ↓
2. Rule check: Does value pass all rules?
   ↓
   ├── Pass → Apply change
   └── Fail → Run fallback (if any), reject update
             ↓
3. Mark state as "dirty"
   ↓
4. Notify dependents (effects, computes) via pre-built dependency graph
   ↓
5. Each effect checks:
     - Did trigger change? ✅
     - Does `when` condition pass? ✅
     - Are all rules valid? ✅
   ↓
6. Run effect (or fallback)
```

All steps are **synchronous**, **deterministic**, and **debuggable**.

---

## Compiler Optimizations

Even though the API is explicit, the **compiler ensures zero runtime overhead** through the following optimizations:

| Task | Optimization |
|------|--------------|
| **Parse `reflex.state`** | Assign unique ID, track mutations |
| **Analyze `triggers`** | Build static dependency graph: `State → [Effects, Computes]` |
| **Compile `rules`** | Inline as direct boolean checks |
| **Eliminate Dead Effects** | Tree-shake unused or unreachable effects |
| **Optimize `.value` access** | Replace with direct variable access where safe |
| **Batch Updates** | Coalesce multiple `reflex.set()` calls into one notification cycle |

> 🚀 Result:  
> **Code looks reactive** → **Runs like imperative code**

---

## Architecture Model

The `reflex` system follows a **unidirectional, compile-time linked** architecture:

```text
┌─────────────┐
│   Actions   │ → Functions that mutate state (e.g., `hydrate()`, `growSafely()`)
└─────────────┘
       ↓
┌─────────────┐
│   State     │ ← Created via `reflex.state(value)`
│ (Signals)   │    Holds `.value`, `.prevValue`, metadata
└─────────────┘
       ↓
   ┌───┴────────────┐
   ▼                ▼
┌─────────┐ ┌─────────────┐
│ Compute │ │   Rule      │
│ (RO)    │ │ (Validation)│
└─────────┘ └─────────────┘
   ▲                ▲
   └───┬────────────┘
       ↓
┌─────────────┐
│   Effect    │ → Side effects (logging, rendering, reactions)
└─────────────┘
```

### Key Features of the Model:
- **State** is the source of truth
- **Rules** guard mutations at update time
- **Computes** derive new state reactively
- **Effects** observe changes and trigger side effects
- All connections are **mapped at compile time** → O(1) performance

---

## Benefits

✅ **Avoids `use` keyword conflicts**  
→ Future-proofs the language by freeing `use` for other semantics

✅ **Co-locates rules with state**  
→ Validation logic lives next to the data it protects

✅ **Enables safe, observable mutations**  
→ No invalid state leaks into effects or UI

✅ **Extensible by design**  
→ Supports:
   - `reflex.batch()` — atomic updates
   - `reflex.history(var, N)` — undo/redo
   - `reflex.watch(var, fn)` — change logging
   - `reflex.constant(42)` — immutable reactive values

✅ **Ideal for complex domains**  
→ Simulations, AI agents, games, robotics, financial models

---

## Future Extensions

```rzn
// Grouped updates
reflex.batch(fun() {
    reflex.set(count, count + 1)
    reflex.set(name, "Updated")
})

// Observe changes
reflex.watch(soilQuality, fun(old, new) {
    log("Soil changed: ${old} → ${new}")
})

// Enable undo history
reflex.history(infectionLevel, 5)

// Immutable reactive constant
reflex.constant MAX_USERS = 100
```

These can be added incrementally without breaking changes.

---

## Why `reflex`, Not `use`?

| `use.state()` | `reflex.state()` |
|-------------|------------------|
| Feels like language magic | Clearly a library call |
| Hard to tree-shake | Easy to import/strip |
| Ambiguous ownership | Clear: `reflex` owns reactivity |
| Not reusable across libs | Can be replaced or extended |

> 💡 This follows the **"library over syntax"** philosophy — like **React Hooks** vs Svelte’s reactivity.

---

## Performance at Scale

| Feature | Benefit |
|-------|--------|
| **No Proxies** | No performance cliff on large state |
| **No GC Overhead** | Signals are plain values or stack vars |
| **O(1) Updates** | Direct function calls via compiled graph |
| **Batch Support** | Prevents flicker in complex updates |
| **Tree-Shakable** | Unused effects/rules are removed |

Ideal for:
- UI frameworks
- Game loops
- Data pipelines
- Real-time dashboards
- Agent-based simulations

---

## Recommendation

Adopt `reflex` as the **standard reactivity library** for Razen v3:

✅ Replace `use.state()` → `reflex.state()`  
✅ Remove ambiguous shorthand syntax  
✅ Embrace **explicit, composable, compiled reactivity**  
✅ Position `reflex` as a **zero-cost abstraction layer**

This gives you:
- 🔧 **Control** — developers see what’s happening
- ⚡ **Speed** — no runtime tracking
- 🧩 **Composition** — easy to extend or replace
- 📚 **Clarity** — great for learning and tooling

### ✅ What’s Included

- ✅ **Clear motivation** for moving away from `use`
- ✅ **Complete API reference**
- ✅ **Execution flow** with diagram
- ✅ **Compiler optimizations table** (as requested)
- ✅ **Architecture model** with visual flow
- ✅ **Benefits and future extensions**
- ✅ **Final recommendation**

---
- **Proposal**: `Reflex`: Reactive State System for Domain Modeling in Razen v3
- **Authored**: K.Sujith (github: sks2k, email: sujithks2k@outlook.com).
  
- **Creator**: Prathmesh Barot (@Prathmesh-Pro)
Built the core language architecture and foundational logic.

- **Co-Creator**: K. Sujith (@sks2k, [sujithks2k@outlook.com](mailto:sujithks2k@outlook.com))
Worked on syntax design refinements and introduced the reflex/hook concept.
Contributed to modular system enhancements and collaborative integration.

**Version**: Preview 3
**Date**: August 2025
