# `reflex`: Reactive State System for Domain Modeling in Razen v3

## Overview

This document proposes `reflex`, a **keyword-safe**, **rule-driven**, and **effect-aware** reactive system for Razen Lang — designed as a **replacement for `use.XXX` patterns** that may conflict with future language features.

`reflex` enables developers to build **self-regulating domain models** (e.g., ecosystems, agents, simulations) using a clean, intuitive API.

---

## Motivation

The `use` keyword is semantically overloaded (React, Rust, etc.) and may be reserved for future language constructs in Razen. To avoid collisions and improve clarity, we introduce `reflex` — a **domain-appropriate alternative** for reactive programming.

---

## Core API

| Function | Description |
|--------|-------------|
| `reflex.state(value)` | Creates observable, rule-governed state |
| `reflex.set(var, value)` | Updates state; triggers rules/effects |
| `reflex.effect([deps], fn)` | Runs when dependencies change |
| `reflex.fallback(fn)` | Handles blocked mutations in `rules` blocks |

---

## Example: Reactive Tree in Ecosystem

See `examples/tree_simulation.rzn` for a full simulation of:
- Soil, water, sunlight dynamics
- Rule-based mutation guards
- Environmental effects
- Infection & immune response

---

## Benefits

- ✅ Avoids `use` keyword conflicts
- ✅ Co-locates rules with state
- ✅ Enables safe, observable mutations
- ✅ Extensible: supports history, batching, logging
- ✅ Ideal for simulations, games, AI agents

---

## Future Extensions

```rzn
reflex.batch(fun() { ... })        // Grouped updates
reflex.watch(var, fun(old, new))  // Observe changes
reflex.history(var, 5)            // Undo support
reflex.constant(42)               // Immutable reactive value
