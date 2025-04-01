# Getting Started with Razen

This guide will help you install Razen and write your first program.

## Installation

Razen can be installed on Linux, macOS, and Windows. Choose the installation method for your operating system.

### Linux

```bash
# Using curl
curl -o install.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" && chmod +x install.sh && sudo ./install.sh
```

```bash
# Using wget
wget -O install.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" && chmod +x install.sh && sudo ./install.sh
```

### macOS

```bash
# Using curl
curl -o install-mac.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install-mac.sh" && chmod +x install-mac.sh && sudo ./install-mac.sh
```

### Windows

1. Download the Windows installer from [GitHub](https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.ps1)
2. Open PowerShell as Administrator
3. Navigate to the download location
4. Run: `.\install.ps1`

## Verifying Installation

After installation, verify that Razen is installed correctly:

```bash
razen version
```

You should see the current version of Razen displayed.

## Your First Razen Program

Let's create a simple "Hello, World!" program:

1. Create a new file named `hello.rzn` with the following content:

```razen
# This is a comment
show "Hello, World!";
```

2. Run the program:

```bash
razen-run hello.rzn
```

You should see `Hello, World!` printed to the console.

## Basic Syntax

Here's a quick overview of Razen's basic syntax:

### Variables

```razen
# Variable declaration with 'take'
take name = "John";
take age = 30;
take is_active = true;

# Variable declaration with 'let'
let score = 95;

# Print variables
show name;
show "Age: " + age;
```

### Conditionals

```razen
take temperature = 25;

if (temperature > 30) {
    show "It's hot outside!";
} else if (temperature > 20) {
    show "It's a nice day!";
} else {
    show "It's cold outside!";
}
```

### Loops

```razen
# While loop
take count = 0;
while (count < 5) {
    show count;
    let count = count + 1;
}

# For loop
for (i in [1, 2, 3, 4, 5]) {
    show "Number: " + i;
}
```

### Functions

```razen
# Define a function
fun greet(name) {
    show "Hello, " + name + "!";
}

# Call the function
greet("Alice");
```

## Next Steps

Now that you've created your first Razen program, you can:

- Explore the [Language Reference](../language-reference/README.md) for detailed syntax information
- Check out the [Examples](../examples/README.md) for more complex code samples
- Follow the [Tutorials](../tutorials/README.md) for step-by-step guides

Happy coding with Razen!
