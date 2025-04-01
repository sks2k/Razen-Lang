# Razen Language Reference

This reference manual provides a comprehensive overview of the Razen programming language syntax, features, and built-in functionality.

## Table of Contents

- [Lexical Structure](#lexical-structure)
- [Data Types](#data-types)
- [Variables](#variables)
- [Operators](#operators)
- [Control Flow](#control-flow)
- [Functions](#functions)
- [Error Handling](#error-handling)
- [Modules and Imports](#modules-and-imports)
- [Built-in Functions](#built-in-functions)

## Lexical Structure

### Comments

```razen
# This is a single-line comment

/*
This is a
multi-line comment
*/
```

### Identifiers

Identifiers in Razen start with a letter or underscore, followed by any number of letters, digits, or underscores.

Valid identifiers:
```
name
_count
user123
camelCase
snake_case
```

### Keywords

The following are reserved keywords in Razen:

```
take, let, fun, if, else, elif, while, for, in, return, break, continue,
true, false, null, show, try, catch, finally, throw, import, from
```

## Data Types

Razen supports the following primitive data types:

### Numbers

```razen
# Integers
take age = 30;
take population = 7900000000;

# Floating-point numbers
take pi = 3.14159;
take temperature = -42.5;
```

### Strings

```razen
take name = "Alice";
take message = 'Hello, World!';

# String interpolation
take greeting = "Hello, ${name}!";

# Multi-line strings
take multiline = """
This is a
multi-line string
""";
```

### Booleans

```razen
take is_active = true;
take is_completed = false;
```

### Null

```razen
take data = null;
```

### Arrays

```razen
take numbers = [1, 2, 3, 4, 5];
take names = ["Alice", "Bob", "Charlie"];
take mixed = [1, "two", true, [3, 4]];

# Accessing elements (zero-indexed)
show numbers[0];  # 1
show names[1];    # Bob

# Modifying elements
let numbers[2] = 10;
```

### Maps (Dictionaries)

```razen
take person = {
    "name": "Alice",
    "age": 30,
    "is_student": false
};

# Accessing elements
show person["name"];  # Alice

# Modifying elements
let person["age"] = 31;
```

## Variables

Razen provides two ways to declare variables:

### Using `take`

The `take` keyword creates a variable that can be reassigned:

```razen
take count = 0;
let count = count + 1;  # count is now 1
```

### Using `let`

The `let` keyword is used for reassignment:

```razen
take name = "Alice";
let name = "Bob";  # name is now "Bob"
```

## Operators

### Arithmetic Operators

```razen
take a = 10;
take b = 3;

show a + b;  # Addition: 13
show a - b;  # Subtraction: 7
show a * b;  # Multiplication: 30
show a / b;  # Division: 3.333...
show a % b;  # Modulus: 1
```

### Comparison Operators

```razen
take x = 5;
take y = 10;

show x == y;  # Equal to: false
show x != y;  # Not equal to: true
show x < y;   # Less than: true
show x > y;   # Greater than: false
show x <= y;  # Less than or equal to: true
show x >= y;  # Greater than or equal to: false
```

### Logical Operators

```razen
take a = true;
take b = false;

show a && b;  # Logical AND: false
show a || b;  # Logical OR: true
show !a;      # Logical NOT: false
```

### Assignment Operators

```razen
take x = 10;

let x += 5;   # x = x + 5, x is now 15
let x -= 3;   # x = x - 3, x is now 12
let x *= 2;   # x = x * 2, x is now 24
let x /= 4;   # x = x / 4, x is now 6
```

## Control Flow

### Conditional Statements

#### If-Else

```razen
take score = 85;

if (score >= 90) {
    show "Grade: A";
} else if (score >= 80) {
    show "Grade: B";
} else if (score >= 70) {
    show "Grade: C";
} else {
    show "Grade: F";
}
```

### Loops

#### While Loop

```razen
take count = 0;

while (count < 5) {
    show count;
    let count = count + 1;
}
```

#### For Loop

```razen
# Iterating over an array
for (item in [1, 2, 3, 4, 5]) {
    show item;
}

# Iterating over a map
take person = {"name": "Alice", "age": 30};
for (key in person) {
    show key + ": " + person[key];
}
```

### Break and Continue

```razen
# Break example
take i = 0;
while (i < 10) {
    if (i == 5) {
        break;  # Exit the loop when i is 5
    }
    show i;
    let i = i + 1;
}

# Continue example
for (i in [1, 2, 3, 4, 5]) {
    if (i % 2 == 0) {
        continue;  # Skip even numbers
    }
    show i;
}
```

## Functions

### Defining Functions

```razen
fun greet(name) {
    return "Hello, " + name + "!";
}

# Function with default parameter
fun power(base, exponent = 2) {
    return base ** exponent;
}

# Function with multiple return values
fun get_min_max(numbers) {
    return [min(numbers), max(numbers)];
}
```

### Calling Functions

```razen
take message = greet("Alice");
show message;  # Hello, Alice!

show power(3);      # 9 (uses default exponent)
show power(2, 3);   # 8

take [min_val, max_val] = get_min_max([3, 1, 5, 2, 4]);
show "Min: " + min_val + ", Max: " + max_val;  # Min: 1, Max: 5
```

## Error Handling

### Try-Catch-Finally

```razen
try {
    take result = 10 / 0;  # This will cause an error
    show "This won't be executed";
} catch {
    show "An error occurred!";
} finally {
    show "This will always be executed";
}
```

### Throwing Errors

```razen
fun divide(a, b) {
    if (b == 0) {
        throw "Division by zero is not allowed";
    }
    return a / b;
}

try {
    show divide(10, 0);
} catch {
    show "Error: " + error_message();
}
```

## Modules and Imports

### Importing Modules

```razen
# Import an entire module
import math;
show math.sin(0.5);

# Import specific functions from a module
from math import sin, cos, tan;
show sin(0.5);

# Import with alias
import math as m;
show m.sqrt(16);
```

## Built-in Functions

Razen provides several built-in functions:

### Input/Output

```razen
# Output
show "Hello, World!";

# Input
take name = input("Enter your name: ");
show "Hello, " + name + "!";
```

### Type Conversion

```razen
take num_str = "123";
take num = int(num_str);
show num + 1;  # 124

take float_num = 3.14;
take int_num = int(float_num);
show int_num;  # 3

take bool_val = bool(1);
show bool_val;  # true
```

### Math Functions

```razen
show abs(-5);        # 5
show max(1, 2, 3);   # 3
show min(1, 2, 3);   # 1
show round(3.7);     # 4
```

### String Functions

```razen
take text = "Hello, World!";

show len(text);           # 13
show text.upper();        # HELLO, WORLD!
show text.lower();        # hello, world!
show text.replace(",", "");  # Hello World!
```

### Array Functions

```razen
take numbers = [3, 1, 4, 1, 5];

show len(numbers);        # 5
show numbers.sort();      # [1, 1, 3, 4, 5]
show numbers.reverse();   # [5, 4, 3, 1, 1]
show numbers.join(", ");  # "5, 4, 3, 1, 1"
```

For more detailed information on specific language features, see the individual documentation pages in this section.
