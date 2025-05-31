/**
 * Razen Language Data for Autocomplete
 * This file contains structured data about Razen language elements
 * for use in the VS Code extension's autocomplete functionality.
 */

// Razen Keywords
const razenKeywords = [
    {
        name: 'if',
        description: 'Conditional statement',
        documentation: 'Used for conditional execution of code blocks.\n\n```razen\nif (condition) {\n  // code to execute if condition is true\n}\n```'
    },
    {
        name: 'else',
        description: 'Alternative execution block',
        documentation: 'Used with if for fallback behavior.\n\n```razen\nif (condition) {\n  // code to execute if condition is true\n} else {\n  // code to execute if condition is false\n}\n```'
    },
    {
        name: 'elif',
        description: 'Else if execution block',
        documentation: 'Used for multiple condition checks.\n\n```razen\nif (condition1) {\n  // code to execute if condition1 is true\n} elif (condition2) {\n  // code to execute if condition2 is true\n} else {\n  // code to execute if all conditions are false\n}\n```'
    },
    {
        name: 'while',
        description: 'Loop control',
        documentation: 'Used for repeated execution based on a condition.\n\n```razen\nwhile (condition) {\n  // code to execute while condition is true\n}\n```'
    },
    {
        name: 'for',
        description: 'Iterative loop',
        documentation: 'Used for iterating over a range or collection.\n\n```razen\nfor (num i = 0; i < 10; i = i + 1) {\n  // code to execute for each iteration\n}\n```'
    },
    {
        name: 'fun',
        description: 'Function declaration',
        documentation: 'Used to define a reusable function.\n\n```razen\nfun functionName(param1, param2) {\n  // function body\n  return result;\n}\n```'
    },
    {
        name: 'return',
        description: 'Function return value',
        documentation: 'Used to return a value from a function.\n\n```razen\nfun add(a, b) {\n  return a + b;\n}\n```'
    },
    {
        name: 'break',
        description: 'Exit loop',
        documentation: 'Used to exit a loop prematurely.\n\n```razen\nwhile (true) {\n  if (condition) {\n    break;\n  }\n}\n```'
    },
    {
        name: 'continue',
        description: 'Skip to next iteration',
        documentation: 'Used to skip the current iteration and continue with the next one.\n\n```razen\nfor (num i = 0; i < 10; i = i + 1) {\n  if (i % 2 == 0) {\n    continue;\n  }\n  // This code will only execute for odd values of i\n}\n```'
    },
    {
        name: 'and',
        description: 'Logical AND',
        documentation: 'Used for logical AND operations.\n\n```razen\nif (condition1 and condition2) {\n  // code to execute if both conditions are true\n}\n```'
    },
    {
        name: 'or',
        description: 'Logical OR',
        documentation: 'Used for logical OR operations.\n\n```razen\nif (condition1 or condition2) {\n  // code to execute if either condition is true\n}\n```'
    },
    {
        name: 'not',
        description: 'Logical negation',
        documentation: 'Used to invert a boolean value.\n\n```razen\nif (not condition) {\n  // code to execute if condition is false\n}\n```'
    },
    {
        name: 'try',
        description: 'Exception handling block',
        documentation: 'Used for handling exceptions.\n\n```razen\ntry {\n  // code that might throw an exception\n} catch {\n  // code to handle the exception\n}\n```'
    },
    {
        name: 'catch',
        description: 'Error capture',
        documentation: 'Used to catch exceptions thrown in a try block.\n\n```razen\ntry {\n  // code that might throw an exception\n} catch {\n  // code to handle the exception\n}\n```'
    },
    {
        name: 'throw',
        description: 'Raise exception',
        documentation: 'Used to throw an exception.\n\n```razen\nif (errorCondition) {\n  throw "Error message";\n}\n```'
    },
    {
        name: 'finally',
        description: 'Cleanup execution',
        documentation: 'Used for code that should always execute, regardless of whether an exception was thrown.\n\n```razen\ntry {\n  // code that might throw an exception\n} catch {\n  // code to handle the exception\n} finally {\n  // code that always executes\n}\n```'
    },
    {
        name: 'in',
        description: 'Membership test',
        documentation: 'Used to check if a value is in a collection.\n\n```razen\nif (element in collection) {\n  // code to execute if element is in collection\n}\n```'
    },
    {
        name: 'type',
        description: 'Document type declaration',
        documentation: 'Used to declare the type of document.\n\n```razen\ntype web;\n```\n\nAvailable options: web, script, cli, freestyle'
    },
    {
        name: 'use',
        description: 'Module import',
        documentation: 'Used to import modules.\n\n```razen\nuse module;\n```'
    },
    {
        name: 'export',
        description: 'Export definition',
        documentation: 'Used to export definitions from a module.\n\n```razen\nexport fun myFunction() { }\n```'
    },
    {
        name: 'as',
        description: 'Alias definition',
        documentation: 'Used to create an alias for an imported module.\n\n```razen\nuse module as m;\n```'
    },
    {
        name: 'from',
        description: 'Import source',
        documentation: 'Used to specify the source of an import.\n\n```razen\nimport { function } from module;\n```'
    },
    {
        name: 'import',
        description: 'Import specific items',
        documentation: 'Used to import specific items from a module.\n\n```razen\nimport { function } from module;\n```'
    },
    {
        name: 'class',
        description: 'Class definition',
        documentation: 'Used to define a class.\n\n```razen\nclass MyClass {\n  // class body\n}\n```'
    },
    {
        name: 'api',
        description: 'API declaration',
        documentation: 'Used to declare an API.\n\n```razen\napi MyAPI {\n  // API definition\n}\n```'
    },
    {
        name: 'call',
        description: 'API call',
        documentation: 'Used to make an API call.\n\n```razen\ncall MyAPI.endpoint(params);\n```'
    },
    {
        name: 'get',
        description: 'HTTP GET request',
        documentation: 'Used for HTTP GET requests.\n\n```razen\nget("https://example.com/api");\n```'
    },
    {
        name: 'post',
        description: 'HTTP POST request',
        documentation: 'Used for HTTP POST requests.\n\n```razen\npost("https://example.com/api", data);\n```'
    },
    {
        name: 'await',
        description: 'Async operation',
        documentation: 'Used to wait for an asynchronous operation to complete.\n\n```razen\nawait asyncFunction();\n```'
    },
    {
        name: 'connect',
        description: 'Connection establishment',
        documentation: 'Used to establish a connection to an external service.\n\n```razen\nconnect to "database";\n```'
    },
    {
        name: 'to',
        description: 'Connection target',
        documentation: 'Used to specify the target of a connection.\n\n```razen\nconnect to "database";\n```'
    },
    {
        name: 'debug',
        description: 'Debug mode',
        documentation: 'Used to enable debug mode.\n\n```razen\ndebug { // debugging code }\n```'
    },
    {
        name: 'assert',
        description: 'Assertion',
        documentation: 'Used to assert that a condition is true.\n\n```razen\nassert(condition, "Error message");\n```'
    },
    {
        name: 'trace',
        description: 'Execution tracing',
        documentation: 'Used to trace execution.\n\n```razen\ntrace { // code to trace }\n```'
    },
    {
        name: 'exit',
        description: 'Exit program',
        documentation: 'Used to exit the program.\n\n```razen\nexit;\n```'
    },
    {
        name: 'load',
        description: 'Loading animation',
        documentation: 'Used to display a loading animation.\n\n```razen\nload("Loading...");\n```'
    },
    {
        name: 'struct',
        description: 'Structure definition',
        documentation: 'Used to define a custom data structure.\n\n```razen\nstruct Person {\n  name: string,\n  age: number,\n  isActive: boolean\n}\n```'
    },
    {
        name: 'true',
        description: 'Boolean true value',
        documentation: 'Represents a boolean true value.\n\n```razen\nbool isActive = true;\n```'
    },
    {
        name: 'false',
        description: 'Boolean false value',
        documentation: 'Represents a boolean false value.\n\n```razen\nbool isActive = false;\n```'
    },
    {
        name: 'null',
        description: 'Null/undefined value',
        documentation: 'Represents a null or undefined value.\n\n```razen\nvar value = null;\n```'
    }
];

