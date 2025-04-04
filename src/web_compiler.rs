use crate::compiler::{Compiler, IR};
use crate::web_parser::{WebParser, WebExpression};
use crate::parser::Expression;
use std::collections::HashMap;

/// WebCompiler extends the standard Razen compiler with web-specific functionality
pub struct WebCompiler {
    compiler: Compiler,
    element_selectors: HashMap<String, String>, // Maps element IDs to their selectors
    event_listeners: HashMap<String, Vec<String>>, // Maps elements to their event listeners
}

impl WebCompiler {
    pub fn new(compiler: Compiler) -> Self {
        WebCompiler {
            compiler,
            element_selectors: HashMap::new(),
            event_listeners: HashMap::new(),
        }
    }

    /// Compile a web expression into IR instructions
    pub fn compile_web_expression(&mut self, expression: WebExpression) -> Vec<IR> {
        match expression {
            WebExpression::ElementSelector(id) => self.compile_element_selector(&id),
            WebExpression::DomManipulation(op_type, content) => self.compile_dom_manipulation(op_type, content),
            WebExpression::ClassManipulation(operation, class_name) => self.compile_class_manipulation(operation, class_name),
            WebExpression::EventListener(event_type, block) => self.compile_event_listener(event_type, block),
            WebExpression::FormSelector(form_id, block) => self.compile_form_selector(form_id, block),
            WebExpression::FetchRequest(url, options) => self.compile_fetch_request(url, options),
            WebExpression::StorageOperation(storage_type, key, value) => self.compile_storage_operation(storage_type, key, value),
            WebExpression::TimerOperation(milliseconds, block) => self.compile_timer_operation(milliseconds, block),
        }
    }

    /// Compile element selector expressions (get, query, all)
    fn compile_element_selector(&mut self, id: &str) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Generate code to get element by ID
        instructions.push(IR::PushString(id.to_string()));
        instructions.push(IR::GetElementById);
        
        // Store the element in a variable for later use
        instructions.push(IR::StoreVar(format!("__element_{}", id)));
        
        // Store the element ID in our map for reference
        self.element_selectors.insert(id.to_string(), format!("#{}",id));
        
