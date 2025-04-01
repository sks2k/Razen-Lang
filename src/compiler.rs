use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::process::Command;

use crate::ast::{Program, Statement, Expression};
use crate::parser::Parser;

// Intermediate representation for code generation
#[derive(Debug, Clone)]
enum IR {
    // Stack operations
    PushNumber(f64),
    PushString(String),
    PushBoolean(bool),
    PushNull,
    Pop,
    Dup,
    Swap,
    
    // Memory operations
    StoreVar(String),
    LoadVar(String),
    
    // Arithmetic operations
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,
    Power,
    FloorDiv,
    Negate,
    
    // Comparison operations
    Equal,
    NotEqual,
    GreaterThan,
    GreaterEqual,
    LessThan,
    LessEqual,
    
    // Logical operations
    And,
    Or,
    Not,
    
    // Control flow
    Jump(usize),
    JumpIfFalse(usize),
    JumpIfTrue(usize),
    Call(String, usize),  // function name, arg count
    Return,
    
    // I/O operations
    Print,
    ReadInput,
    Exit,
    
    // Array operations
    CreateArray(usize),
    GetIndex,
    SetIndex,
    
    // Map operations
    CreateMap(usize),
    GetKey,
    SetKey,
    
    // Function definition
    DefineFunction(String, usize),  // function name, address
    
    // Labels for jumps
    Label(String),
}

// Symbol table for variable and function tracking
#[derive(Debug, Clone)]
struct SymbolTable {
    symbols: HashMap<String, usize>,
    parent: Option<Box<SymbolTable>>,
    next_index: usize,
}

impl SymbolTable {
    fn new() -> Self {
        SymbolTable {
            symbols: HashMap::new(),
            parent: None,
            next_index: 0,
        }
    }
    
    fn new_enclosed(parent: SymbolTable) -> Self {
        SymbolTable {
            symbols: HashMap::new(),
            parent: Some(Box::new(parent)),
            next_index: 0,
        }
    }
    
    fn define(&mut self, name: &str) -> usize {
        let index = self.next_index;
        self.symbols.insert(name.to_string(), index);
        self.next_index += 1;
        index
    }
    
    fn resolve(&self, name: &str) -> Option<usize> {
        match self.symbols.get(name) {
            Some(index) => Some(*index),
            None => {
                if let Some(parent) = &self.parent {
                    parent.resolve(name)
                } else {
                    None
                }
            }
        }
    }
}

// Function table for tracking function definitions
#[derive(Debug, Clone)]
struct FunctionTable {
    functions: HashMap<String, usize>,  // function name -> address in IR
}

impl FunctionTable {
    fn new() -> Self {
        FunctionTable {
            functions: HashMap::new(),
        }
    }
    
    fn define(&mut self, name: &str, address: usize) {
        self.functions.insert(name.to_string(), address);
    }
    
    fn resolve(&self, name: &str) -> Option<usize> {
        self.functions.get(name).copied()
    }
}

// Compiler for translating AST to machine code
pub struct Compiler {
    ir: Vec<IR>,
    symbol_table: SymbolTable,
    function_table: FunctionTable,
    current_function: Option<String>,
    break_stack: Vec<Vec<usize>>,    // Stack of break statement positions for nested loops
    continue_stack: Vec<Vec<usize>>, // Stack of continue statement positions for nested loops
    label_counter: usize,            // Counter for generating unique labels
    clean_output: bool,              // Flag to only show program output
}

impl Compiler {
    pub fn new() -> Self {
        Compiler {
            ir: Vec::new(),
            symbol_table: SymbolTable::new(),
            function_table: FunctionTable::new(),
            current_function: None,
            break_stack: Vec::new(),
            continue_stack: Vec::new(),
            label_counter: 0,
            clean_output: false,
        }
    }
    
    // Set clean output mode
    pub fn set_clean_output(&mut self, clean: bool) {
        self.clean_output = clean;
    }
    
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, String> {
        match Parser::from_file(path) {
            Ok(mut parser) => {
                let program = parser.parse_program();
                if !parser.get_errors().is_empty() {
                    return Err(format!("Parser errors: {:?}", parser.get_errors()));
                }
                
                let mut compiler = Compiler::new();
                
                // Check for clean output flag in environment
                if std::env::args().any(|arg| arg == "--clean-output") {
                    compiler.set_clean_output(true);
                }
                
                compiler.compile_program(program);
                Ok(compiler)
            },
            Err(e) => Err(e),
        }
    }
    
