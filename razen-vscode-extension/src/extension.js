const vscode = require('vscode');
const { razenKeywords, razenVariables, razenFunctions, razenConstants, razenLibraries } = require('./razenLanguageData');
const { activateLanguageServer, deactivateLanguageServer } = require('./server/razenClient');
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('Razen Language Extension is now active!');
    
    // Activate the language server for error checking
    activateLanguageServer(context);
    
    // Register the run, debug, and test commands
    const runFileCommand = vscode.commands.registerCommand('razen.runFile', runRazenFile);    
    const debugFileCommand = vscode.commands.registerCommand('razen.debugFile', debugRazenFile);
    const testFileCommand = vscode.commands.registerCommand('razen.testFile', testRazenFile);
    
    context.subscriptions.push(runFileCommand);
    context.subscriptions.push(debugFileCommand);
    context.subscriptions.push(testFileCommand);

    // Register the completion item provider for Razen language
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        'razen',
        {
            provideCompletionItems(document, position, token, context) {
                // Get the current line text up to the cursor position
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                
                // Create a list to hold all completion items
                const completionItems = [];
                
                // Check for shorthand notation pattern (e.g., let.varname.value)
                const shorthandMatch = linePrefix.match(/^(\w+)\.(\w+)\.(.*)$/);
                if (shorthandMatch) {
                    const [fullMatch, keyword, varName, value] = shorthandMatch;
                    
                    // Create a completion item for the shorthand notation
                    const item = new vscode.CompletionItem(`${keyword} ${varName} = ${value}`, vscode.CompletionItemKind.Snippet);
                    item.detail = `Expand shorthand: ${fullMatch} → ${keyword} ${varName} = ${value}`;
                    item.documentation = new vscode.MarkdownString(
                        `Expands the shorthand notation \`${fullMatch}\` to a full variable declaration:\n\n` +
                        `\`\`\`razen\n${keyword} ${varName} = ${value};\n\`\`\``
                    );
                    
                    // Set the range to replace (the entire shorthand)
                    const startPos = new vscode.Position(position.line, 0);
                    const endPos = position;
                    const range = new vscode.Range(startPos, endPos);
                    
                    item.additionalTextEdits = [vscode.TextEdit.replace(range, `${keyword} ${varName} = ${value}`)];
                    
                    // Add the shorthand expansion as the only suggestion
                    return [item];
                }
                
                // Add document-specific items (variables and functions defined in the current document)
                const documentItems = getDocumentDefinedItems(document);
                completionItems.push(...documentItems);
                
                // Add language keywords
                const keywordItems = getKeywordCompletionItems();
                completionItems.push(...keywordItems);
                
                // Add language variables
                const variableItems = getVariableCompletionItems();
                completionItems.push(...variableItems);
                
                // Add language functions
                const functionItems = getFunctionCompletionItems();
                completionItems.push(...functionItems);
                
                // Add language constants
                const constantItems = getConstantCompletionItems();
                completionItems.push(...constantItems);
                
                // Add context-aware suggestions based on the line prefix
                const contextItems = getContextAwareCompletionItems(linePrefix, document, position);
                completionItems.push(...contextItems);
                
                // Add library-specific completions if in a library context
                const libraryItems = getLibraryCompletionItems(linePrefix);
                completionItems.push(...libraryItems);
                
                return completionItems;
            }
        },
        '.', // Trigger completion when a dot is typed
        ' ', // Trigger completion when a space is typed
        '(', // Trigger completion when an opening parenthesis is typed
        '{', // Trigger completion when an opening brace is typed
        '=', // Trigger completion when an equals sign is typed
        '"', // Trigger completion when a double quote is typed
        "'", // Trigger completion when a single quote is typed
        '+', // Trigger completion when a plus sign is typed (for string concatenation)
        ',', // Trigger completion when a comma is typed (for function arguments)
        '[', // Trigger completion when an opening bracket is typed (for arrays)
        ':' // Trigger completion when a colon is typed (for objects)
    );

    // Register a second provider specifically for shorthand notation
    const shorthandProvider = vscode.languages.registerCompletionItemProvider(
        'razen',
        {
            provideCompletionItems(document, position, token, context) {
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                
                // Check if we're typing a variable declaration keyword
                if (/^(num|str|bool|var|const)$/.test(linePrefix)) {
                    // Suggest shorthand notation
                    const item = new vscode.CompletionItem('Shorthand notation', vscode.CompletionItemKind.Snippet);
                    item.detail = 'Use shorthand notation for variable declaration';
                    item.documentation = new vscode.MarkdownString(
                        'Razen supports shorthand notation for variable declarations:\n\n' +
                        '`keyword.variableName.value` expands to `keyword variableName = value`\n\n' +
                        'Examples:\n' +
                        '- `num.count.0` → `num count = 0`\n' +
                        '- `str.name."John"` → `str name = "John"`\n' +
                        '- `bool.isActive.true` → `bool isActive = true`'
                    );
                    
                    item.insertText = new vscode.SnippetString('.${1:variableName}.${2:value}');
                    
                    return [item];
                }
                
                return [];
            }
        },
        '.' // Trigger after typing a variable declaration keyword followed by a dot
    );

    // Register a provider for template snippets (razen:web, razen:cli, etc.)
    const templateProvider = vscode.languages.registerCompletionItemProvider(
        'razen',
        {
            provideCompletionItems(document, position, token, context) {
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                
                // Check if we're typing a template prefix
                if (/^razen:/.test(linePrefix)) {
                    const completionItems = [];
                    
                    // ========== DOCUMENT TYPES ==========
                    
                    // Web application template (document type)
                    const webTemplate = new vscode.CompletionItem('razen:web', vscode.CompletionItemKind.Snippet);
                    webTemplate.detail = 'Create a Razen web application (document type)';
                    webTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a Razen web application (document type: web).\n\n' +
                        'Note: The web document type is still in development.'
                    );
                    webTemplate.insertText = new vscode.SnippetString(
                        'type web;\n\n' +
                        '# ${1:Razen Web Application}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Initialize DOM elements when page loads\n' +
                        'fun initializeApp() {\n' +
                        '\tstr appContainer = document.getElementById("app");\n' +
                        '\tappContainer.innerHTML = "<h1>Welcome to Razen Web App</h1>";\n\n' +
                        '\t# Add event listeners\n' +
                        '\tstr button = document.createElement("button");\n' +
                        '\tbutton.textContent = "Click Me";\n' +
                        '\tbutton.addEventListener("click", handleButtonClick);\n' +
                        '\tappContainer.appendChild(button);\n' +
                        '}\n\n' +
                        '# Event handler for button click\n' +
                        'fun handleButtonClick() {\n' +
                        '\tshow "Button clicked!";\n' +
                        '\tstr result = document.getElementById("result");\n' +
                        '\tif (result) {\n' +
                        '\t\tresult.textContent = "Button was clicked at " + new Date().toLocaleTimeString();\n' +
                        '\t} else {\n' +
                        '\t\tstr resultElement = document.createElement("div");\n' +
                        '\t\tresultElement.id = "result";\n' +
                        '\t\tresultElement.textContent = "Button was clicked at " + new Date().toLocaleTimeString();\n' +
                        '\t\tdocument.getElementById("app").appendChild(resultElement);\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Call the initialize function when the DOM is fully loaded\n' +
                        'document.addEventListener("DOMContentLoaded", initializeApp);\n'
                    );
                    
                    // CLI application template (document type)
                    const cliTemplate = new vscode.CompletionItem('razen:cli', vscode.CompletionItemKind.Snippet);
                    cliTemplate.detail = 'Create a Razen CLI application (document type)';
                    cliTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a Razen command-line interface application (document type: cli).'
                    );
                    cliTemplate.insertText = new vscode.SnippetString(
                        'type cli;\n\n' +
                        '# ${1:Razen CLI Application}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Application version\n' +
                        'const VERSION = "1.0.0";\n\n' +
                        '# Display welcome message\n' +
                        'fun showWelcome() {\n' +
                        '\tshow "===================================";\n' +
                        '\tshow "  ${1:Razen CLI Application} v" + VERSION;\n' +
                        '\tshow "===================================";\n' +
                        '\tshow "";\n' +
                        '}\n\n' +
                        '# Display help menu\n' +
                        'fun showHelp() {\n' +
                        '\tshow "Usage: razen app.rzn [command]";\n' +
                        '\tshow "";\n' +
                        '\tshow "Commands:";\n' +
                        '\tshow "  help     Display this help menu";\n' +
                        '\tshow "  version  Display application version";\n' +
                        '\tshow "  run      Run the main functionality";\n' +
                        '\tshow "";\n' +
                        '}\n\n' +
                        '# Process command line arguments\n' +
                        'fun processArgs(args) {\n' +
                        '\tif (args.length == 0) {\n' +
                        '\t\tshowWelcome();\n' +
                        '\t\tshowHelp();\n' +
                        '\t\treturn;\n' +
                        '\t}\n\n' +
                        '\ttake command = args[0];\n' +
                        '\t\n' +
                        '\tif (command == "help") {\n' +
                        '\t\tshowHelp();\n' +
                        '\t} else if (command == "version") {\n' +
                        '\t\tshow VERSION;\n' +
                        '\t} else if (command == "run") {\n' +
                        '\t\trunMain();\n' +
                        '\t} else {\n' +
                        '\t\tshow "Unknown command: " + command;\n' +
                        '\t\tshowHelp();\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Main application functionality\n' +
                        'fun runMain() {\n' +
                        '\tshowWelcome();\n' +
                        '\tshow "Running main application...";\n' +
                        '\t# Your application code here\n' +
                        '\t${2:// TODO: Implement main functionality}\n' +
                        '}\n\n' +
                        '# Start the application\n' +
                        'processArgs(process.argv.slice(2));\n'
                    );
                    
                    // Script template (document type)
                    const scriptTemplate = new vscode.CompletionItem('razen:script', vscode.CompletionItemKind.Snippet);
                    scriptTemplate.detail = 'Create a Razen script (document type)';
                    scriptTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a simple Razen script (document type: script).'
                    );
                    scriptTemplate.insertText = new vscode.SnippetString(
                        'type script;\n\n' +
                        '# ${1:Razen Script}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Variables\n' +
                        'num count = 0;\n' +
                        'str message = "Hello, Razen!";\n' +
                        'bool isActive = true;\n\n' +
                        '# Functions\n' +
                        'fun greet(name) {\n' +
                        '\treturn "Hello, " + name + "!";\n' +
                        '}\n\n' +
                        'fun increment(value, amount) {\n' +
                        '\treturn value + amount;\n' +
                        '}\n\n' +
                        '# Main script\n' +
                        'show message;\n\n' +
                        'take userName = "User";\n' +
                        'show greet(userName);\n\n' +
                        'count = increment(count, 5);\n' +
                        'show "Count: " + count;\n\n' +
                        'if (isActive) {\n' +
                        '\tshow "Script is active!";\n' +
                        '} else {\n' +
                        '\tshow "Script is inactive.";\n' +
                        '}\n'
                    );
                    
                    // Freestyle template (document type)
                    const freestyleTemplate = new vscode.CompletionItem('razen:freestyle', vscode.CompletionItemKind.Snippet);
                    freestyleTemplate.detail = 'Create a Razen freestyle program (document type)';
                    freestyleTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a freestyle Razen program (document type: freestyle).'
                    );
                    freestyleTemplate.insertText = new vscode.SnippetString(
                        'type freestyle;\n\n' +
                        '# ${1:Razen Freestyle Program}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# This is a freestyle Razen program where you can mix different paradigms\n\n' +
                        '# Variables\n' +
                        'take name = "Razen";\n' +
                        'let age = 1;\n' +
                        'hold isAwesome = true;\n\n' +
                        '# Display a welcome message\n' +
                        'show "Welcome to " + name + "!";\n' +
                        'show name + " is " + age + " year old.";\n\n' +
                        'if (isAwesome) {\n' +
                        '\tshow name + " is awesome!";\n' +
                        '}\n\n' +
                        '# Get user input\n' +
                        'show "What is your name?";\n' +
                        'read userName;\n' +
                        'show "Hello, " + userName + "!";\n\n' +
                        '# Create a simple loop\n' +
                        'num counter = 0;\n' +
                        'while (counter < 5) {\n' +
                        '\tshow "Counter: " + counter;\n' +
                        '\tcounter = counter + 1;\n' +
                        '}\n\n' +
                        'show "Program completed!";\n'
                    );
                    
                    // ========== FEATURES/COMPONENTS ==========
                    
                    // API template (feature/component)
                    const apiTemplate = new vscode.CompletionItem('razen:api', vscode.CompletionItemKind.Snippet);
                    apiTemplate.detail = 'Create a Razen API server (feature)';
                    apiTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a Razen API server (feature that works with script or web document types).'
                    );
                    apiTemplate.insertText = new vscode.SnippetString(
                        'type ${1|script,web|};\n\n' +
                        '# ${2:Razen API Server}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Import required modules\n' +
                        'const express = require("express");\n' +
                        'const cors = require("cors");\n' +
                        'const bodyParser = require("body-parser");\n\n' +
                        '# Initialize the Express app\n' +
                        'const app = express();\n' +
                        'const PORT = process.env.PORT || 3000;\n\n' +
                        '# Middleware\n' +
                        'app.use(cors());\n' +
                        'app.use(bodyParser.json());\n\n' +
                        '# Sample data\n' +
                        'take users = [\n' +
                        '\t{ id: 1, name: "John Doe", email: "john@example.com" },\n' +
                        '\t{ id: 2, name: "Jane Smith", email: "jane@example.com" }\n' +
                        '];\n\n' +
                        '# Routes\n' +
                        '# GET /api/users - Get all users\n' +
                        'app.get("/api/users", (req, res) => {\n' +
                        '\tres.json(users);\n' +
                        '});\n\n' +
                        '# GET /api/users/:id - Get user by ID\n' +
                        'app.get("/api/users/:id", (req, res) => {\n' +
                        '\ttake id = parseInt(req.params.id);\n' +
                        '\ttake user = users.find(u => u.id === id);\n' +
                        '\t\n' +
                        '\tif (user) {\n' +
                        '\t\tres.json(user);\n' +
                        '\t} else {\n' +
                        '\t\tres.status(404).json({ message: "User not found" });\n' +
                        '\t}\n' +
                        '});\n\n' +
                        '# POST /api/users - Create a new user\n' +
                        'app.post("/api/users", (req, res) => {\n' +
                        '\ttake { name, email } = req.body;\n' +
                        '\t\n' +
                        '\tif (!name || !email) {\n' +
                        '\t\treturn res.status(400).json({ message: "Name and email are required" });\n' +
                        '\t}\n' +
                        '\t\n' +
                        '\ttake newUser = {\n' +
                        '\t\tid: users.length + 1,\n' +
                        '\t\tname,\n' +
                        '\t\temail\n' +
                        '\t};\n' +
                        '\t\n' +
                        '\tusers.push(newUser);\n' +
                        '\tres.status(201).json(newUser);\n' +
                        '});\n\n' +
                        '# PUT /api/users/:id - Update a user\n' +
                        'app.put("/api/users/:id", (req, res) => {\n' +
                        '\ttake id = parseInt(req.params.id);\n' +
                        '\ttake { name, email } = req.body;\n' +
                        '\ttake userIndex = users.findIndex(u => u.id === id);\n' +
                        '\t\n' +
                        '\tif (userIndex === -1) {\n' +
                        '\t\treturn res.status(404).json({ message: "User not found" });\n' +
                        '\t}\n' +
                        '\t\n' +
                        '\tusers[userIndex] = { ...users[userIndex], name, email };\n' +
                        '\tres.json(users[userIndex]);\n' +
                        '});\n\n' +
                        '# DELETE /api/users/:id - Delete a user\n' +
                        'app.delete("/api/users/:id", (req, res) => {\n' +
                        '\ttake id = parseInt(req.params.id);\n' +
                        '\ttake userIndex = users.findIndex(u => u.id === id);\n' +
                        '\t\n' +
                        '\tif (userIndex === -1) {\n' +
                        '\t\treturn res.status(404).json({ message: "User not found" });\n' +
                        '\t}\n' +
                        '\t\n' +
                        '\tusers.splice(userIndex, 1);\n' +
                        '\tres.status(204).send();\n' +
                        '});\n\n' +
                        '# Start the server\n' +
                        'app.listen(PORT, () => {\n' +
                        '\tshow "API server running on port " + PORT;\n' +
                        '});\n'
                    );
                    
                    // Database template (feature/component)
                    const dbTemplate = new vscode.CompletionItem('razen:database', vscode.CompletionItemKind.Snippet);
                    dbTemplate.detail = 'Create a Razen database integration (feature)';
                    dbTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a Razen application with database integration (feature that works with any document type).'
                    );
                    dbTemplate.insertText = new vscode.SnippetString(
                        'type ${1|script,web,cli,freestyle|};\n\n' +
                        '# ${2:Razen Database Integration}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Import required modules\n' +
                        'const mysql = require("mysql2/promise");\n\n' +
                        '# Database configuration\n' +
                        'take dbConfig = {\n' +
                        '\thost: "localhost",\n' +
                        '\tuser: "root",\n' +
                        '\tpassword: "password",\n' +
                        '\tdatabase: "razen_db"\n' +
                        '};\n\n' +
                        '# Create a connection pool\n' +
                        'take pool = mysql.createPool(dbConfig);\n\n' +
                        '# Function to get all users\n' +
                        'async fun getUsers() {\n' +
                        '\ttry {\n' +
                        '\t\ttake [rows] = await pool.query("SELECT * FROM users");\n' +
                        '\t\treturn rows;\n' +
                        '\t} catch (error) {\n' +
                        '\t\tshow "Error getting users: " + error.message;\n' +
                        '\t\treturn [];\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Function to get user by ID\n' +
                        'async fun getUserById(id) {\n' +
                        '\ttry {\n' +
                        '\t\ttake [rows] = await pool.query("SELECT * FROM users WHERE id = ?", [id]);\n' +
                        '\t\treturn rows[0];\n' +
                        '\t} catch (error) {\n' +
                        '\t\tshow "Error getting user: " + error.message;\n' +
                        '\t\treturn null;\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Function to create a new user\n' +
                        'async fun createUser(name, email) {\n' +
                        '\ttry {\n' +
                        '\t\ttake [result] = await pool.query(\n' +
                        '\t\t\t"INSERT INTO users (name, email) VALUES (?, ?)",\n' +
                        '\t\t\t[name, email]\n' +
                        '\t\t);\n' +
                        '\t\treturn { id: result.insertId, name, email };\n' +
                        '\t} catch (error) {\n' +
                        '\t\tshow "Error creating user: " + error.message;\n' +
                        '\t\treturn null;\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Main function\n' +
                        'async fun main() {\n' +
                        '\tshow "Database Integration Example";\n' +
                        '\t\n' +
                        '\t# Create a new user\n' +
                        '\ttake newUser = await createUser("John Doe", "john@example.com");\n' +
                        '\tshow "Created user:", newUser;\n' +
                        '\t\n' +
                        '\t# Get all users\n' +
                        '\ttake users = await getUsers();\n' +
                        '\tshow "All users:", users;\n' +
                        '}\n\n' +
                        '# Run the main function\n' +
                        'main().catch(error => {\n' +
                        '\tshow "Error in main:", error;\n' +
                        '});\n'
                    );
                    
                    // Component template (feature/component)
                    const componentTemplate = new vscode.CompletionItem('razen:component', vscode.CompletionItemKind.Snippet);
                    componentTemplate.detail = 'Create a Razen component (feature)';
                    componentTemplate.documentation = new vscode.MarkdownString(
                        'Creates a template for a reusable Razen component (feature that works best with web document type).'
                    );
                    componentTemplate.insertText = new vscode.SnippetString(
                        'type ${1|web,script|};\n\n' +
                        '# ${2:Razen Component}\n' +
                        '# Created: ${CURRENT_YEAR}-${CURRENT_MONTH}-${CURRENT_DATE}\n\n' +
                        '# Component class\n' +
                        'class ${3:Component} {\n' +
                        '\t# Constructor\n' +
                        '\tconstructor(props) {\n' +
                        '\t\tthis.props = props || {};\n' +
                        '\t\tthis.state = {\n' +
                        '\t\t\tcount: 0,\n' +
                        '\t\t\tisActive: false\n' +
                        '\t\t};\n' +
                        '\t}\n\n' +
                        '\t# Method to update state\n' +
                        '\tsetState(newState) {\n' +
                        '\t\tthis.state = { ...this.state, ...newState };\n' +
                        '\t\tthis.render();\n' +
                        '\t}\n\n' +
                        '\t# Method to increment counter\n' +
                        '\tincrement() {\n' +
                        '\t\tthis.setState({ count: this.state.count + 1 });\n' +
                        '\t}\n\n' +
                        '\t# Method to toggle active state\n' +
                        '\ttoggleActive() {\n' +
                        '\t\tthis.setState({ isActive: !this.state.isActive });\n' +
                        '\t}\n\n' +
                        '\t# Render method\n' +
                        '\trender() {\n' +
                        '\t\ttake container = document.getElementById(this.props.containerId || "app");\n' +
                        '\t\tif (!container) return;\n\n' +
                        '\t\t# Clear container\n' +
                        '\t\tcontainer.innerHTML = "";\n\n' +
                        '\t\t# Create component elements\n' +
                        '\t\ttake componentEl = document.createElement("div");\n' +
                        '\t\tcomponentEl.className = "component " + (this.state.isActive ? "active" : "inactive");\n\n' +
                        '\t\t# Create title\n' +
                        '\t\ttake title = document.createElement("h2");\n' +
                        '\t\ttitle.textContent = this.props.title || "Razen Component";\n' +
                        '\t\tcomponentEl.appendChild(title);\n\n' +
                        '\t\t# Create counter display\n' +
                        '\t\ttake counter = document.createElement("p");\n' +
                        '\t\tcounter.textContent = "Count: " + this.state.count;\n' +
                        '\t\tcomponentEl.appendChild(counter);\n\n' +
                        '\t\t# Create increment button\n' +
                        '\t\ttake incButton = document.createElement("button");\n' +
                        '\t\tincButton.textContent = "Increment";\n' +
                        '\t\tincButton.onclick = () => this.increment();\n' +
                        '\t\tcomponentEl.appendChild(incButton);\n\n' +
                        '\t\t# Create toggle button\n' +
                        '\t\ttake toggleButton = document.createElement("button");\n' +
                        '\t\ttoggleButton.textContent = this.state.isActive ? "Deactivate" : "Activate";\n' +
                        '\t\ttoggleButton.onclick = () => this.toggleActive();\n' +
                        '\t\tcomponentEl.appendChild(toggleButton);\n\n' +
                        '\t\t# Append component to container\n' +
                        '\t\tcontainer.appendChild(componentEl);\n' +
                        '\t}\n' +
                        '}\n\n' +
                        '# Export the component\n' +
                        'module.exports = ${3:Component};\n'
                    );
                    
                    // Group templates by type for better organization
                    const documentTypeTemplates = [
                        webTemplate,
                        cliTemplate,
                        scriptTemplate,
                        freestyleTemplate
                    ];
                    
                    const featureTemplates = [
                        apiTemplate,
                        dbTemplate,
                        componentTemplate
                    ];
                    
                    // Add all templates to completion items
                    completionItems.push(...documentTypeTemplates, ...featureTemplates);
                    
                    return completionItems;
                }
                
                return [];
            }
        },
        ':' // Trigger after typing razen:
    );

    context.subscriptions.push(completionProvider, shorthandProvider, templateProvider);
}