        instructions
    }

    /// Compile DOM manipulation expressions (html, text, attr, style)
    fn compile_dom_manipulation(&mut self, op_type: String, content: Expression) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Compile the content expression
        instructions.extend(self.compiler.compile_expression(content));
        
        // Generate the appropriate DOM manipulation instruction
        match op_type.as_str() {
            "html" => instructions.push(IR::SetInnerHTML),
            "text" => instructions.push(IR::SetTextContent),
            "attr" => instructions.push(IR::SetAttribute),
            "style" => instructions.push(IR::SetStyle),
            _ => instructions.push(IR::Noop), // Should not happen
        }
        
        instructions
    }

    /// Compile class manipulation (add, remove, toggle, contains)
    fn compile_class_manipulation(&mut self, operation: String, class_name: String) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Push the class name
        instructions.push(IR::PushString(class_name));
        
        // Generate the appropriate class manipulation instruction
        match operation.as_str() {
            "add" => instructions.push(IR::AddClass),
            "remove" => instructions.push(IR::RemoveClass),
            "toggle" => instructions.push(IR::ToggleClass),
            "contains" => instructions.push(IR::ContainsClass),
            _ => instructions.push(IR::Noop), // Should not happen
        }
        
        instructions
    }

    /// Compile event listener (on click { ... })
    fn compile_event_listener(&mut self, event_type: String, block: Vec<crate::parser::Statement>) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Push the event type
        instructions.push(IR::PushString(event_type.clone()));
        
        // Compile the event handler block
        let block_instructions = self.compiler.compile_block(block);
        
        // Create a function for the event handler
        let function_name = format!("__event_handler_{}_{}", event_type, self.compiler.get_unique_id());
        instructions.push(IR::DefineFunction(function_name.clone(), block_instructions));
        
        // Add the event listener
        instructions.push(IR::AddEventListener(function_name));
        
        instructions
    }

    /// Compile form selector (form login_form { ... })
    fn compile_form_selector(&mut self, form_id: String, block: Vec<crate::parser::Statement>) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Get the form element
        instructions.push(IR::PushString(form_id.clone()));
        instructions.push(IR::GetElementById);
        
        // Store the form element in a variable
        instructions.push(IR::StoreVar(format!("__form_{}", form_id)));
        
        // Compile the form block
        instructions.extend(self.compiler.compile_block(block));
        
        instructions
    }

    /// Compile fetch requests (fetch, post, get_data)
    fn compile_fetch_request(&mut self, url: String, options: Vec<crate::parser::Statement>) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Push the URL
        instructions.push(IR::PushString(url));
        
        // Compile the options
        let options_instructions = self.compiler.compile_block(options);
        
        // Create a function for the options
        let function_name = format!("__fetch_options_{}", self.compiler.get_unique_id());
        instructions.push(IR::DefineFunction(function_name.clone(), options_instructions));
        
        // Make the fetch request
        instructions.push(IR::FetchRequest(function_name));
        
        instructions
    }

    /// Compile storage operations (store_local, store_session)
    fn compile_storage_operation(&mut self, storage_type: String, key: String, value: Expression) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // Push the key
        instructions.push(IR::PushString(key));
        
        // For 'set' operations, compile the value expression
        if value != Expression::Null {
            instructions.extend(self.compiler.compile_expression(value));
            
            // Generate the appropriate storage set instruction
            match storage_type.as_str() {
                "local" => instructions.push(IR::LocalStorageSet),
                "session" => instructions.push(IR::SessionStorageSet),
                _ => instructions.push(IR::Noop), // Should not happen
            }
        } else {
            // For 'get' operations, generate the appropriate storage get instruction
            match storage_type.as_str() {
                "local" => instructions.push(IR::LocalStorageGet),
                "session" => instructions.push(IR::SessionStorageGet),
                _ => instructions.push(IR::Noop), // Should not happen
            }
        }
        
        instructions
    }

    /// Compile timer operations (wait, interval)
    fn compile_timer_operation(&mut self, milliseconds: i64, block: Vec<crate::parser::Statement>) -> Vec<IR> {
        let mut instructions = Vec::new();
        
        // If milliseconds is -1, this is an 'interval clear' operation
        if milliseconds == -1 {
            instructions.push(IR::ClearInterval);
            return instructions;
        }
        
        // Push the milliseconds
        instructions.push(IR::PushInteger(milliseconds));
        
        // Compile the timer block
        let block_instructions = self.compiler.compile_block(block);
        
        // Create a function for the timer callback
        let function_name = format!("__timer_callback_{}", self.compiler.get_unique_id());
        instructions.push(IR::DefineFunction(function_name.clone(), block_instructions));
        
        // Generate the appropriate timer instruction
        if milliseconds > 0 {
            instructions.push(IR::SetTimeout(function_name));
        } else {
            instructions.push(IR::SetInterval(function_name));
        }
        
        instructions
    }

    /// Generate JavaScript code for the web-specific IR instructions
    pub fn generate_js_code(&self, ir_instructions: Vec<IR>) -> String {
        let mut js_code = String::new();
        
        for instruction in ir_instructions {
            match instruction {
                IR::GetElementById => {
                    js_code.push_str("document.getElementById(");
                    js_code.push_str("stack.pop()");
                    js_code.push_str(");\n");
                },
                IR::SetInnerHTML => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const content = stack.pop();\n");
                    js_code.push_str("element.innerHTML = content;\n");
                },
                IR::SetTextContent => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const content = stack.pop();\n");
                    js_code.push_str("element.textContent = content;\n");
                },
                IR::SetAttribute => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const value = stack.pop();\n");
                    js_code.push_str("const name = stack.pop();\n");
                    js_code.push_str("element.setAttribute(name, value);\n");
                },
                IR::SetStyle => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const value = stack.pop();\n");
                    js_code.push_str("const property = stack.pop();\n");
                    js_code.push_str("element.style[property] = value;\n");
                },
                IR::AddClass => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const className = stack.pop();\n");
                    js_code.push_str("element.classList.add(className);\n");
                },
                IR::RemoveClass => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const className = stack.pop();\n");
                    js_code.push_str("element.classList.remove(className);\n");
                },
                IR::ToggleClass => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const className = stack.pop();\n");
                    js_code.push_str("element.classList.toggle(className);\n");
                },
                IR::ContainsClass => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const className = stack.pop();\n");
                    js_code.push_str("stack.push(element.classList.contains(className));\n");
                },
                IR::AddEventListener(function_name) => {
                    js_code.push_str("const element = stack.pop();\n");
                    js_code.push_str("const eventType = stack.pop();\n");
                    js_code.push_str(&format!("element.addEventListener(eventType, {});\n", function_name));
                },
                IR::FetchRequest(options_function) => {
                    js_code.push_str("const url = stack.pop();\n");
                    js_code.push_str(&format!("const options = {}();\n", options_function));
                    js_code.push_str("fetch(url, options)\n");
                    js_code.push_str("  .then(response => response.json())\n");
                    js_code.push_str("  .then(data => {\n");
                    js_code.push_str("    if (options.success) options.success(data);\n");
                    js_code.push_str("  })\n");
                    js_code.push_str("  .catch(error => {\n");
                    js_code.push_str("    if (options.error) options.error(error);\n");
                    js_code.push_str("  });\n");
                },
                IR::LocalStorageSet => {
                    js_code.push_str("const value = stack.pop();\n");
                    js_code.push_str("const key = stack.pop();\n");
                    js_code.push_str("localStorage.setItem(key, JSON.stringify(value));\n");
                },
                IR::LocalStorageGet => {
                    js_code.push_str("const key = stack.pop();\n");
                    js_code.push_str("const value = localStorage.getItem(key);\n");
                    js_code.push_str("stack.push(value ? JSON.parse(value) : null);\n");
                },
                IR::SessionStorageSet => {
                    js_code.push_str("const value = stack.pop();\n");
                    js_code.push_str("const key = stack.pop();\n");
                    js_code.push_str("sessionStorage.setItem(key, JSON.stringify(value));\n");
                },
                IR::SessionStorageGet => {
                    js_code.push_str("const key = stack.pop();\n");
                    js_code.push_str("const value = sessionStorage.getItem(key);\n");
                    js_code.push_str("stack.push(value ? JSON.parse(value) : null);\n");
                },
                IR::SetTimeout(callback_function) => {
                    js_code.push_str("const milliseconds = stack.pop();\n");
                    js_code.push_str(&format!("setTimeout({}, milliseconds);\n", callback_function));
                },
                IR::SetInterval(callback_function) => {
                    js_code.push_str("const milliseconds = stack.pop();\n");
                    js_code.push_str(&format!("const intervalId = setInterval({}, milliseconds);\n", callback_function));
                    js_code.push_str("stack.push(intervalId);\n");
                },
                IR::ClearInterval => {
                    js_code.push_str("const intervalId = stack.pop();\n");
                    js_code.push_str("clearInterval(intervalId);\n");
                },
                // Handle other IR instructions by delegating to the standard compiler
                _ => {
                    js_code.push_str(&self.compiler.generate_js_for_instruction(instruction));
                }
            }
        }
        
        js_code
    }
}