// Razen Variables with snippets
const razenVariables = [
    {
        name: 'num',
        signature: 'num variableName = value;',
        description: 'Numeric variable declaration',
        documentation: 'Used to declare a numeric variable. Should only be used with numeric values (integers or floats).\n\n```razen\n// Correct usage:\nnum counter = 42;\nnum pi = 3.14;\n\n// Incorrect usage (will cause errors):\n// num name = "John";  // Error: String value with num\n// num isActive = true;  // Error: Boolean value with num\n```',
        snippet: 'num ${1:variableName} = ${2:numericValue};'
    },
    {
        name: 'str',
        signature: 'str variableName = value;',
        description: 'String variable declaration',
        documentation: 'Used for declaring string variables and text manipulation.\n\n```razen\nstr message = "Hello, World!";\n```',
        snippet: 'str ${1:variableName} = "${2:value}"'
    },
    {
        name: 'bool',
        signature: 'bool variableName = value;',
        description: 'Boolean variable declaration',
        documentation: 'Used to declare a boolean variable. Should only be used with boolean values (true/false).\n\n```razen\n// Correct usage:\nbool isActive = true;\nbool hasPermission = false;\nbool comparison = 5 > 3;  // Boolean expression\n\n// Incorrect usage (will cause errors):\n// bool count = 42;  // Error: Numeric value with bool\n// bool name = "John";  // Error: String value with bool\n```',
        snippet: 'bool ${1:variableName} = ${2|true,false|};'
    },
    {
        name: 'var',
        signature: 'var variableName = value;',
        description: 'Generic variable declaration',
        documentation: 'Used for declaring variables of any type.\n\n```razen\nvar data = { name: "John", age: 30 };\n```',
        snippet: 'var ${1:variableName} = ${2:value}'
    },
    {
        name: 'const',
        signature: 'const variableName = value;',
        description: 'Constant variable declaration',
        documentation: 'Used to declare a constant variable.\n\n```razen\nconst PI = 3.14;\n```',
        snippet: 'const ${1:variableName} = ${2:value}'
    },
    {
        name: 'num',
        signature: 'num variableName = value1 + value2;',
        description: 'Numeric variable with addition',
        documentation: 'Used to declare a numeric variable that stores the result of addition. Should only be used with numeric expressions.\n\n```razen\n// Correct usage:\nnum total = 10 + 20;\nnum result = a + b;  // Where a and b are numeric\n\n// Incorrect usage (will cause errors):\n// num message = "Hello" + "World";  // Error: String concatenation with num\n```',
        snippet: 'num ${1:variableName} = ${2:numericValue1} + ${3:numericValue2};'
    },
    {
        name: 'num',
        signature: 'num variableName = value1 - value2;',
        description: 'Numeric variable with subtraction',
        documentation: 'Used for declaring a numeric variable with subtraction.\n\n```razen\nnum result = a - b;\n```',
        snippet: 'num ${1:variableName} = ${2:a} - ${3:b}'
    },
    {
        name: 'num',
        signature: 'num variableName = value1 * value2;',
        description: 'Numeric variable with multiplication',
        documentation: 'Used to declare a numeric variable that stores the result of multiplication. Should only be used with numeric expressions.\n\n```razen\n// Correct usage:\nnum result = 5 * 10;\nnum area = width * height;  // Where width and height are numeric\n\n// Incorrect usage (will cause errors):\n// num result = "Hello" * 3;  // Error: String multiplication with num\n```',
        snippet: 'num ${1:variableName} = ${2:numericValue1} * ${3:numericValue2};'
    },
    {
        name: 'num',
        signature: 'num variableName = value1 / value2;',
        description: 'Numeric variable with division',
        documentation: 'Used for declaring a numeric variable with division.\n\n```razen\nnum result = a / b;\n```',
        snippet: 'num ${1:variableName} = ${2:a} / ${3:b}'
    },
    {
        name: 'num',
        signature: 'num variableName = value1 % value2;',
        description: 'Numeric variable with modulus',
        documentation: 'Used to declare a numeric variable that stores the remainder of division. Should only be used with numeric expressions.\n\n```razen\n// Correct usage:\nnum result = 10 % 3;  // result = 1\nnum isEven = number % 2;  // 0 if even, 1 if odd\n\n// Incorrect usage (will cause errors):\n// num result = "Hello" % 2;  // Error: String modulus with num\n```',
        snippet: 'num ${1:variableName} = ${2:numericValue1} % ${3:numericValue2};'
    },
    {
        name: 'power',
        description: 'Exponentiation operation',
        documentation: 'Used for calculating the power of a value.\n\n```razen\npower result = a ** b;\n```',
        snippet: 'power ${1:variableName} = ${2:a} ** ${3:b}'
    },
    {
        name: 'text',
        signature: 'text variableName = value;',
        description: 'String data storage',
        documentation: 'Used to declare a variable for storing string data. Should only be used with string values.\n\n```razen\n// Correct usage:\ntext greeting = "Hello, World!";\ntext name = "John";\n\n// Incorrect usage (will cause errors):\n// text count = 42;  // Error: Numeric value with text\n// text isActive = true;  // Error: Boolean value with text\n```',
        snippet: 'text ${1:variableName} = "${2:stringValue}";'
    },
    {
        name: 'list',
        description: 'Dynamic array declaration',
        documentation: 'Used for storing multiple values of any type.\n\n```razen\nlist items = [1, 2, 3, 4, 5];\n```',
        snippet: 'list ${1:variableName} = [${2:items}]'
    },
    {
        name: 'map',
        description: 'Key-value storage',
        documentation: 'Used for storing related data with unique keys.\n\n```razen\nmap person = { name: "John", age: 30 };\n```',
        snippet: 'map ${1:variableName} = { ${2:key}: ${3:value} }'
    },
    {
        name: 'show',
        description: 'Output display',
        documentation: 'Used for displaying results and messages.\n\n```razen\nshow "Hello, World!";\nshow variable;\n```',
        snippet: 'show ${1:message}'
    },
    {
        name: 'read',
        description: 'User input',
        documentation: 'Used for getting user input and data entry.\n\n```razen\nread userInput;\n```',
        snippet: 'read ${1:variableName}'
    }
];

