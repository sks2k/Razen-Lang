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
    WebpageStructure(Vec<Statement>),      // webpage { ... }
    TopSection(Vec<Statement>),            // top { ... }
    BottomSection(Vec<Statement>),         // bottom { ... }
    ElementSelector(String),               // find, search, findall
    ContentManipulation(String, Expression), // insert, write, property, look
    TypeManipulation(String, String),      // type add, remove, toggle, contains
    EventHandler(String, Vec<Statement>),  // when event { ... }
    FormProcessor(String, Vec<Statement>), // entryform id { ... }
    DataRequest(String, Vec<Statement>),   // request, senddata, getdata url { ... }
    DataStorage(String, String, Expression), // save, keep, remember
    UtilityFunction(i64, Vec<Statement>),  // pause, repeat
}

impl WebParser {
    pub fn new(parser: Parser) -> Self {
        WebParser { parser }
    }
    
    /// Parse webpage structure (webpage { ... })
    fn parse_webpage_structure(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'webpage' token
        self.parser.next_token();
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::WebpageStructure(block))
    }
    
    /// Parse top section (top { ... })
    fn parse_top_section(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'top' token
        self.parser.next_token();
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::TopSection(block))
    }
    
    /// Parse bottom section (bottom { ... })
    fn parse_bottom_section(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'bottom' token
        self.parser.next_token();
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::BottomSection(block))
    }

    /// Parse a web-specific expression
    pub fn parse_web_expression(&mut self) -> Result<WebExpression, Error> {
        let token = self.parser.peek_token();
        
        match token.token_type {
            // Document Structure
            TokenType::Webpage => self.parse_webpage_structure(),
            TokenType::Top => self.parse_top_section(),
            TokenType::Bottom => self.parse_bottom_section(),
            
            // Element selectors
            TokenType::Find => self.parse_element_selector("find"),
            TokenType::Search => self.parse_element_selector("search"),
            TokenType::FindAll => self.parse_element_selector("findall"),
            
            // Content manipulation
            TokenType::Insert => self.parse_content_manipulation("insert"),
            TokenType::Write => self.parse_content_manipulation("write"),
            TokenType::Property => self.parse_content_manipulation("property"),
            TokenType::Look => self.parse_content_manipulation("look"),
            
            // Type manipulation
            TokenType::Type => self.parse_type_manipulation(),
            
            // Event handling
            TokenType::When => self.parse_event_handler(),
            TokenType::Stop => self.parse_event_removal(),
            
            // Form handling
            TokenType::EntryForm => self.parse_form_processor(),
            
            // Data Communication
            TokenType::Request => self.parse_data_request("request"),
            TokenType::SendData => self.parse_data_request("senddata"),
            TokenType::GetData => self.parse_data_request("getdata"),
            
            // Data Storage
            TokenType::Save => self.parse_data_storage("save"),
            TokenType::Keep => self.parse_data_storage("keep"),
            TokenType::Remember => self.parse_data_storage("remember"),
            
            // Utility Functions
            TokenType::Pause => self.parse_utility_function("pause"),
            TokenType::Repeat => self.parse_utility_function("repeat"),
            
            _ => Err(Error::new(format!("Unexpected token in web expression: {:?}", token))),
        }
    }

    /// Parse element selector expressions (find, search, findall)
    fn parse_element_selector(&mut self, selector_type: &str) -> Result<WebExpression, Error> {
        // Consume the selector token (find, search, findall)
        self.parser.next_token();
        
        // Get the element ID or selector
        let identifier = self.parser.parse_identifier()?;
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::ElementSelector(identifier))
    }

    /// Parse content manipulation expressions (insert, write, property, look)
    fn parse_content_manipulation(&mut self, manipulation_type: &str) -> Result<WebExpression, Error> {
        // Consume the manipulation token
        self.parser.next_token();
        
        // Expect content or property name
        let content = self.parser.parse_expression(0)?;
        
        Ok(WebExpression::ContentManipulation(manipulation_type.to_string(), content))
    }

    /// Parse type manipulation (add, remove, toggle, contains)
    fn parse_type_manipulation(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'type' token
        self.parser.next_token();
        
        // Get the operation (add, remove, toggle, contains)
        let operation = self.parser.parse_identifier()?;
        
        // Expect equals sign
        self.parser.expect_token(TokenType::Equal)?;
        
        // Get the type name
        let type_name = self.parser.parse_string()?;
        
        Ok(WebExpression::TypeManipulation(operation, type_name))
    }

    /// Parse event handler (when click { ... })
    fn parse_event_handler(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'when' token
        self.parser.next_token();
        
        // Get the event type
        let event_type = self.parser.parse_identifier()?;
        
        // Expect a block of statements
        let block = self.parser.parse_block_statement()?;
        
        Ok(WebExpression::EventHandler(event_type, block))
    }

    /// Parse event removal (stop click)
    fn parse_event_removal(&mut self) -> Result<WebExpression, Error> {
        // Consume the 'stop' token
        self.parser.next_token();
        
        // Get the event type
        let event_type = self.parser.parse_identifier()?;
        
        // This is just a placeholder as event removal doesn't have a block
        Ok(WebExpression::EventHandler(event_type, vec![]))
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