    fn generate_label(&mut self, prefix: &str) -> String {
        let label = format!("{}{}", prefix, self.label_counter);
        self.label_counter += 1;
        label
    }
    
    fn emit(&mut self, code: IR) -> usize {
        let pos = self.ir.len();
        self.ir.push(code);
        pos
    }
    
    fn emit_label(&mut self, label: &str) -> usize {
        self.emit(IR::Label(label.to_string()))
    }
    
    fn replace_instruction(&mut self, pos: usize, code: IR) {
        self.ir[pos] = code;
    }
    
    fn enter_scope(&mut self) {
        let new_table = SymbolTable::new_enclosed(self.symbol_table.clone());
        self.symbol_table = new_table;
    }
    
    fn leave_scope(&mut self) {
        if let Some(parent) = self.symbol_table.parent.take() {
            self.symbol_table = *parent;
        }
    }
    
    fn enter_loop(&mut self) {
        self.break_stack.push(Vec::new());
        self.continue_stack.push(Vec::new());
    }
    
    fn leave_loop(&mut self, loop_start: usize, loop_end: usize) {
        // Patch all break statements
        if let Some(breaks) = self.break_stack.pop() {
            for pos in breaks {
                self.replace_instruction(pos, IR::Jump(loop_end));
            }
        }
        
        // Patch all continue statements
        if let Some(continues) = self.continue_stack.pop() {
            for pos in continues {
                self.replace_instruction(pos, IR::Jump(loop_start));
            }
        }
    }
    
    fn define_builtins(&mut self) {
        // Define built-in functions like print, math operations, etc.
        self.symbol_table.define("print");
        self.symbol_table.define("read");
        self.symbol_table.define("len");
        self.symbol_table.define("append");
        self.symbol_table.define("remove");
    }
    
    pub fn compile_program(&mut self, program: Program) {
        // Define built-in functions
        self.define_builtins();
        
        // First pass: register all functions
        for stmt in &program.statements {
            if let Statement::FunctionDeclaration { name, .. } = stmt {
                self.symbol_table.define(name);
            }
        }
        
        // Second pass: compile all statements
        for stmt in program.statements {
            self.compile_statement(stmt);
        }
    }
    
    fn compile_statement(&mut self, stmt: Statement) {
        match stmt {
            Statement::VariableDeclaration { var_type, name, value } => {
                self.compile_variable_declaration(var_type, name, value);
            },
            Statement::FunctionDeclaration { name, parameters, body } => {
                self.compile_function_declaration(name, parameters, body);
            },
            Statement::ReturnStatement { value } => {
                self.compile_return_statement(value);
            },
            Statement::ExpressionStatement { expression } => {
                self.compile_expression(expression);
                // Discard the result of the expression
                self.emit(IR::Pop);
            },
            Statement::BlockStatement { statements } => {
                self.compile_block_statement(statements);
            },
            Statement::IfStatement { condition, consequence, alternative } => {
                self.compile_if_statement(condition, consequence, alternative);
            },
            Statement::WhileStatement { condition, body } => {
                self.compile_while_statement(condition, body);
            },
            Statement::ForStatement { iterator, iterable, body } => {
                self.compile_for_statement(iterator, iterable, body);
            },
            Statement::BreakStatement => {
                self.compile_break_statement();
            },
            Statement::ContinueStatement => {
                self.compile_continue_statement();
            },
            Statement::ShowStatement { value } => {
                self.compile_show_statement(value);
            },
            Statement::TryStatement { try_block, catch_block, finally_block } => {
                self.compile_try_statement(try_block, catch_block, finally_block);
            },
            Statement::ThrowStatement { value } => {
                self.compile_throw_statement(value);
            },
            Statement::ReadStatement { name } => {
                self.compile_read_statement(name);
            },
            Statement::ExitStatement => {
                self.compile_exit_statement();
            },
        }
    }
    
    fn compile_variable_declaration(&mut self, _var_type: String, name: String, value: Option<Expression>) {
        // Define the variable in the symbol table
        self.symbol_table.define(&name);
        
        // Compile the initializer expression if it exists
        if let Some(expr) = value {
            self.compile_expression(expr);
        } else {
            // If no initializer, push null as the default value
            self.emit(IR::PushNull);
        }
        
        // Store the value in the variable
        self.emit(IR::StoreVar(name));
    }
    