// Add these IR variants to the main IR enum in compiler.rs
impl IR {
    // Web-specific IR instructions
    pub const GetElementById: Self = IR::Custom("GetElementById".to_string());
    pub const SetInnerHTML: Self = IR::Custom("SetInnerHTML".to_string());
    pub const SetTextContent: Self = IR::Custom("SetTextContent".to_string());
    pub const SetAttribute: Self = IR::Custom("SetAttribute".to_string());
    pub const SetStyle: Self = IR::Custom("SetStyle".to_string());
    pub const AddClass: Self = IR::Custom("AddClass".to_string());
    pub const RemoveClass: Self = IR::Custom("RemoveClass".to_string());
    pub const ToggleClass: Self = IR::Custom("ToggleClass".to_string());
    pub const ContainsClass: Self = IR::Custom("ContainsClass".to_string());
    pub const AddEventListener: fn(String) -> Self = |function_name| IR::CustomWithString("AddEventListener".to_string(), function_name);
    pub const FetchRequest: fn(String) -> Self = |options_function| IR::CustomWithString("FetchRequest".to_string(), options_function);
    pub const LocalStorageSet: Self = IR::Custom("LocalStorageSet".to_string());
    pub const LocalStorageGet: Self = IR::Custom("LocalStorageGet".to_string());
    pub const SessionStorageSet: Self = IR::Custom("SessionStorageSet".to_string());
    pub const SessionStorageGet: Self = IR::Custom("SessionStorageGet".to_string());
    pub const SetTimeout: fn(String) -> Self = |callback_function| IR::CustomWithString("SetTimeout".to_string(), callback_function);
    pub const SetInterval: fn(String) -> Self = |callback_function| IR::CustomWithString("SetInterval".to_string(), callback_function);
    pub const ClearInterval: Self = IR::Custom("ClearInterval".to_string());
}