// Razen Functions with snippets
const razenFunctions = [
    {
        name: 'plus',
        signature: 'plus(a, b)',
        description: 'Adds two values',
        documentation: 'Returns the sum of two values.\n\n```razen\nlet result = plus(5, 3); // result = 8\n```',
        snippet: 'plus(${1:a}, ${2:b})'
    },
    {
        name: 'minus',
        signature: 'minus(a, b)',
        description: 'Subtracts two values',
        documentation: 'Returns the difference between two values.\n\n```razen\nlet result = minus(5, 3); // result = 2\n```',
        snippet: 'minus(${1:a}, ${2:b})'
    },
    {
        name: 'times',
        signature: 'times(a, b)',
        description: 'Multiplies two values',
        documentation: 'Returns the product of two values.\n\n```razen\nlet result = times(5, 3); // result = 15\n```',
        snippet: 'times(${1:a}, ${2:b})'
    },
    {
        name: 'by',
        signature: 'by(a, b)',
        description: 'Divides two values',
        documentation: 'Returns the quotient of two values.\n\n```razen\nlet result = by(6, 3); // result = 2\n```',
        snippet: 'by(${1:a}, ${2:b})'
    },
    {
        name: 'mod',
        signature: 'mod(a, b)',
        description: 'Calculates modulus',
        documentation: 'Returns the remainder of dividing two values.\n\n```razen\nlet result = mod(7, 3); // result = 1\n```',
        snippet: 'mod(${1:a}, ${2:b})'
    },
    {
        name: 'power',
        signature: 'power(a, b)',
        description: 'Calculates exponentiation',
        documentation: 'Returns the result of raising a to the power of b.\n\n```razen\nlet result = power(2, 3); // result = 8\n```',
        snippet: 'power(${1:a}, ${2:b})'
    },
    {
        name: 'round',
        signature: 'round(num)',
        description: 'Rounds a number',
        documentation: 'Returns the rounded value of a number.\n\n```razen\nlet result = round(3.7); // result = 4\n```',
        snippet: 'round(${1:num})'
    },
    {
        name: 'sqrt',
        signature: 'sqrt(num)',
        description: 'Calculates square root',
        documentation: 'Returns the square root of a number.\n\n```razen\nlet result = sqrt(9); // result = 3\n```',
        snippet: 'sqrt(${1:num})'
    },
    {
        name: 'abs',
        signature: 'abs(num)',
        description: 'Calculates absolute value',
        documentation: 'Returns the absolute value of a number.\n\n```razen\nlet result = abs(-5); // result = 5\n```',
        snippet: 'abs(${1:num})'
    },
    {
        name: 'size',
        signature: 'size(str)',
        description: 'Gets string length',
        documentation: 'Returns the length of a string.\n\n```razen\nlet length = size("Hello"); // length = 5\n```',
        snippet: 'size(${1:str})'
    },
    {
        name: 'join',
        signature: 'join(str1, str2)',
        description: 'Concatenates strings',
        documentation: 'Returns the concatenation of two strings.\n\n```razen\ntake result = join("Hello, ", "World!"); // result = "Hello, World!"\n```',
        snippet: 'join(${1:str1}, ${2:str2})'
    },
    {
        name: 'big',
        signature: 'big(str)',
        description: 'Converts to uppercase',
        documentation: 'Returns the uppercase version of a string.\n\n```razen\ntake result = big("hello"); // result = "HELLO"\n```',
        snippet: 'big(${1:str})'
    },
    {
        name: 'small',
        signature: 'small(str)',
        description: 'Converts to lowercase',
        documentation: 'Returns the lowercase version of a string.\n\n```razen\ntake result = small("HELLO"); // result = "hello"\n```',
        snippet: 'small(${1:str})'
    },
    {
        name: 'split',
        signature: 'split(str, delim)',
        description: 'Splits string into array',
        documentation: 'Returns an array of substrings split by the delimiter.\n\n```razen\nlist parts = split("a,b,c", ","); // parts = ["a", "b", "c"]\n```',
        snippet: 'split(${1:str}, ${2:delim})'
    },
    {
        name: 'replace',
        signature: 'replace(str, old, new)',
        description: 'Replaces substring',
        documentation: 'Returns a new string with all occurrences of old replaced by new.\n\n```razen\ntake result = replace("Hello, World!", "World", "Razen"); // result = "Hello, Razen!"\n```',
        snippet: 'replace(${1:str}, ${2:old}, ${3:new})'
    },
    {
        name: 'trim',
        signature: 'trim(str)',
        description: 'Removes whitespace',
        documentation: 'Returns a new string with whitespace removed from both ends.\n\n```razen\ntake result = trim("  Hello  "); // result = "Hello"\n```',
        snippet: 'trim(${1:str})'
    },
    {
        name: 'find',
        signature: 'find(str, substr)',
        description: 'Finds substring position',
        documentation: 'Returns the position of the first occurrence of substr in str, or -1 if not found.\n\n```razen\nlet position = find("Hello, World!", "World"); // position = 7\n```',
        snippet: 'find(${1:str}, ${2:substr})'
    },
    {
        name: 'count',
        signature: 'count(arr)',
        description: 'Gets array length',
        documentation: 'Returns the number of elements in an array.\n\n```razen\nlet length = count([1, 2, 3, 4, 5]); // length = 5\n```',
        snippet: 'count(${1:arr})'
    },
    {
        name: 'add',
        signature: 'add(arr, item)',
        description: 'Adds item to array',
        documentation: 'Adds an item to the end of an array.\n\n```razen\nlist numbers = [1, 2, 3];\nadd(numbers, 4); // numbers = [1, 2, 3, 4]\n```',
        snippet: 'add(${1:arr}, ${2:item})'
    },
    {
        name: 'take',
        signature: 'take(arr)',
        description: 'Removes last item from array',
        documentation: 'Removes and returns the last item from an array.\n\n```razen\nlist numbers = [1, 2, 3, 4];\nlet last = take(numbers); // last = 4, numbers = [1, 2, 3]\n```',
        snippet: 'take(${1:arr})'
    },
    {
        name: 'clear',
        signature: 'clear(arr)',
        description: 'Empties an array',
        documentation: 'Removes all elements from an array.\n\n```razen\nlist numbers = [1, 2, 3, 4];\nclear(numbers); // numbers = []\n```',
        snippet: 'clear(${1:arr})'
    },
    {
        name: 'sort',
        signature: 'sort(arr)',
        description: 'Sorts an array',
        documentation: 'Sorts the elements of an array in place.\n\n```razen\nlist numbers = [3, 1, 4, 2];\nsort(numbers); // numbers = [1, 2, 3, 4]\n```',
        snippet: 'sort(${1:arr})'
    },
    {
        name: 'reverse',
        signature: 'reverse(arr)',
        description: 'Reverses an array',
        documentation: 'Reverses the elements of an array in place.\n\n```razen\nlist numbers = [1, 2, 3, 4];\nreverse(numbers); // numbers = [4, 3, 2, 1]\n```',
        snippet: 'reverse(${1:arr})'
    },
    {
        name: 'keys',
        signature: 'keys(obj)',
        description: 'Gets all keys from object',
        documentation: 'Returns an array of all keys in an object.\n\n```razen\nmap person = { name: "John", age: 30 };\nlist allKeys = keys(person); // allKeys = ["name", "age"]\n```',
        snippet: 'keys(${1:obj})'
    },
    {
        name: 'values',
        signature: 'values(obj)',
        description: 'Gets all values from object',
        documentation: 'Returns an array of all values in an object.\n\n```razen\nmap person = { name: "John", age: 30 };\nlist allValues = values(person); // allValues = ["John", 30]\n```',
        snippet: 'values(${1:obj})'
    },
    {
        name: 'contains',
        signature: 'contains(obj, key)',
        description: 'Checks if key exists in object',
        documentation: 'Returns true if the object contains the specified key, false otherwise.\n\n```razen\nmap person = { name: "John", age: 30 };\nhold hasName = contains(person, "name"); // hasName = true\n```',
        snippet: 'contains(${1:obj}, ${2:key})'
    },
    {
        name: 'remove',
        signature: 'remove(obj, key)',
        description: 'Removes key-value pair from object',
        documentation: 'Removes the specified key-value pair from an object.\n\n```razen\nmap person = { name: "John", age: 30 };\nremove(person, "age"); // person = { name: "John" }\n```',
        snippet: 'remove(${1:obj}, ${2:key})'
    },
    {
        name: 'get',
        signature: 'get(obj, key)',
        description: 'Gets value from object by key',
        documentation: 'Returns the value associated with the specified key in an object.\n\n```razen\nmap person = { name: "John", age: 30 };\ntake name = get(person, "name"); // name = "John"\n```',
        snippet: 'get(${1:obj}, ${2:key})'
    },



    {
        name: 'sleep',
        signature: 'sleep(ms)',
        description: 'Delays execution',
        documentation: 'Pauses execution for the specified number of milliseconds.\n\n```razen\nsleep(1000); // Pauses for 1 second\n```',
        snippet: 'sleep(${1:ms})'
    },
    {
        name: 'say',
        signature: 'say(message)',
        description: 'Displays output',
        documentation: 'Displays a message to the user.\n\n```razen\nsay("Hello, World!");\n```',
        snippet: 'say(${1:message})'
    },
    {
        name: 'ask',
        signature: 'ask(question)',
        description: 'Gets user input',
        documentation: 'Prompts the user with a question and returns their response.\n\n```razen\ntake name = ask("What is your name?");\n```',
        snippet: 'ask(${1:question})'
    },
    {
        name: 'write',
        signature: 'write(file, data)',
        description: 'Writes to file',
        documentation: 'Writes data to a file.\n\n```razen\nwrite("output.txt", "Hello, World!");\n```',
        snippet: 'write(${1:file}, ${2:data})'
    },
    {
        name: 'read_file',
        signature: 'read_file(file)',
        description: 'Reads from file',
        documentation: 'Reads data from a file.\n\n```razen\ntake content = read_file("input.txt");\n```',
        snippet: 'read_file(${1:file})'
    }
];