    fn compile_function_declaration(&mut self, name: String, parameters: Vec<String>, body: Vec<Statement>) {
        // Save the current function name
        let old_function = self.current_function.clone();
        self.current_function = Some(name.clone());
        
        // Generate a unique label for the function
        let function_label = self.generate_label("function_");
        let end_label = self.generate_label("end_");
        
        // Emit a jump to skip over the function body
        let jump_pos = self.emit(IR::Jump(0));
        
        // Mark the start of the function
        let function_start = self.emit_label(&function_label);
        
        // Register the function in the function table
        self.function_table.define(&name, function_start);
        
        // Create a new scope for the function body
        self.enter_scope();
        
        // Define parameters in the function's scope
        for param in parameters {
            self.symbol_table.define(&param);
        }
        
        // Compile the function body
        for stmt in body {
            self.compile_statement(stmt);
        }
        
        // Ensure the function returns (even if there's no explicit return)
        self.emit(IR::PushNull);
        self.emit(IR::Return);
        
        // Mark the end of the function
        let function_end = self.emit_label(&end_label);
        
        // Update the jump instruction to skip over the function body
        self.replace_instruction(jump_pos, IR::Jump(function_end));
        
        // Leave the function's scope
        self.leave_scope();
        
        // Restore the previous function name
        self.current_function = old_function;
    }
    
    fn compile_return_statement(&mut self, value: Option<Expression>) {
        // Compile the return value if it exists
        if let Some(expr) = value {
            self.compile_expression(expr);
        } else {
            // If no return value, push null
            self.emit(IR::PushNull);
        }
        
        // Emit the return instruction
        self.emit(IR::Return);
    }
    
    fn compile_block_statement(&mut self, statements: Vec<Statement>) {
        // Create a new scope for the block
        self.enter_scope();
        
        // Compile each statement in the block
        for stmt in statements {
            self.compile_statement(stmt);
        }
        
        // Leave the block's scope
        self.leave_scope();
    }
    
    fn compile_if_statement(&mut self, condition: Expression, consequence: Vec<Statement>, alternative: Option<Vec<Statement>>) {
        // Generate labels for the if statement
        let else_label = self.generate_label("else_");
        let end_label = self.generate_label("end_");
        
        // Compile the condition
        self.compile_expression(condition);
        
        // Emit a conditional jump to the else branch
        self.emit(IR::JumpIfFalse(0)); // Placeholder for else_label
        let jump_to_else_pos = self.ir.len() - 1;
        
        // Compile the consequence (if branch)
        for stmt in consequence {
            self.compile_statement(stmt);
        }
        
        // Emit a jump to the end of the if statement
        self.emit(IR::Jump(0)); // Placeholder for end_label
        let jump_to_end_pos = self.ir.len() - 1;
        
        // Mark the start of the else branch
        let else_pos = self.emit_label(&else_label);
        
        // Update the jump to else instruction
        self.replace_instruction(jump_to_else_pos, IR::JumpIfFalse(else_pos));
        
        // Compile the alternative (else branch) if it exists
        if let Some(alt) = alternative {
            for stmt in alt {
                self.compile_statement(stmt);
            }
        }
        
        // Mark the end of the if statement
        let end_pos = self.emit_label(&end_label);
        
        // Update the jump to end instruction
        self.replace_instruction(jump_to_end_pos, IR::Jump(end_pos));
    }
    
    fn compile_while_statement(&mut self, condition: Expression, body: Vec<Statement>) {
        // Generate labels for the while loop
        let loop_label = self.generate_label("loop_");
        let end_label = self.generate_label("end_");
        
        // Mark the start of the loop
        let loop_start = self.emit_label(&loop_label);
        
        // Enter the loop context for break/continue statements
        self.enter_loop();
        
        // Compile the condition
        self.compile_expression(condition);
        
        // Emit a conditional jump to the end of the loop
        self.emit(IR::JumpIfFalse(0)); // Placeholder for end_label
        let jump_to_end_pos = self.ir.len() - 1;
        
        // Compile the loop body
        for stmt in body {
            self.compile_statement(stmt);
        }
        
        // Emit a jump back to the start of the loop
        self.emit(IR::Jump(loop_start));
        
        // Mark the end of the loop
        let end_pos = self.emit_label(&end_label);
        
        // Update the jump to end instruction
        self.replace_instruction(jump_to_end_pos, IR::JumpIfFalse(end_pos));
        
        // Leave the loop context and patch break/continue statements
        self.leave_loop(loop_start, end_pos);
    }
    
