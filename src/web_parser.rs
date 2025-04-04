use crate::parser::{Parser, Expression, Statement};
use crate::token::{Token, TokenType};
use crate::error::Error;

/// WebParser extends the standard Razen parser with web-specific functionality
pub struct WebParser {
    parser: Parser,
}

/// Web-specific expression types
#[derive(Debug, Clone)]
pub enum WebExpression {
    ElementSelector(String),               // get, query, all
    DomManipulation(String, Expression),   // html, text, attr, style
    ClassManipulation(String, String),     // add, remove, toggle, contains
    EventListener(String, Vec<Statement>), // on event { ... }
    FormSelector(String, Vec<Statement>),  // form id { ... }
    FetchRequest(String, Vec<Statement>),  // fetch url { ... }
    StorageOperation(String, String, Expression), // store_local, store_session
    TimerOperation(i64, Vec<Statement>),   // wait, interval
}

impl WebParser {
    pub fn new(parser: Parser) -> Self {
        WebParser { parser }
    }

    /// Parse a web-specific expression
    pub fn parse_web_expression(&mut self) -> Result<WebExpression, Error> {
        let token = self.parser.peek_token();
        
        match token.token_type {
            // Element selectors
            TokenType::Get => self.parse_element_selector("get"),
            TokenType::Query => self.parse_element_selector("query"),
            TokenType::All => self.parse_element_selector("all"),
            
            // DOM manipulation
            TokenType::Html => self.parse_dom_manipulation("html"),
            TokenType::Text => self.parse_dom_manipulation("text"),
            TokenType::Attr => self.parse_dom_manipulation("attr"),
            TokenType::Style => self.parse_dom_manipulation("style"),
            
            // Class manipulation
            TokenType::Class => self.parse_class_manipulation(),
            
            // Event handling
            TokenType::On => self.parse_event_listener(),
            TokenType::Off => self.parse_event_removal(),
            
            // Form handling
            TokenType::Form => self.parse_form_selector(),
            
            // AJAX and Fetch
            TokenType::Fetch => self.parse_fetch_request("fetch"),
            TokenType::Post => self.parse_fetch_request("post"),
            TokenType::GetData => self.parse_fetch_request("get_data"),
            
            // Storage
            TokenType::StoreLocal => self.parse_storage_operation("local"),
            TokenType::StoreSession => self.parse_storage_operation("session"),
            
            // Timers
            TokenType::Wait => self.parse_timer_operation("wait"),
            TokenType::Interval => self.parse_timer_operation("interval"),
            
            _ => Err(Error::new(format!("Unexpected token in web expression: {:?}", token))),
        }
    }