/**
 * Get completion items for all Razen keywords
 * @returns {vscode.CompletionItem[]}
 */
function getKeywordCompletionItems() {
    return razenKeywords.map(keyword => {
        const item = new vscode.CompletionItem(keyword.name, vscode.CompletionItemKind.Keyword);
        item.detail = keyword.description;
        item.documentation = new vscode.MarkdownString(keyword.documentation || keyword.description);
        return item;
    });
}

/**
 * Get completion items for all Razen variables
 * @returns {vscode.CompletionItem[]}
 */
function getVariableCompletionItems() {
    return razenVariables.map(variable => {
        const item = new vscode.CompletionItem(variable.name, vscode.CompletionItemKind.Variable);
        item.detail = variable.description;
        item.documentation = new vscode.MarkdownString(variable.documentation || variable.description);
        
        // Add snippet support for variable declarations
        if (variable.snippet) {
            item.insertText = new vscode.SnippetString(variable.snippet);
        }
        
        // Add shorthand notation hint
        if (['let', 'take', 'hold', 'put'].includes(variable.name)) {
            const existingDoc = item.documentation.value;
            item.documentation = new vscode.MarkdownString(
                existingDoc + '\n\n**Shorthand Notation Available**:\n' +
                `\`${variable.name}.variableName.value\` expands to \`${variable.name} variableName = value\``
            );
        }
        
        return item;
    });
}