    fn compile_for_statement(&mut self, iterator: String, iterable: Expression, body: Vec<Statement>) {
        // Generate labels for the for loop
        let loop_label = self.generate_label("for_loop_");
        let end_label = self.generate_label("for_end_");
        
        // Create a new scope for the loop
        self.enter_scope();
        
        // Define the iterator variable
        self.symbol_table.define(&iterator);
        
        // Compile the iterable expression
        self.compile_expression(iterable);
        
        // Create a temporary index variable
        let index_var = format!("__index_{}", self.generate_label(""));
        self.symbol_table.define(&index_var);
        
        // Initialize the index to 0
        self.emit(IR::PushNumber(0.0));
        self.emit(IR::StoreVar(index_var.clone()));
        
        // Mark the start of the loop
        let loop_start = self.emit_label(&loop_label);
        
        // Enter the loop context for break/continue statements
        self.enter_loop();
        
        // Check if the index is less than the length of the iterable
        self.emit(IR::LoadVar(index_var.clone()));
        self.emit(IR::Dup); // Duplicate the index for the array access
        self.emit(IR::GetIndex); // Get the element at the current index
        
        // Store the current element in the iterator variable
        self.emit(IR::StoreVar(iterator));
        
        // Increment the index
        self.emit(IR::LoadVar(index_var.clone()));
        self.emit(IR::PushNumber(1.0));
        self.emit(IR::Add);
        self.emit(IR::StoreVar(index_var.clone()));
        
        // Compile the loop body
        for stmt in body {
            self.compile_statement(stmt);
        }
        
        // Emit a jump back to the start of the loop
        self.emit(IR::Jump(loop_start));
        
        // Mark the end of the loop
        let end_pos = self.emit_label(&end_label);
        
        // Leave the loop context and patch break/continue statements
        self.leave_loop(loop_start, end_pos);
        
        // Leave the loop's scope
        self.leave_scope();
    }
    
    fn compile_break_statement(&mut self) {
        // Check if we're inside a loop
        if self.break_stack.is_empty() {
            panic!("Break statement outside of loop");
        }
        
        // Emit a jump to the end of the loop (will be patched later)
        let break_pos = self.emit(IR::Jump(0)); // Placeholder
        
        // Add the break position to the current loop's break stack
        if let Some(breaks) = self.break_stack.last_mut() {
            breaks.push(break_pos);
        }
    }
    
    fn compile_continue_statement(&mut self) {
        // Check if we're inside a loop
        if self.continue_stack.is_empty() {
            panic!("Continue statement outside of loop");
        }
        
        // Emit a jump to the start of the loop (will be patched later)
        let continue_pos = self.emit(IR::Jump(0)); // Placeholder
        
        // Add the continue position to the current loop's continue stack
        if let Some(continues) = self.continue_stack.last_mut() {
            continues.push(continue_pos);
        }
    }
    
    fn compile_show_statement(&mut self, value: Expression) {
        // Compile the value to be shown
        self.compile_expression(value);
        
        // Emit the print instruction
        self.emit(IR::Print);
    }
    
    fn compile_try_statement(&mut self, try_block: Vec<Statement>, catch_block: Option<Vec<Statement>>, finally_block: Option<Vec<Statement>>) {
        // This is a simplified implementation of try/catch/finally
        // In a real implementation, this would involve exception handling
        
        // Compile the try block
        for stmt in try_block {
            self.compile_statement(stmt);
        }
        
        // Compile the catch block if it exists
        if let Some(catch) = catch_block {
            for stmt in catch {
                self.compile_statement(stmt);
            }
        }
        
        // Compile the finally block if it exists
        if let Some(finally) = finally_block {
            for stmt in finally {
                self.compile_statement(stmt);
            }
        }
    }
    
    fn compile_throw_statement(&mut self, value: Expression) {
        // Compile the value to be thrown
        self.compile_expression(value);
        
        // In a real implementation, this would involve exception handling
        // For now, we'll just print the error and exit
        self.emit(IR::Print);
    }
    
    fn compile_read_statement(&mut self, name: String) {
        // Define the variable in the symbol table
        self.symbol_table.define(&name);
        
        // Add a custom IR operation for reading user input
        self.emit(IR::ReadInput);
        self.emit(IR::StoreVar(name));
    }
    