    /// Parse element selector expressions (get, query, all)
    fn parse_element_selector(&mut self, selector_type: &str) -> Result<WebExpression, Error> {
        // Consume the selector token (get, query, all)
        self.parser.next_token();
        
        // Get the element ID or selector
        let identifier = self.parser.parse_identifier()?;
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::ElementSelector(identifier))
    }

    /// Parse DOM manipulation expressions (html, text, attr, style)
    fn parse_dom_manipulation(&mut self, manipulation_type: &str) -> Result<WebExpression, Error> {
        // Consume the manipulation token
        self.parser.next_token();
        
        // Expect content or property name
        let content = self.parser.parse_expression(0)?;
        
        Ok(WebExpression::DomManipulation(manipulation_type.to_string(), content))
    }

    /// Parse class manipulation (add, remove, toggle, contains)
    fn parse_class_manipulation(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'class' token
        self.parser.next_token();
        
        // Get the operation (add, remove, toggle, contains)
        let operation = self.parser.parse_identifier()?;
        
        // Expect equals sign
        self.parser.expect_token(TokenType::Equal)?;
        
        // Get the class name
        let class_name = self.parser.parse_string()?;
        
        Ok(WebExpression::ClassManipulation(operation, class_name))
    }

    /// Parse event listener (on click { ... })
    fn parse_event_listener(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'on' token
        self.parser.next_token();
        
        // Get the event type
        let event_type = self.parser.parse_identifier()?;
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::EventListener(event_type, block))
    }

    /// Parse event removal (off click)
    fn parse_event_removal(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'off' token
        self.parser.next_token();
        
        // Get the event type
        let event_type = self.parser.parse_identifier()?;
        
        // This is just a placeholder as event removal doesn't have a block
        Ok(WebExpression::EventListener(event_type, vec![]))
    }

    /// Parse form selector (form login_form { ... })
    fn parse_form_selector(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'form' token
        self.parser.next_token();
        
        // Get the form ID
        let form_id = self.parser.parse_identifier()?;
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::FormSelector(form_id, block))
    }

    /// Parse fetch requests (fetch, post, get_data)
    fn parse_fetch_request(&mut self, request_type: &str) -> Result<WebExpression, Error> {
        // Consume the request token
        self.parser.next_token();
        
        // Get the URL
        let url = self.parser.parse_string()?;
        
        // Expect a block of options
        let options = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::FetchRequest(url, options))
    }

    /// Parse storage operations (store_local, store_session)
    fn parse_storage_operation(&mut self, storage_type: &str) -> Result<WebExpression, Error> {
        // Consume the storage token
        self.parser.next_token();
        
        // Get the operation (set, get)
        let operation = self.parser.parse_identifier()?;
        
        // For 'set' operations, expect key, equals sign, and value
        if operation == "set" {
            let key = self.parser.parse_identifier()?;
            self.parser.expect_token(TokenType::Equal)?;
            let value = self.parser.parse_expression(0)?;
            
            Ok(WebExpression::StorageOperation(storage_type.to_string(), key, value))
        } else if operation == "get" {
            // For 'get' operations, just expect the key
            let key = self.parser.parse_identifier()?;
            
            // Use a null expression as placeholder since get doesn't have a value
            Ok(WebExpression::StorageOperation(storage_type.to_string(), key, Expression::Null))
        } else {
            Err(Error::new(format!("Invalid storage operation: {}", operation)))
        }
    }

    /// Parse timer operations (wait, interval)
    fn parse_timer_operation(&mut self, timer_type: &str) -> Result<WebExpression, Error> {
        // Consume the timer token
        self.parser.next_token();
        
        // For 'wait' and 'interval', expect milliseconds and a block
        if timer_type == "wait" || timer_type == "interval" {
            // Get the milliseconds
            let milliseconds = match self.parser.parse_expression(0)? {
                Expression::IntegerLiteral(value) => value,
                _ => return Err(Error::new("Expected integer for timer duration".to_string())),
            };
            
            // Expect a block of statements
            let block = self.parser.parse_block_statement()?;
            
            Ok(WebExpression::TimerOperation(milliseconds, block))
        } else if timer_type == "interval" && self.parser.peek_token().token_type == TokenType::Clear {
            // For 'interval clear', expect an identifier
            self.parser.next_token(); // Consume 'clear'
            let id = self.parser.parse_identifier()?;
            
            // Use an empty block for 'interval clear'
            Ok(WebExpression::TimerOperation(-1, vec![]))
        } else {
            Err(Error::new(format!("Invalid timer operation: {}", timer_type)))
        }
    }

    /// Check if the current token represents a web-specific expression
    pub fn is_web_expression(&self) -> bool {
        let token_type = self.parser.peek_token().token_type;
        
        matches!(token_type, 
            TokenType::Get | TokenType::Query | TokenType::All |
            TokenType::Html | TokenType::Text | TokenType::Attr | TokenType::Style |
            TokenType::Class | TokenType::On | TokenType::Off |
            TokenType::Form | TokenType::Fetch | TokenType::Post | TokenType::GetData |
            TokenType::StoreLocal | TokenType::StoreSession |
            TokenType::Wait | TokenType::Interval
        )
    }
}
