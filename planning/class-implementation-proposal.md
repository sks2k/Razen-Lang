# Flexible Class Implementation
2025-08-23

# A Language with Flexible Class Design

This document proposes a single language theory that provides developers with the freedom to choose their class structure based on the complexity and scale of the project. Rather than enforcing a single paradigm, this language offers three distinct, powerful models.

---

## Class Design Models

This language offers three distinct, powerful models for class design:

### 1. The Inline Model

*   Simple and concise for small, self-contained classes.

### 2. The Mixed Model

*   A practical compromise for mid-sized projects, providing structure within a single file.

### 3. The Declare/Implement Split Model

*   The most robust model for large-scale, professional projects, emphasizing strict API contracts and separation of concerns.

---

## Example Code

### 1. The Hero Class (Inline Model)

The **Inline Model** is for quick, self-contained classes. All properties and methods are defined within a single class block. It is ideal for prototyping or for simple classes that don't need a formal public interface.

```
class Hero {
    // Properties
    var health: int = 100
    var inventory: list<str> = []
    var stats: map<str, int> = {"strength": 10, "speed": 15}
    var position: tuple<int, int> = (0, 0)
    var name: str = "Hero"
    var isAlive: bool = true

    // Functions
    fun addItem(item) {
        inventory.add(item)
    }

    fun takeDamage(amount) {
        health = health - amount
        if health <= 0 {
            isAlive = false
        }
    }

    fun move(x, y) {
        position = (x, y)
    }
}
```

---

### 2. The Monster Class (Mixed Model)

The **Mixed Model** provides a useful middle ground. It uses a single class block but organizes its properties and methods into logical sections. This allows for a degree of structure without the verbosity of a full declare/implement split.

```
class Monster {
    // --- Class Declaration Section ---
    var name: str = "Dragon"
    var health: int = 500
    var attackPower: int = 50

    // --- Method Implementation Section ---
    fun init(name) {
        this.name = name
    }

    fun roar() {
        show f"{name} roars fiercely!"
    }

    fun attack(target) {
        show f"{this.name} breathes fire at {target.name}!"
        target.takeDamage(this.attackPower)
    }

    fun takeDamage(amount) {
        this.health = this.health - amount
        if this.health <= 0 {
            show f"{this.name} has been defeated!"
        }
    }
}
```

---

### 3. The Enemy Class (Declare/Implement Model)

The **Declare/Implement Model** is the most robust and scalable. The `declare class` block acts as a public contract, defining the class's API without showing its internal workings. The `implement class` block then provides the concrete logic. This is the best model for team-based projects where multiple developers rely on a stable, well-documented interface.

```
declare class Enemy {
    var name: str
    var health: int
    var damage: int
    fun attack(target)
    fun takeDamage(amount)
}

implement class Enemy {
    fun init(name, health, damage) {
        this.name = name
        this.health = health
        this.damage = damage
    }

    fun attack(target) {
        show f"{this.name} attacks {target.name}!"
        target.takeDamage(this.damage)
    }

    fun takeDamage(amount) {
        this.health = this.health - amount
        if this.health <= 0 {
            show f"{this.name} has been defeated!"
        }
    }
}
```

---
## Team & Attribution – Razen-Lang v3
- **Proposal**: Add flexible Class syntax Design
- **Authored**: K.Sujith (github: sks2k, email: sujithks2k@outlook.com).
  
- **Creator**: Prathmesh Barot (@Prathmesh-Pro)
Built the core language architecture and foundational logic.

- **Co-Creator**: K. Sujith (@sks2k, [sujithks2k@outlook.com](mailto:sujithks2k@outlook.com))
Worked on syntax design refinements and introduced the reflex/hook concept.
Contributed to modular system enhancements and collaborative integration.

**Version**: Preview 3
**Date**: August 2025