    fn compile_exit_statement(&mut self) {
        // Emit the exit instruction to terminate the program
        self.emit(IR::Exit);
    }
    
    fn compile_expression(&mut self, expr: Expression) {
        match expr {
            Expression::Identifier(name) => {
                self.emit(IR::LoadVar(name));
            },
            Expression::StringLiteral(value) => {
                self.emit(IR::PushString(value));
            },
            Expression::NumberLiteral(value) => {
                self.emit(IR::PushNumber(value));
            },
            Expression::BooleanLiteral(value) => {
                self.emit(IR::PushBoolean(value));
            },
            Expression::NullLiteral => {
                self.emit(IR::PushNull);
            },
            Expression::PrefixExpression { operator, right } => {
                self.compile_prefix_expression(operator, *right);
            },
            Expression::InfixExpression { left, operator, right } => {
                self.compile_infix_expression(*left, operator, *right);
            },
            Expression::AssignmentExpression { left, operator, right } => {
                self.compile_assignment_expression(*left, operator, *right);
            },
            Expression::CallExpression { function, arguments } => {
                self.compile_call_expression(*function, arguments);
            },
            Expression::ArrayLiteral { elements } => {
                self.compile_array_literal(elements);
            },
            Expression::IndexExpression { left, index } => {
                self.compile_index_expression(*left, *index);
            },
            Expression::MapLiteral { pairs } => {
                self.compile_map_literal(pairs);
            },
        }
    }
    
    fn compile_prefix_expression(&mut self, operator: String, right: Expression) {
        // Compile the right operand
        self.compile_expression(right);
        
        // Apply the prefix operator
        match operator.as_str() {
            "-" => { self.emit(IR::Negate); },
            "!" => { self.emit(IR::Not); },
            _ => panic!("Unknown prefix operator: {}", operator),
        }
    }
    
    fn compile_infix_expression(&mut self, left: Expression, operator: String, right: Expression) {
        // Compile the left operand
        self.compile_expression(left);
        
        // Compile the right operand
        self.compile_expression(right);
        
        // Apply the infix operator
        match operator.as_str() {
            "+" => { self.emit(IR::Add); },
            "-" => { self.emit(IR::Subtract); },
            "*" => { self.emit(IR::Multiply); },
            "/" => { self.emit(IR::Divide); },
            "%" => { self.emit(IR::Modulo); },
            "**" => { self.emit(IR::Power); },
            "//" => { self.emit(IR::FloorDiv); },
            "==" => { self.emit(IR::Equal); },
            "!=" => { self.emit(IR::NotEqual); },
            ">" => { self.emit(IR::GreaterThan); },
            ">=" => { self.emit(IR::GreaterEqual); },
            "<" => { self.emit(IR::LessThan); },
            "<=" => { self.emit(IR::LessEqual); },
            "&&" => { self.emit(IR::And); },
            "||" => { self.emit(IR::Or); },
            _ => panic!("Unknown infix operator: {}", operator),
        }
    }
    
    fn compile_assignment_expression(&mut self, left: Expression, operator: String, right: Expression) {
        // For simple assignment (=), just compile the right expression and store it
        if operator == "=" {
            // Compile the right expression
            self.compile_expression(right);
            
            // Store the result in the variable
            if let Expression::Identifier(name) = left {
                self.emit(IR::StoreVar(name));
            } else if let Expression::IndexExpression { left: array, index } = left {
                // Compile the array and index
                self.compile_expression(*array);
                self.compile_expression(*index);
                
                // Store the value in the array at the given index
                self.emit(IR::SetIndex);
            } else {
                panic!("Invalid left-hand side in assignment");
            }
        } else {
            // For compound assignments (+=, -=, etc.), load the variable, apply the operation, and store it back
            if let Expression::Identifier(name) = left.clone() {
                // Load the current value
                self.emit(IR::LoadVar(name.clone()));
                
                // Compile the right expression
                self.compile_expression(right);
                
                // Apply the operation
                match operator.as_str() {
                    "+=" => { self.emit(IR::Add); },
                    "-=" => { self.emit(IR::Subtract); },
                    "*=" => { self.emit(IR::Multiply); },
                    "/=" => { self.emit(IR::Divide); },
                    "%=" => { self.emit(IR::Modulo); },
                    _ => panic!("Unknown assignment operator: {}", operator),
                }
                
                // Store the result back in the variable
                self.emit(IR::StoreVar(name));
            } else {
                panic!("Invalid left-hand side in compound assignment");
            }
        }
    }
    
