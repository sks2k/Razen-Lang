# Razen API Reference

This section provides detailed documentation for Razen's built-in functions, modules, and APIs.

## Built-in Functions

### Input/Output Functions

#### `show(value)`
Displays a value to the console.

```razen
show "Hello, World!";  // Displays: Hello, World!
show 42;               // Displays: 42
```

#### `input([prompt])`
Reads a line of input from the user, optionally displaying a prompt.

```razen
take name = input("Enter your name: ");
show "Hello, " + name + "!";
```

### Type Conversion Functions

#### `int(value)`
Converts a value to an integer.

```razen
take num_str = "123";
take num = int(num_str);  // num is 123 (integer)
```

#### `float(value)`
Converts a value to a floating-point number.

```razen
take int_val = 42;
take float_val = float(int_val);  // float_val is 42.0
```

#### `str(value)`
Converts a value to a string.

```razen
take num = 42;
take num_str = str(num);  // num_str is "42"
```

#### `bool(value)`
Converts a value to a boolean.

```razen
take num = 1;
take bool_val = bool(num);  // bool_val is true
```

### Math Functions

#### `abs(number)`
Returns the absolute value of a number.

```razen
show abs(-5);  // 5
show abs(5);   // 5
```

#### `max(a, b, ...)`
Returns the largest of the given arguments.

```razen
show max(1, 2, 3);  // 3
```

#### `min(a, b, ...)`
Returns the smallest of the given arguments.

```razen
show min(1, 2, 3);  // 1
```

#### `round(number)`
Rounds a number to the nearest integer.

```razen
show round(3.7);  // 4
show round(3.2);  // 3
```

### String Functions

#### `len(value)`
Returns the length of a string, array, or map.

```razen
show len("Hello");  // 5
show len([1, 2, 3]);  // 3
```

#### `string.upper()`
Converts a string to uppercase.

```razen
take text = "Hello";
show text.upper();  // "HELLO"
```

#### `string.lower()`
Converts a string to lowercase.

```razen
take text = "Hello";
show text.lower();  // "hello"
```

#### `string.replace(old, new)`
Replaces all occurrences of `old` with `new` in a string.

```razen
take text = "Hello, World!";
show text.replace(",", "");  // "Hello World!"
```

### Array Functions

#### `array.sort()`
Sorts an array in ascending order.

```razen
take numbers = [3, 1, 4, 1, 5];
show numbers.sort();  // [1, 1, 3, 4, 5]
```

#### `array.reverse()`
Reverses the order of elements in an array.

```razen
take numbers = [1, 2, 3, 4, 5];
show numbers.reverse();  // [5, 4, 3, 2, 1]
```

#### `array.join([separator])`
Joins all elements of an array into a string, using the specified separator.

```razen
take fruits = ["apple", "banana", "cherry"];
show fruits.join(", ");  // "apple, banana, cherry"
```

## Standard Library Modules

### Math Module

```razen
import math;

show math.pi;       // 3.141592653589793
show math.sin(0.5); // 0.479425538604203
show math.cos(0.5); // 0.8775825618903728
show math.sqrt(16); // 4
```

### File Module

```razen
import file;

// Write to a file
file.write("example.txt", "Hello, World!");

// Read from a file
take content = file.read("example.txt");
show content;  // "Hello, World!"
```

### System Module

```razen
import system;

// Get command line arguments
take args = system.args();
show args;

// Get environment variables
take home = system.env("HOME");
show home;

// Execute a shell command
take result = system.exec("ls -la");
show result;
```

### Random Module

```razen
import random;

// Generate a random integer between 1 and 10
take num = random.int(1, 10);
show num;

// Generate a random floating-point number between 0 and 1
take float_num = random.float();
show float_num;

// Choose a random element from an array
take fruits = ["apple", "banana", "cherry"];
take fruit = random.choice(fruits);
show fruit;
```

## Error Handling

### Error Functions

#### `error_message()`
Returns the message of the current error in a catch block.

```razen
try {
    take result = 10 / 0;
} catch {
    show "Error: " + error_message();
}
```

#### `throw(message)`
Throws an error with the specified message.

```razen
fun divide(a, b) {
    if (b == 0) {
        throw "Division by zero is not allowed";
    }
    return a / b;
}
```

## More Documentation

For more detailed information on specific APIs and functions, please refer to the individual documentation pages in this section.