/**
 * Get completion items for all Razen functions
 * @returns {vscode.CompletionItem[]}
 */
function getFunctionCompletionItems() {
    return razenFunctions.map(func => {
        const item = new vscode.CompletionItem(func.name, vscode.CompletionItemKind.Function);
        item.detail = func.signature;
        item.documentation = new vscode.MarkdownString(func.documentation || func.description);
        
        // Add snippet support for function calls
        if (func.snippet) {
            item.insertText = new vscode.SnippetString(func.snippet);
        }
        
        return item;
    });
}

/**
 * Get completion items for all Razen constants
 * @returns {vscode.CompletionItem[]}
 */
function getConstantCompletionItems() {
    return razenConstants.map(constant => {
        const item = new vscode.CompletionItem(constant.name, vscode.CompletionItemKind.Constant);
        item.detail = constant.description;
        item.documentation = new vscode.MarkdownString(constant.documentation || constant.description);
        return item;
    });
}

/**
 * Get variables and functions defined in the current document
 * @param {vscode.TextDocument} document 
 * @returns {vscode.CompletionItem[]}
 */
function getDocumentDefinedItems(document) {
    const text = document.getText();
    const completionItems = [];
    
    // Regular expressions for finding variable declarations
    const varRegex = /(?:let|take|hold|put)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:=|\+|-|\*|\/|%|\(|{|$)/g;
    
    // Regular expression for finding function declarations
    const funcRegex = /fun\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(/g;
    
    // Regular expression for finding struct declarations
    const structRegex = /struct\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*{/g;
    
    // Find all variable declarations
    let match;
    while ((match = varRegex.exec(text)) !== null) {
        const varName = match[1];
        const item = new vscode.CompletionItem(varName, vscode.CompletionItemKind.Variable);
        item.detail = `(document variable) ${varName}`;
        item.documentation = new vscode.MarkdownString(`Variable defined in the current document.`);
        completionItems.push(item);
    }
    
    // Find all function declarations
    while ((match = funcRegex.exec(text)) !== null) {
        const funcName = match[1];
        const item = new vscode.CompletionItem(funcName, vscode.CompletionItemKind.Function);
        item.detail = `(document function) ${funcName}`;
        item.documentation = new vscode.MarkdownString(`Function defined in the current document.`);
        
        // Add snippet for function call
        item.insertText = new vscode.SnippetString(`${funcName}($\{1:arguments})`);
        
        completionItems.push(item);
    }
    
    // Find all struct declarations
    while ((match = structRegex.exec(text)) !== null) {
        const structName = match[1];
        const item = new vscode.CompletionItem(structName, vscode.CompletionItemKind.Class);
        item.detail = `(document struct) ${structName}`;
        item.documentation = new vscode.MarkdownString(`Struct defined in the current document.`);
        
        // Add snippet for struct instantiation
        item.insertText = new vscode.SnippetString(`${structName} { $\{1:properties} }`);
        
        completionItems.push(item);
    }
    
    return completionItems;
}

/**
 * Get context-aware completion items based on the current line and position
 * @param {string} linePrefix 
 * @param {vscode.TextDocument} document 
 * @param {vscode.Position} position 
 * @returns {vscode.CompletionItem[]}
 */
function getLibraryCompletionItems(linePrefix) {
    const completionItems = [];
    
    // Check if we're in a library function call context
    const libraryMatch = linePrefix.match(/([A-Z][a-zA-Z0-9]*)\s*\[\s*([a-zA-Z0-9_]*)$/i);
    if (libraryMatch) {
        const libraryName = libraryMatch[1].toLowerCase();
        const partialFunction = libraryMatch[2];
        
        // Find the matching library
        const library = razenLibraries.find(lib => lib.name.toLowerCase() === libraryName.toLowerCase());
        if (library) {
            // Add all functions from this library as completion items
            library.functions.forEach(func => {
                if (!partialFunction || func.name.startsWith(partialFunction)) {
                    const item = new vscode.CompletionItem(func.name, vscode.CompletionItemKind.Method);
                    item.detail = func.signature;
                    item.documentation = func.description;
                    completionItems.push(item);
                }
            });
        }
    }
    
    // Check if we're after 'lib' keyword to suggest libraries
    if (/\blib\s+([a-zA-Z0-9_]*)$/i.test(linePrefix)) {
        razenLibraries.forEach(library => {
            const item = new vscode.CompletionItem(library.name, vscode.CompletionItemKind.Module);
            item.detail = library.description;
            item.documentation = `Library for ${library.description.toLowerCase()}\n\nImport with: lib ${library.name};`;
            item.insertText = `${library.name};`;
            completionItems.push(item);
        });
    }
    
    return completionItems;
}

function getContextAwareCompletionItems(linePrefix, document, position) {
    const completionItems = [];
    
    // Check if we're after a string and a + sign (string concatenation)
    if (/["']\s*\+\s*$/.test(linePrefix)) {
        // After string concatenation, suggest variables
        const varItems = getDocumentDefinedItems(document).filter(
            item => item.kind === vscode.CompletionItemKind.Variable
        );
        completionItems.push(...varItems);
        
        // Also suggest string literals
        const stringLiterals = ['"text"', '"hello"', '""'];
        stringLiterals.forEach(value => {
            const item = new vscode.CompletionItem(value, vscode.CompletionItemKind.Value);
            item.detail = 'String literal';
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'type' keyword
    if (/type\s+$/.test(linePrefix)) {
        // Suggest document types
        const docTypes = ['web', 'script', 'cli', 'freestyle'];
        docTypes.forEach(type => {
            const item = new vscode.CompletionItem(type, vscode.CompletionItemKind.TypeParameter);
            item.detail = `Document type: ${type}`;
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'if', 'while', or similar control flow keywords
    if (/(?:if|while|elif)\s+$/.test(linePrefix)) {
        // Suggest variables for condition
        const varItems = getDocumentDefinedItems(document).filter(
            item => item.kind === vscode.CompletionItemKind.Variable
        );
        completionItems.push(...varItems);
        
        // Add common condition snippets
        const conditionSnippets = [
            { label: 'condition ==', snippet: '${1:variable} == ${2:value}' },
            { label: 'condition !=', snippet: '${1:variable} != ${2:value}' },
            { label: 'condition >', snippet: '${1:variable} > ${2:value}' },
            { label: 'condition <', snippet: '${1:variable} < ${2:value}' },
            { label: 'condition >=', snippet: '${1:variable} >= ${2:value}' },
            { label: 'condition <=', snippet: '${1:variable} <= ${2:value}' },
            { label: 'condition and', snippet: '${1:condition1} and ${2:condition2}' },
            { label: 'condition or', snippet: '${1:condition1} or ${2:condition2}' },
            { label: 'condition not', snippet: 'not ${1:condition}' }
        ];
        
        conditionSnippets.forEach(cond => {
            const item = new vscode.CompletionItem(cond.label, vscode.CompletionItemKind.Snippet);
            item.insertText = new vscode.SnippetString(cond.snippet);
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'for' keyword
    if (/for\s+$/.test(linePrefix)) {
        // Add for loop snippets
        const forSnippets = [
            { 
                label: 'for loop (range)', 
                snippet: '(let ${1:i} = 0; ${1:i} < ${2:count}; ${1:i} = ${1:i} + 1) {\n\t${3}\n}' 
            },
            { 
                label: 'for loop (array)', 
                snippet: '(let ${1:i} = 0; ${1:i} < ${2:array}.length; ${1:i} = ${1:i} + 1) {\n\t${3}\n}' 
            },
            {
                label: 'for loop (in)',
                snippet: '(${1:item} in ${2:array}) {\n\t${3}\n}'
            }
        ];
        
        forSnippets.forEach(snippet => {
            const item = new vscode.CompletionItem(snippet.label, vscode.CompletionItemKind.Snippet);
            item.insertText = new vscode.SnippetString(snippet.snippet);
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'fun' keyword
    if (/fun\s+$/.test(linePrefix)) {
        // Add function declaration snippets
        const functionSnippets = [
            {
                label: 'function (no params)',
                snippet: '${1:functionName}() {\n\t${2}\n}'
            },
            {
                label: 'function (with params)',
                snippet: '${1:functionName}(${2:param1}, ${3:param2}) {\n\t${4}\n}'
            },
            {
                label: 'function (with return)',
                snippet: '${1:functionName}(${2:params}) {\n\t${3}\n\treturn ${4:result};\n}'
            }
        ];
        
        functionSnippets.forEach(snippet => {
            const item = new vscode.CompletionItem(snippet.label, vscode.CompletionItemKind.Snippet);
            item.insertText = new vscode.SnippetString(snippet.snippet);
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'struct' keyword
    if (/struct\s+$/.test(linePrefix)) {
        // Add struct declaration snippet
        const structSnippet = {
            label: 'struct declaration',
            snippet: '${1:StructName} {\n\t${2:property1}: ${3:type1},\n\t${4:property2}: ${5:type2}\n}'
        };
        
        const item = new vscode.CompletionItem(structSnippet.label, vscode.CompletionItemKind.Snippet);
        item.insertText = new vscode.SnippetString(structSnippet.snippet);
        completionItems.push(item);
    }
    
    // Check if we're after a variable declaration keyword
    if (/(?:let|take|hold|put)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*$/.test(linePrefix)) {
        // Suggest common values based on the variable type
        if (linePrefix.startsWith('let')) {
            // Numeric values
            const numericValues = ['0', '1', '100', '3.14'];
            numericValues.forEach(value => {
                const item = new vscode.CompletionItem(value, vscode.CompletionItemKind.Value);
                completionItems.push(item);
            });
        } else if (linePrefix.startsWith('take')) {
            // String values
            const stringValues = ['"text"', '"hello"', '""'];
            stringValues.forEach(value => {
                const item = new vscode.CompletionItem(value, vscode.CompletionItemKind.Value);
                completionItems.push(item);
            });
        } else if (linePrefix.startsWith('hold')) {
            // Boolean values
            const boolValues = ['true', 'false'];
            boolValues.forEach(value => {
                const item = new vscode.CompletionItem(value, vscode.CompletionItemKind.Value);
                completionItems.push(item);
            });
        } else if (linePrefix.startsWith('put')) {
            // Mixed values
            const mixedValues = ['0', '"text"', 'true', 'false', '[]', '{}'];
            mixedValues.forEach(value => {
                const item = new vscode.CompletionItem(value, vscode.CompletionItemKind.Value);
                completionItems.push(item);
            });
            
            // Array and object snippets
            const complexSnippets = [
                {
                    label: 'array',
                    snippet: '[${1:item1}, ${2:item2}, ${3:item3}]'
                },
                {
                    label: 'object',
                    snippet: '{\n\t"${1:key1}": ${2:value1},\n\t"${3:key2}": ${4:value2}\n}'
                }
            ];
            
            complexSnippets.forEach(snippet => {
                const item = new vscode.CompletionItem(snippet.label, vscode.CompletionItemKind.Snippet);
                item.insertText = new vscode.SnippetString(snippet.snippet);
                completionItems.push(item);
            });
        }
    }
    
    // Add string concatenation snippets when appropriate
    if (/take\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*["'][^"']*["']\s*$/.test(linePrefix)) {
        // After a string assignment, suggest concatenation
        const concatSnippet = {
            label: 'concat with variable',
            snippet: ' + ${1:variable}'
        };
        
        const item = new vscode.CompletionItem(concatSnippet.label, vscode.CompletionItemKind.Snippet);
        item.insertText = new vscode.SnippetString(concatSnippet.snippet);
        completionItems.push(item);
    }
    
    // Add try-catch snippet after typing 'try'
    if (/try\s*$/.test(linePrefix)) {
        const tryCatchSnippet = {
            label: 'try-catch block',
            snippet: '{\n\t${1:// code that might throw an exception}\n} catch {\n\t${2:// code to handle the exception}\n}'
        };
        
        const item = new vscode.CompletionItem(tryCatchSnippet.label, vscode.CompletionItemKind.Snippet);
        item.insertText = new vscode.SnippetString(tryCatchSnippet.snippet);
        completionItems.push(item);
    }
    
    // Check if we're after 'show' keyword
    if (/\bshow\s+$/.test(linePrefix)) {
        // Add common output strings
        const outputStrings = ['"";', '"Hello, World!";', '"Result: " + result;'];
        outputStrings.forEach(str => {
            const item = new vscode.CompletionItem(str, vscode.CompletionItemKind.Snippet);
            completionItems.push(item);
        });
        
        // Add colored output snippets
        const colorSnippets = [
            { label: 'show(red)', snippet: '(red) "${1:Error message}";' },
            { label: 'show(green)', snippet: '(green) "${1:Success message}";' },
            { label: 'show(blue)', snippet: '(blue) "${1:Information}";' },
            { label: 'show(yellow)', snippet: '(yellow) "${1:Warning message}";' },
            { label: 'show(magenta)', snippet: '(magenta) "${1:Special message}";' },
            { label: 'show(cyan)', snippet: '(cyan) "${1:Highlighted information}";' },
            { label: 'show(white)', snippet: '(white) "${1:Standard message}";' },
            { label: 'show(bright_red)', snippet: '(bright_red) "${1:Critical error}";' },
            { label: 'show(bright_green)', snippet: '(bright_green) "${1:Important success}";' },
            { label: 'show(bright_blue)', snippet: '(bright_blue) "${1:Important information}";' },
            { label: 'show(bright_yellow)', snippet: '(bright_yellow) "${1:Important warning}";' },
            { label: 'show(bright_magenta)', snippet: '(bright_magenta) "${1:Important special message}";' },
            { label: 'show(bright_cyan)', snippet: '(bright_cyan) "${1:Important highlighted information}";' },
            { label: 'show(bright_white)', snippet: '(bright_white) "${1:Important standard message}";' }
        ];
        
        colorSnippets.forEach(snippet => {
            const item = new vscode.CompletionItem(snippet.label, vscode.CompletionItemKind.Snippet);
            item.insertText = new vscode.SnippetString(snippet.snippet);
            item.documentation = new vscode.MarkdownString(`Colored output using the ${snippet.label.replace('show(', '').replace(')', '')} color`);
            completionItems.push(item);
        });
    }
    
    // Check if we're after 'show(' (for color parameter)
    if (/\bshow\s*\(\s*$/.test(linePrefix)) {
        // Add color options
        const colors = [
            'red', 'green', 'blue', 'yellow', 'magenta', 'cyan', 'white',
            'bright_red', 'bright_green', 'bright_blue', 'bright_yellow', 'bright_magenta', 'bright_cyan', 'bright_white'
        ];
        
        colors.forEach(color => {
            const item = new vscode.CompletionItem(color, vscode.CompletionItemKind.Color);
            item.documentation = `Use ${color} for colored console output`;
            item.insertText = new vscode.SnippetString(`${color}) "\${1:message}";`);
            completionItems.push(item);
        });
    }
    
    return completionItems;
}

/**
 * Run a Razen file using the razen-run script
 * @param {vscode.Uri} [uri] - The URI of the file to run
 */
async function runRazenFile(uri) {
    // Get the active text editor if no URI is provided
    if (!uri) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No file is open to run');
            return;
        }
        
        // Check if the file is a Razen file
        if (path.extname(editor.document.fileName) !== '.rzn') {
            vscode.window.showErrorMessage('Not a Razen file (.rzn)');
            return;
        }
        
        // Save the file before running
        if (editor.document.isDirty) {
            await editor.document.save();
        }
        
        uri = editor.document.uri;
    }
    
    // Convert URI to file path
    const filePath = uri.fsPath;
    
    // Create or show the output channel
    const outputChannel = vscode.window.createOutputChannel('Razen Run');
    outputChannel.show(true); // Preserve focus
    
    // Find the razen-run script
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(uri);
    let razenRunScript = '';
    
    // Try to find the script in the workspace
    if (workspaceFolder) {
        const possibleScriptPaths = [
            path.join(workspaceFolder.uri.fsPath, 'scripts', 'razen-run'),
            path.join(workspaceFolder.uri.fsPath, '..', 'scripts', 'razen-run'),
            path.join(workspaceFolder.uri.fsPath, '..', '..', 'scripts', 'razen-run')
        ];
        
        for (const scriptPath of possibleScriptPaths) {
            if (fs.existsSync(scriptPath)) {
                razenRunScript = scriptPath;
                break;
            }
        }
    }
    
    // If not found in workspace, try common installation locations
    if (!razenRunScript) {
        const commonPaths = [
            '/usr/local/bin/razen-run',
            '/usr/bin/razen-run',
            path.join(process.env.HOME || process.env.USERPROFILE, '.razen', 'bin', 'razen-run')
        ];
        
        for (const scriptPath of commonPaths) {
            if (fs.existsSync(scriptPath)) {
                razenRunScript = scriptPath;
                break;
            }
        }
    }
    
    // If still not found, use the command directly (assuming it's in PATH)
    if (!razenRunScript) {
        razenRunScript = 'razen-run';
    }
    
    // Show running message
    outputChannel.appendLine(`Running: ${filePath}`);
    outputChannel.appendLine('-----------------------------------');
    
    // Execute the razen-run script with the file path
    const command = `"${razenRunScript}" "${filePath}"`;
    
    // Create a terminal to run the command
    const terminal = vscode.window.createTerminal('Razen Run');
    terminal.sendText(command);
    terminal.show();
}

/**
 * Debug a Razen file using the razen-debug script
 * @param {vscode.Uri} [uri] - The URI of the file to debug
 */
async function debugRazenFile(uri) {
    // Get the active text editor if no URI is provided
    if (!uri) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No file is open to debug');
            return;
        }
        
        // Check if the file is a Razen file
        if (path.extname(editor.document.fileName) !== '.rzn') {
            vscode.window.showErrorMessage('Not a Razen file (.rzn)');
            return;
        }
        
        // Save the file before debugging
        if (editor.document.isDirty) {
            await editor.document.save();
        }
        
        uri = editor.document.uri;
    }
    
    // Convert URI to file path
    const filePath = uri.fsPath;
    
    // Create or show the output channel
    const outputChannel = vscode.window.createOutputChannel('Razen Debug');
    outputChannel.show(true); // Preserve focus
    
    // Find the razen-debug script
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(uri);
    let razenDebugScript = '';
    
    // Try to find the script in the workspace
    if (workspaceFolder) {
        const possibleScriptPaths = [
            path.join(workspaceFolder.uri.fsPath, 'scripts', 'razen-debug'),
            path.join(workspaceFolder.uri.fsPath, '..', 'scripts', 'razen-debug'),
            path.join(workspaceFolder.uri.fsPath, '..', '..', 'scripts', 'razen-debug')
        ];
        
        for (const scriptPath of possibleScriptPaths) {
            if (fs.existsSync(scriptPath)) {
                razenDebugScript = scriptPath;
                break;
            }
        }
    }
    
    // If not found in workspace, try common installation locations
    if (!razenDebugScript) {
        const commonPaths = [
            '/usr/local/bin/razen-debug',
            '/usr/bin/razen-debug',
            path.join(process.env.HOME || process.env.USERPROFILE, '.razen', 'bin', 'razen-debug')
        ];
        
        for (const scriptPath of commonPaths) {
            if (fs.existsSync(scriptPath)) {
                razenDebugScript = scriptPath;
                break;
            }
        }
    }
    
    // If still not found, use the command directly (assuming it's in PATH)
    if (!razenDebugScript) {
        razenDebugScript = 'razen-debug';
    }
    
    // Show debugging message
    outputChannel.appendLine(`Debugging: ${filePath}`);
    outputChannel.appendLine('-----------------------------------');
    
    // Execute the razen-debug script with the file path
    const command = `"${razenDebugScript}" "${filePath}"`;
    
    // Create a terminal to run the command
    const terminal = vscode.window.createTerminal('Razen Debug');
    terminal.sendText(command);
    terminal.show();
}

/**
 * Run tests for a Razen file or directory using the razen-test script
 * @param {vscode.Uri} [uri] - The URI of the file or directory to test
 */
async function testRazenFile(uri) {
    // Get the active text editor if no URI is provided
    if (!uri) {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            // If no editor is active, try to run tests for the entire workspace
            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders || workspaceFolders.length === 0) {
                vscode.window.showErrorMessage('No file or workspace is open to test');
                return;
            }
            
            uri = workspaceFolders[0].uri;
        } else {
            // Check if the file is a Razen file
            if (path.extname(editor.document.fileName) !== '.rzn') {
                vscode.window.showErrorMessage('Not a Razen file (.rzn)');
                return;
            }
            
            // Save the file before testing
            if (editor.document.isDirty) {
                await editor.document.save();
            }
            
            uri = editor.document.uri;
        }
    }
    
    // Convert URI to file path
    const filePath = uri.fsPath;
    
    // Create or show the output channel
    const outputChannel = vscode.window.createOutputChannel('Razen Test');
    outputChannel.show(true); // Preserve focus
    
    // Find the razen-test script
    const workspaceFolder = vscode.workspace.getWorkspaceFolder(uri);
    let razenTestScript = '';
    
    // Try to find the script in the workspace
    if (workspaceFolder) {
        const possibleScriptPaths = [
            path.join(workspaceFolder.uri.fsPath, 'scripts', 'razen-test'),
            path.join(workspaceFolder.uri.fsPath, '..', 'scripts', 'razen-test'),
            path.join(workspaceFolder.uri.fsPath, '..', '..', 'scripts', 'razen-test')
        ];
        
        for (const scriptPath of possibleScriptPaths) {
            if (fs.existsSync(scriptPath)) {
                razenTestScript = scriptPath;
                break;
            }
        }
    }
    
    // If not found in workspace, try common installation locations
    if (!razenTestScript) {
        const commonPaths = [
            '/usr/local/bin/razen-test',
            '/usr/bin/razen-test',
            path.join(process.env.HOME || process.env.USERPROFILE, '.razen', 'bin', 'razen-test')
        ];
        
        for (const scriptPath of commonPaths) {
            if (fs.existsSync(scriptPath)) {
                razenTestScript = scriptPath;
                break;
            }
        }
    }
    
    // If still not found, use the command directly (assuming it's in PATH)
    if (!razenTestScript) {
        razenTestScript = 'razen-test';
    }
    
    // Show testing message
    const isDirectory = fs.lstatSync(filePath).isDirectory();
    if (isDirectory) {
        outputChannel.appendLine(`Running tests in directory: ${filePath}`);
    } else {
        outputChannel.appendLine(`Running tests for file: ${filePath}`);
    }
    outputChannel.appendLine('-----------------------------------');
    
    // Execute the razen-test script with the file or directory path
    const command = `"${razenTestScript}" "${filePath}"`;
    
    // Create a terminal to run the command
    const terminal = vscode.window.createTerminal('Razen Test');
    terminal.sendText(command);
    terminal.show();
}

function deactivate() {
    // Deactivate the language server
    return deactivateLanguageServer();
}

module.exports = {
    activate,
    deactivate
};