    fn compile_call_expression(&mut self, function: Expression, arguments: Vec<Expression>) {
        // Compile each argument
        for arg in &arguments {
            self.compile_expression(arg.clone());
        }
        
        // Get the function name
        if let Expression::Identifier(name) = function {
            // Call the function with the given number of arguments
            self.emit(IR::Call(name, arguments.len()));
        } else {
            panic!("Function call on non-identifier");
        }
    }
    
    fn compile_array_literal(&mut self, elements: Vec<Expression>) {
        // Compile each element
        for elem in &elements {
            self.compile_expression(elem.clone());
        }
        
        // Create the array with the given number of elements
        self.emit(IR::CreateArray(elements.len()));
    }
    
    fn compile_index_expression(&mut self, left: Expression, index: Expression) {
        // Compile the array
        self.compile_expression(left);
        
        // Compile the index
        self.compile_expression(index);
        
        // Get the element at the given index
        self.emit(IR::GetIndex);
    }
    
    fn compile_map_literal(&mut self, pairs: Vec<(Expression, Expression)>) {
        // Compile each key-value pair
        for (key, value) in &pairs {
            self.compile_expression(key.clone());
            self.compile_expression(value.clone());
        }
        
        // Create the map with the given number of key-value pairs
        self.emit(IR::CreateMap(pairs.len()));
    }
    
    // Generate machine code from the IR
    pub fn generate_machine_code(&self) -> Result<Vec<u8>, String> {
        // This is a simplified implementation that would be replaced with actual machine code generation
        // In a real implementation, this would translate the IR to native machine code
        
        // For now, we'll just return a placeholder binary
        let mut code = Vec::new();
        
        // Add a simple header
        code.extend_from_slice(b"\x7FELF"); // ELF magic number
        
        // Add placeholder code for each IR instruction
        for ir in &self.ir {
            match ir {
                IR::PushNumber(_) => code.push(0x01),
                IR::PushString(_) => code.push(0x02),
                IR::PushBoolean(_) => code.push(0x03),
                IR::PushNull => code.push(0x04),
                IR::Pop => code.push(0x05),
                IR::Dup => code.push(0x06),
                IR::Swap => code.push(0x07),
                IR::StoreVar(_) => code.push(0x08),
                IR::LoadVar(_) => code.push(0x09),
                IR::Add => code.push(0x0A),
                IR::Subtract => code.push(0x0B),
                IR::Multiply => code.push(0x0C),
                IR::Divide => code.push(0x0D),
                IR::Modulo => code.push(0x0E),
                IR::Power => code.push(0x0F),
                IR::FloorDiv => code.push(0x10),
                IR::Negate => code.push(0x11),
                IR::Equal => code.push(0x12),
                IR::NotEqual => code.push(0x13),
                IR::GreaterThan => code.push(0x14),
                IR::GreaterEqual => code.push(0x15),
                IR::LessThan => code.push(0x16),
                IR::LessEqual => code.push(0x17),
                IR::And => code.push(0x18),
                IR::Or => code.push(0x19),
                IR::Not => code.push(0x1A),
                IR::Jump(_) => code.push(0x1B),
                IR::JumpIfFalse(_) => code.push(0x1C),
                IR::JumpIfTrue(_) => code.push(0x1D),
                IR::Call(_, _) => code.push(0x1E),
                IR::Return => code.push(0x1F),
                IR::Print => code.push(0x20),
                IR::ReadInput => code.push(0x29),
                IR::Exit => code.push(0x2A),
                IR::CreateArray(_) => code.push(0x21),
                IR::GetIndex => code.push(0x22),
                IR::SetIndex => code.push(0x23),
                IR::CreateMap(_) => code.push(0x24),
                IR::GetKey => code.push(0x25),
                IR::SetKey => code.push(0x26),
                IR::DefineFunction(_, _) => code.push(0x27),
                IR::Label(_) => code.push(0x28),
            }
        }
        
        Ok(code)
    }
    