// Razen Constants
const razenConstants = [
    {
        name: 'MATH_PI',
        description: 'Mathematical constant PI',
        documentation: 'The mathematical constant π (pi), approximately 3.14159265359.\n\n```razen\nlet area = MATH_PI * radius * radius;\n```'
    },
    {
        name: 'MATH_E',
        description: 'Mathematical constant E',
        documentation: 'The mathematical constant e, approximately 2.71828182846.\n\n```razen\nlet compound = principal * MATH_E ** rate;\n```'
    },
    {
        name: 'MATH_TAU',
        description: 'Mathematical constant TAU (2π)',
        documentation: 'The mathematical constant τ (tau), which equals 2π, approximately 6.28318530718.\n\n```razen\nlet circumference = MATH_TAU * radius;\n```'
    },
    {
        name: 'MATH_INF',
        description: 'Mathematical infinity',
        documentation: 'Represents positive infinity.\n\n```razen\nlet infinity = MATH_INF;\n```'
    },
    {
        name: 'MATH_NAN',
        description: 'Not a Number',
        documentation: 'Represents a value that is not a valid number.\n\n```razen\nlet notANumber = MATH_NAN;\n```'
    },
    // Color constants for ANSI terminal output
    {
        name: 'red',
        description: 'Red color for console output',
        documentation: 'Used with show statement to display text in red.\n\n```razen\nshow(red) "Error message";\n```'
    },
    {
        name: 'green',
        description: 'Green color for console output',
        documentation: 'Used with show statement to display text in green.\n\n```razen\nshow(green) "Success message";\n```'
    },
    {
        name: 'blue',
        description: 'Blue color for console output',
        documentation: 'Used with show statement to display text in blue.\n\n```razen\nshow(blue) "Information";\n```'
    },
    {
        name: 'yellow',
        description: 'Yellow color for console output',
        documentation: 'Used with show statement to display text in yellow.\n\n```razen\nshow(yellow) "Warning message";\n```'
    },
    {
        name: 'magenta',
        description: 'Magenta color for console output',
        documentation: 'Used with show statement to display text in magenta.\n\n```razen\nshow(magenta) "Special message";\n```'
    },
    {
        name: 'cyan',
        description: 'Cyan color for console output',
        documentation: 'Used with show statement to display text in cyan.\n\n```razen\nshow(cyan) "Highlighted information";\n```'
    },
    {
        name: 'white',
        description: 'White color for console output',
        documentation: 'Used with show statement to display text in white.\n\n```razen\nshow(white) "Standard message";\n```'
    },
    {
        name: 'bright_red',
        description: 'Bright red color for console output',
        documentation: 'Used with show statement to display text in bright red.\n\n```razen\nshow(bright_red) "Critical error";\n```'
    },
    {
        name: 'bright_green',
        description: 'Bright green color for console output',
        documentation: 'Used with show statement to display text in bright green.\n\n```razen\nshow(bright_green) "Important success";\n```'
    },
    {
        name: 'bright_blue',
        description: 'Bright blue color for console output',
        documentation: 'Used with show statement to display text in bright blue.\n\n```razen\nshow(bright_blue) "Important information";\n```'
    },
    {
        name: 'bright_yellow',
        description: 'Bright yellow color for console output',
        documentation: 'Used with show statement to display text in bright yellow.\n\n```razen\nshow(bright_yellow) "Important warning";\n```'
    },
    {
        name: 'bright_magenta',
        description: 'Bright magenta color for console output',
        documentation: 'Used with show statement to display text in bright magenta.\n\n```razen\nshow(bright_magenta) "Important special message";\n```'
    },
    {
        name: 'bright_cyan',
        description: 'Bright cyan color for console output',
        documentation: 'Used with show statement to display text in bright cyan.\n\n```razen\nshow(bright_cyan) "Important highlighted information";\n```'
    },
    {
        name: 'bright_white',
        description: 'Bright white color for console output',
        documentation: 'Used with show statement to display text in bright white.\n\n```razen\nshow(bright_white) "Important standard message";\n```'
    },
    // Original color constants
    {
        name: 'COLOR_RED',
        description: 'Red color constant',
        documentation: 'Represents the color red for console or UI output.\n\n```razen\nshow COLOR_RED + "Error!" + COLOR_RESET;\n```'
    },
    {
        name: 'COLOR_GREEN',
        description: 'Green color constant',
        documentation: 'Represents the color green for console or UI output.\n\n```razen\nshow COLOR_GREEN + "Success!" + COLOR_RESET;\n```'
    },
    {
        name: 'COLOR_BLUE',
        description: 'Blue color constant',
        documentation: 'Represents the color blue for console or UI output.\n\n```razen\nshow COLOR_BLUE + "Information" + COLOR_RESET;\n```'
    },
    {
        name: 'COLOR_YELLOW',
        description: 'Yellow color constant',
        documentation: 'Represents the color yellow for console or UI output.\n\n```razen\nshow COLOR_YELLOW + "Warning!" + COLOR_RESET;\n```'
    },
    {
        name: 'COLOR_RESET',
        description: 'Reset color constant',
        documentation: 'Resets the color back to default for console or UI output.\n\n```razen\nshow COLOR_RED + "Error!" + COLOR_RESET;\n```'
    },
    {
        name: 'ENV_DEVELOPMENT',
        description: 'Development environment constant',
        documentation: 'Represents the development environment.\n\n```razen\nif (environment == ENV_DEVELOPMENT) {\n  show "Debug mode enabled";\n}\n```'
    },
    {
        name: 'ENV_PRODUCTION',
        description: 'Production environment constant',
        documentation: 'Represents the production environment.\n\n```razen\nif (environment == ENV_PRODUCTION) {\n  show "Running in production mode";\n}\n```'
    },
    {
        name: 'ENV_TEST',
        description: 'Test environment constant',
        documentation: 'Represents the test environment.\n\n```razen\nif (environment == ENV_TEST) {\n  show "Running tests";\n}\n```'
    },
    {
        name: 'OS_WINDOWS',
        description: 'Windows OS constant',
        documentation: 'Represents the Windows operating system.\n\n```razen\nif (os == OS_WINDOWS) {\n  show "Running on Windows";\n}\n```'
    },
    {
        name: 'OS_MACOS',
        description: 'macOS constant',
        documentation: 'Represents the macOS operating system.\n\n```razen\nif (os == OS_MACOS) {\n  show "Running on macOS";\n}\n```'
    },
    {
        name: 'OS_LINUX',
        description: 'Linux OS constant',
        documentation: 'Represents the Linux operating system.\n\n```razen\nif (os == OS_LINUX) {\n  show "Running on Linux";\n}\n```'
    }
];