    // Write the generated machine code to a file
    pub fn write_to_file<P: AsRef<Path>>(&self, path: P) -> Result<(), String> {
        match self.generate_machine_code() {
            Ok(code) => {
                match fs::write(path, code) {
                    Ok(_) => Ok(()),
                    Err(e) => Err(format!("Failed to write to file: {}", e)),
                }
            },
            Err(e) => Err(e),
        }
    }
    
    // Execute the compiled code directly
    pub fn execute(&self) -> Result<(), String> {
        // In a real implementation, this would execute the generated machine code
        // For now, we'll just interpret the IR directly
        
        // Only show debug output if not in clean output mode
        if !self.clean_output {
            println!("Executing Razen program...");
            
            // Print the IR for debugging
            for (i, ir) in self.ir.iter().enumerate() {
                println!("{}: {:?}", i, ir);
            }
        }
        
        // Simple stack-based interpreter for the IR
        let mut stack: Vec<String> = Vec::new();
        let mut variables: HashMap<String, String> = HashMap::new();
        
        // Execute each instruction
        let mut pc = 0; // Program counter
        while pc < self.ir.len() {
            let ir = &self.ir[pc];
            match ir {
                IR::PushNumber(n) => stack.push(n.to_string()),
                IR::PushString(s) => stack.push(s.clone()),
                IR::PushBoolean(b) => stack.push(b.to_string()),
                IR::Add => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        // Try to add as numbers first
                        if let (Ok(a_num), Ok(b_num)) = (a.parse::<f64>(), b.parse::<f64>()) {
                            stack.push((a_num + b_num).to_string());
                        } else {
                            // Otherwise concatenate as strings
                            stack.push(format!("{}{}", a, b));
                        }
                    }
                },
                IR::Subtract => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        if let (Ok(a_num), Ok(b_num)) = (a.parse::<f64>(), b.parse::<f64>()) {
                            stack.push((a_num - b_num).to_string());
                        }
                    }
                },
                IR::Multiply => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        if let (Ok(a_num), Ok(b_num)) = (a.parse::<f64>(), b.parse::<f64>()) {
                            stack.push((a_num * b_num).to_string());
                        }
                    }
                },
                IR::Divide => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        if let (Ok(a_num), Ok(b_num)) = (a.parse::<f64>(), b.parse::<f64>()) {
                            if b_num != 0.0 {
                                stack.push((a_num / b_num).to_string());
                            } else {
                                return Err("Division by zero".to_string());
                            }
                        }
                    }
                },
                IR::Equal => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        // Compare as strings
                        let result = a == b;
                        stack.push(result.to_string());
                    }
                },
                IR::NotEqual => {
                    if let (Some(b), Some(a)) = (stack.pop(), stack.pop()) {
                        // Compare as strings
                        let result = a != b;
                        stack.push(result.to_string());
                    }
                },
                IR::StoreVar(name) => {
                    if let Some(value) = stack.pop() {
                        variables.insert(name.clone(), value);
                    }
                },
                IR::LoadVar(name) => {
                    if let Some(value) = variables.get(name) {
                        stack.push(value.clone());
                    } else {
                        stack.push("undefined".to_string());
                    }
                },
                IR::Print => {
                    if let Some(value) = stack.pop() {
                        println!("{}", value);
                    }
                },
                IR::ReadInput => {
                    use std::io::{self, BufRead};
                    let stdin = io::stdin();
                    let mut line = String::new();
                    stdin.lock().read_line(&mut line).expect("Failed to read line");
                    // Remove trailing newline
                    if line.ends_with('\n') {
                        line.pop();
                        if line.ends_with('\r') {
                            line.pop();
                        }
                    }
                    stack.push(line);
                },
                IR::Exit => {
                    if !self.clean_output {
                        println!("Program terminated with exit statement");
                    }
                    return Ok(());
                },
                IR::Jump(target) => {
                    pc = *target;
                    continue;
                },
                IR::JumpIfFalse(target) => {
                    if let Some(value) = stack.pop() {
                        if value == "false" || value == "0" || value.is_empty() || value == "False" {
                            pc = *target;
                            continue;
                        }
                    }
                },
                // Add basic implementations for other instructions as needed
                _ => {
                    // For instructions not yet implemented, just log if in debug mode
                    if !self.clean_output {
                        println!("Unimplemented instruction: {:?}", ir);
                    }
                }
            }
            pc += 1; // Move to next instruction
        }
        
        if !self.clean_output {
            println!("Execution complete.");
        }
        
        Ok(())
    }
}