// Razen Library Data
const razenLibraries = [
    {
        name: 'arrlib',
        description: 'Array Library',
        functions: [
            { name: 'push', description: 'Adds an element to an array', signature: 'ArrLib[push](array, element)' },
            { name: 'pop', description: 'Removes and returns the last element', signature: 'ArrLib[pop](array)' },
            { name: 'join', description: 'Joins array elements with a delimiter', signature: 'ArrLib[join](array, delimiter)' },
            { name: 'length', description: 'Returns the array length', signature: 'ArrLib[length](array)' },
            { name: 'unique', description: 'Returns array with unique elements', signature: 'ArrLib[unique](array)' }
        ]
    },
    {
        name: 'strlib',
        description: 'String Library',
        functions: [
            { name: 'upper', description: 'Converts string to uppercase', signature: 'StrLib[upper](string)' },
            { name: 'lower', description: 'Converts string to lowercase', signature: 'StrLib[lower](string)' },
            { name: 'substring', description: 'Extracts a substring', signature: 'StrLib[substring](string, start, end)' },
            { name: 'replace', description: 'Replaces text in a string', signature: 'StrLib[replace](string, search, replacement)' },
            { name: 'length', description: 'Returns the string length', signature: 'StrLib[length](string)' },
            { name: 'split', description: 'Splits string by delimiter', signature: 'StrLib[split](string, delimiter)' },
            { name: 'trim', description: 'Removes whitespace from ends', signature: 'StrLib[trim](string)' },
            { name: 'starts_with', description: 'Checks if string starts with prefix', signature: 'StrLib[starts_with](string, prefix)' },
            { name: 'ends_with', description: 'Checks if string ends with suffix', signature: 'StrLib[ends_with](string, suffix)' },
            { name: 'contains', description: 'Checks if string contains substring', signature: 'StrLib[contains](string, substring)' },
            { name: 'repeat', description: 'Repeats string n times', signature: 'StrLib[repeat](string, count)' }
        ]
    },
    {
        name: 'mathlib',
        description: 'Math Library',
        functions: [
            { name: 'add', description: 'Adds two numbers', signature: 'MathLib[add](a, b)' },
            { name: 'subtract', description: 'Subtracts two numbers', signature: 'MathLib[subtract](a, b)' },
            { name: 'multiply', description: 'Multiplies two numbers', signature: 'MathLib[multiply](a, b)' },
            { name: 'divide', description: 'Divides two numbers', signature: 'MathLib[divide](a, b)' },
            { name: 'power', description: 'Raises a to the power of b', signature: 'MathLib[power](a, b)' },
            { name: 'sqrt', description: 'Square root of a number', signature: 'MathLib[sqrt](number)' },
            { name: 'abs', description: 'Absolute value of a number', signature: 'MathLib[abs](number)' },
            { name: 'round', description: 'Rounds a number', signature: 'MathLib[round](number)' },
            { name: 'floor', description: 'Rounds down to nearest integer', signature: 'MathLib[floor](number)' },
            { name: 'ceil', description: 'Rounds up to nearest integer', signature: 'MathLib[ceil](number)' },
            { name: 'sin', description: 'Sine of an angle', signature: 'MathLib[sin](angle)' },
            { name: 'cos', description: 'Cosine of an angle', signature: 'MathLib[cos](angle)' },
            { name: 'tan', description: 'Tangent of an angle', signature: 'MathLib[tan](angle)' },
            { name: 'log', description: 'Logarithm of a number', signature: 'MathLib[log](number, base)' },
            { name: 'exp', description: 'Exponential function', signature: 'MathLib[exp](number)' },
            { name: 'random', description: 'Random number between 0 and 1', signature: 'MathLib[random]()' },
            { name: 'max', description: 'Maximum of numbers', signature: 'MathLib[max](a, b, ...)' },
            { name: 'min', description: 'Minimum of numbers', signature: 'MathLib[min](a, b, ...)' },
            { name: 'modulo', description: 'Modulo operation', signature: 'MathLib[modulo](a, b)' }
        ]
    },
    {
        name: 'timelib',
        description: 'Time Library',
        functions: [
            { name: 'now', description: 'Current timestamp', signature: 'TimeLib[now]()' },
            { name: 'format', description: 'Format timestamp', signature: 'TimeLib[format](timestamp, format)' },
            { name: 'parse', description: 'Parse date string', signature: 'TimeLib[parse](dateString)' },
            { name: 'sleep', description: 'Sleep for milliseconds', signature: 'TimeLib[sleep](milliseconds)' }
        ]
    },
    {
        name: 'random',
        description: 'Random Library',
        functions: [
            { name: 'int', description: 'Random integer in range', signature: 'Random[int](min, max)' },
            { name: 'float', description: 'Random float in range', signature: 'Random[float](min, max)' },
            { name: 'choice', description: 'Random element from array', signature: 'Random[choice](array)' },
            { name: 'shuffle', description: 'Shuffles an array', signature: 'Random[shuffle](array)' }
        ]
    },
    {
        name: 'file',
        description: 'File Library',
        functions: [
            { name: 'read', description: 'Read file contents', signature: 'File[read](path)' },
            { name: 'write', description: 'Write to file', signature: 'File[write](path, content)' },
            { name: 'append', description: 'Append to file', signature: 'File[append](path, content)' },
            { name: 'exists', description: 'Check if file exists', signature: 'File[exists](path)' }
        ]
    },
    {
        name: 'json',
        description: 'JSON Library',
        functions: [
            { name: 'parse', description: 'Parse JSON string', signature: 'JSON[parse](jsonString)' },
            { name: 'stringify', description: 'Convert to JSON string', signature: 'JSON[stringify](object)' }
        ]
    },
    {
        name: 'bolt',
        description: 'Bolt Library for intensive operations',
        functions: [
            { name: 'run', description: 'Runs intensive operation', signature: 'Bolt[run](operation)' },
            { name: 'parallel', description: 'Runs operations in parallel', signature: 'Bolt[parallel](items, operation)' }
        ]
    },
    {
        name: 'seed',
        description: 'Seed Library for data generation',
        functions: [
            { name: 'generate', description: 'Generates a seed', signature: 'Seed[generate](length)' },
            { name: 'map', description: 'Creates a 2D map from seed', signature: 'Seed[map](seed, width, height)' }
        ]
    },
    {
        name: 'color',
        description: 'Color Library',
        functions: [
            { name: 'hex_to_rgb', description: 'Converts hex to RGB', signature: 'Color[hex_to_rgb](hexColor)' },
            { name: 'rgb_to_hex', description: 'Converts RGB to hex', signature: 'Color[rgb_to_hex](rgbArray)' },
            { name: 'lighten', description: 'Lightens a color', signature: 'Color[lighten](color, percentage)' },
            { name: 'darken', description: 'Darkens a color', signature: 'Color[darken](color, percentage)' },
            { name: 'get_ansi_color', description: 'Gets ANSI color code', signature: 'Color[get_ansi_color](colorName)' }
        ]
    },
    {
        name: 'crypto',
        description: 'Cryptography Library',
        functions: [
            { name: 'hash', description: 'Hash a string', signature: 'Crypto[hash](string)' },
            { name: 'encrypt', description: 'Encrypt data', signature: 'Crypto[encrypt](data, key)' },
            { name: 'decrypt', description: 'Decrypt data', signature: 'Crypto[decrypt](data, key)' }
        ]
    },
    {
        name: 'regex',
        description: 'Regular Expression Library',
        functions: [
            { name: 'match', description: 'Check if string matches pattern', signature: 'Regex[match](string, pattern)' },
            { name: 'search', description: 'Search for pattern in string', signature: 'Regex[search](string, pattern)' },
            { name: 'replace', description: 'Replace pattern in string', signature: 'Regex[replace](string, pattern, replacement)' }
        ]
    },
    {
        name: 'uuid',
        description: 'UUID Library',
        functions: [
            { name: 'generate', description: 'Generate a UUID', signature: 'UUID[generate]()' },
            { name: 'is_valid', description: 'Check if UUID is valid', signature: 'UUID[is_valid](uuid)' }
        ]
    },
    {
        name: 'os',
        description: 'Operating System Library',
        functions: [
            { name: 'env', description: 'Get environment variable', signature: 'OS[env](name)' },
            { name: 'cwd', description: 'Get current working directory', signature: 'OS[cwd]()' },
            { name: 'platform', description: 'Get platform name', signature: 'OS[platform]()' }
        ]
    },
    {
        name: 'filesystem',
        description: 'Filesystem Library',
        functions: [
            { name: 'exists', description: 'Check if file or directory exists', signature: 'Filesystem[exists](path)' },
            { name: 'is_file', description: 'Check if path is a file', signature: 'Filesystem[is_file](path)' },
            { name: 'is_dir', description: 'Check if path is a directory', signature: 'Filesystem[is_dir](path)' },
            { name: 'create_dir', description: 'Create a directory', signature: 'Filesystem[create_dir](path)' },
            { name: 'remove', description: 'Remove a file or directory', signature: 'Filesystem[remove](path)' },
            { name: 'read_file', description: 'Read file contents', signature: 'Filesystem[read_file](path)' },
            { name: 'write_file', description: 'Write content to file', signature: 'Filesystem[write_file](path, content)' },
            { name: 'list_dir', description: 'List directory contents', signature: 'Filesystem[list_dir](path)' },
            { name: 'metadata', description: 'Get file or directory metadata', signature: 'Filesystem[metadata](path)' },
            { name: 'absolute_path', description: 'Get absolute path', signature: 'Filesystem[absolute_path](path)' },
            { name: 'copy', description: 'Copy file or directory', signature: 'Filesystem[copy](source, destination)' },
            { name: 'move', description: 'Move file or directory', signature: 'Filesystem[move](source, destination)' },
            { name: 'extension', description: 'Get file extension', signature: 'Filesystem[extension](path)' },
            { name: 'file_stem', description: 'Get file name without extension', signature: 'Filesystem[file_stem](path)' },
            { name: 'parent_dir', description: 'Get parent directory', signature: 'Filesystem[parent_dir](path)' },
            { name: 'join_path', description: 'Join path components', signature: 'Filesystem[join_path](path1, path2, ...)' },
            { name: 'change_dir', description: 'Change current directory', signature: 'Filesystem[change_dir](path)' },
            { name: 'current_dir', description: 'Get current directory', signature: 'Filesystem[current_dir]()' },
            { name: 'temp_file', description: 'Create temporary file', signature: 'Filesystem[temp_file]()' },
            { name: 'temp_dir', description: 'Create temporary directory', signature: 'Filesystem[temp_dir]()' }
        ]
    },
    {
        name: 'lexerlib',
        description: 'Lexer Library',
        functions: [
            { name: 'create_lexer', description: 'Create a lexer instance', signature: 'LexerLib[create_lexer](source)' },
            { name: 'tokenize', description: 'Tokenize source code', signature: 'LexerLib[tokenize](source)' },
            { name: 'define_token', description: 'Define a token type', signature: 'LexerLib[define_token](name, pattern)' }
        ]
    },
    {
        name: 'parserlib',
        description: 'Parser Library',
        functions: [
            { name: 'create_parser', description: 'Create a parser instance', signature: 'ParserLib[create_parser](tokens)' },
            { name: 'parse', description: 'Parse tokens into AST', signature: 'ParserLib[parse](tokens)' },
            { name: 'define_rule', description: 'Define a grammar rule', signature: 'ParserLib[define_rule](name, pattern)' },
            { name: 'create_grammar', description: 'Create a grammar definition', signature: 'ParserLib[create_grammar](rules)' }
        ]
    },
    {
        name: 'astlib',
        description: 'AST Library',
        functions: [
            { name: 'create_node', description: 'Create an AST node', signature: 'ASTLib[create_node](type, value)' },
            { name: 'define_node_type', description: 'Define a node type', signature: 'ASTLib[define_node_type](name, fields)' },
            { name: 'traverse', description: 'Traverse an AST', signature: 'ASTLib[traverse](ast, visitor)' },
            { name: 'create_visitor', description: 'Create an AST visitor', signature: 'ASTLib[create_visitor](handlers)' }
        ]
    },
    {
        name: 'symbollib',
        description: 'Symbol Library',
        functions: [
            { name: 'create_symbol_table', description: 'Create a symbol table', signature: 'SymbolLib[create_symbol_table]()' },
            { name: 'define_symbol', description: 'Define a symbol', signature: 'SymbolLib[define_symbol](name, type)' },
            { name: 'add_symbol', description: 'Add a symbol to table', signature: 'SymbolLib[add_symbol](table, symbol)' },
            { name: 'lookup_symbol', description: 'Look up a symbol', signature: 'SymbolLib[lookup_symbol](table, name)' }
        ]
    },
    {
        name: 'typelib',
        description: 'Type Library',
        functions: [
            { name: 'define_type', description: 'Define a type', signature: 'TypeLib[define_type](name, fields)' },
            { name: 'check_type', description: 'Check type of value', signature: 'TypeLib[check_type](value, type)' },
            { name: 'create_type_system', description: 'Create a type system', signature: 'TypeLib[create_type_system]()' },
            { name: 'infer_type', description: 'Infer type of expression', signature: 'TypeLib[infer_type](expr)' }
        ]
    },
    {
        name: 'irlib',
        description: 'IR Library',
        functions: [
            { name: 'create_instruction', description: 'Create an IR instruction', signature: 'IRLib[create_instruction](opcode, operands)' },
            { name: 'generate', description: 'Generate IR from AST', signature: 'IRLib[generate](ast)' },
            { name: 'optimize', description: 'Optimize IR', signature: 'IRLib[optimize](ir)' },
            { name: 'to_string', description: 'Convert IR to string', signature: 'IRLib[to_string](ir)' }
        ]
    },
    {
        name: 'codegenlib',
        description: 'Code Generation Library',
        functions: [
            { name: 'create_generator', description: 'Create a code generator', signature: 'CodeGenLib[create_generator](target)' },
            { name: 'generate', description: 'Generate code from IR', signature: 'CodeGenLib[generate](ir)' },
            { name: 'define_target', description: 'Define a target platform', signature: 'CodeGenLib[define_target](name, options)' },
            { name: 'emit_code', description: 'Emit generated code', signature: 'CodeGenLib[emit_code](code, file)' }
        ]
    },
    {
        name: 'optimizelib',
        description: 'Optimization Library',
        functions: [
            { name: 'create_pass', description: 'Create an optimization pass', signature: 'OptimizeLib[create_pass](name, handler)' },
            { name: 'apply', description: 'Apply optimization pass', signature: 'OptimizeLib[apply](pass, ir)' },
            { name: 'analyze', description: 'Analyze code for optimizations', signature: 'OptimizeLib[analyze](ir)' },
            { name: 'create_pipeline', description: 'Create optimization pipeline', signature: 'OptimizeLib[create_pipeline](passes)' }
        ]
    },
    {
        name: 'validation',
        description: 'Validation Library',
        functions: [
            { name: 'email', description: 'Validate email address', signature: 'Validation[email](email)' },
            { name: 'phone', description: 'Validate phone number', signature: 'Validation[phone](phone)' },
            { name: 'required', description: 'Check if value is not empty', signature: 'Validation[required](value)' },
            { name: 'min_length', description: 'Check minimum length', signature: 'Validation[min_length](value, length)' }
        ]
    },
    {
        name: 'system',
        description: 'System Library',
        functions: [
            { name: 'exec', description: 'Execute system command', signature: 'System[exec](command)' },
            { name: 'uptime', description: 'Get system uptime', signature: 'System[uptime]()' },
            { name: 'info', description: 'Get system information', signature: 'System[info]()' }
        ]
    },
    {
        name: 'boxlib',
        description: 'Box Library for value boxing',
        functions: [
            { name: 'put', description: 'Box a value', signature: 'BoxLib[put](value)' },
            { name: 'get', description: 'Unbox a value', signature: 'BoxLib[get](box)' },
            { name: 'is_box', description: 'Check if value is boxed', signature: 'BoxLib[is_box](value)' }
        ]
    },
    {
        name: 'loglib',
        description: 'Logging Library',
        functions: [
            { name: 'info', description: 'Log info message', signature: 'LogLib[info](message)' },
            { name: 'warn', description: 'Log warning message', signature: 'LogLib[warn](message)' },
            { name: 'error', description: 'Log error message', signature: 'LogLib[error](message)' },
            { name: 'debug', description: 'Log debug message', signature: 'LogLib[debug](message)' }
        ]
    },
    {
        name: 'htlib',
        description: 'Head/Tails Library',
        functions: [
            { name: 'coin', description: 'Flip a coin', signature: 'HTLib[coin]()' },
            { name: 'bool', description: 'Generate random boolean', signature: 'HTLib[bool]()' }
        ]
    },
    {
        name: 'netlib',
        description: 'Network Library',
        functions: [
            { name: 'ping', description: 'Ping a host', signature: 'NetLib[ping](host)' },
            { name: 'get', description: 'HTTP GET request', signature: 'NetLib[get](url)' },
            { name: 'post', description: 'HTTP POST request', signature: 'NetLib[post](url, data)' }
        ]
    }
];

module.exports = {
    razenKeywords,
    razenVariables,
    razenFunctions,
    razenConstants,
    razenLibraries
};
