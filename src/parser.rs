use std::collections::HashMap;
use std::path::Path;

use crate::ast::{Program, Statement, Expression};
use crate::token::{Token, TokenType};
use crate::lexer::Lexer;

// Define operator precedence levels
#[derive(PartialEq, PartialOrd, Debug)]
enum Precedence {
    Lowest,
    Assignment,  // =
    LogicalOr,   // ||
    LogicalAnd,  // &&
    Equals,      // ==, !=
    LessGreater, // >, <, >=, <=
    Sum,         // +, -
    Product,     // *, /, %
    Power,       // **
    Prefix,      // -X, !X
    Call,        // myFunction(X)
    Index,       // array[index]
}

pub struct Parser {
    lexer: Lexer,
    current_token: Token,
    peek_token: Token,
    errors: Vec<String>,
    // Maps for prefix and infix parsing functions
    prefix_parse_fns: HashMap<TokenType, fn(&mut Parser) -> Option<Expression>>,
    infix_parse_fns: HashMap<TokenType, fn(&mut Parser, Expression) -> Option<Expression>>,
}

impl Parser {
    pub fn new(mut lexer: Lexer) -> Self {
        let current_token = lexer.next_token();
        let peek_token = lexer.next_token();
        
        let mut parser = Parser {
            lexer,
            current_token,
            peek_token,
            errors: Vec::new(),
            prefix_parse_fns: HashMap::new(),
            infix_parse_fns: HashMap::new(),
        };
        
        // Register prefix parse functions
        parser.register_prefix(TokenType::Identifier, Parser::parse_identifier);
        parser.register_prefix(TokenType::StringLiteral, Parser::parse_string_literal);
        parser.register_prefix(TokenType::NumberLiteral, Parser::parse_number_literal);
        parser.register_prefix(TokenType::True, Parser::parse_boolean_literal);
        parser.register_prefix(TokenType::False, Parser::parse_boolean_literal);
        parser.register_prefix(TokenType::Null, Parser::parse_null_literal);
        parser.register_prefix(TokenType::LeftParen, Parser::parse_grouped_expression);
        parser.register_prefix(TokenType::LeftBracket, Parser::parse_array_literal);
        parser.register_prefix(TokenType::LeftBrace, Parser::parse_map_literal);
        parser.register_prefix(TokenType::Minus, Parser::parse_prefix_expression);
        parser.register_prefix(TokenType::Not, Parser::parse_prefix_expression);
        
        // Register mathematical keywords as identifier parsers
        parser.register_prefix(TokenType::Sum, Parser::parse_identifier);
        parser.register_prefix(TokenType::Diff, Parser::parse_identifier);
        parser.register_prefix(TokenType::Prod, Parser::parse_identifier);
        parser.register_prefix(TokenType::Div, Parser::parse_identifier);
        parser.register_prefix(TokenType::Mod, Parser::parse_identifier);
        
        // Register string operation keywords as identifier parsers
        parser.register_prefix(TokenType::Text, Parser::parse_identifier);
        parser.register_prefix(TokenType::Concat, Parser::parse_identifier);
        parser.register_prefix(TokenType::Slice, Parser::parse_identifier);
        parser.register_prefix(TokenType::Len, Parser::parse_identifier);
        
        // Register list and array keywords as identifier parsers
        parser.register_prefix(TokenType::List, Parser::parse_identifier);
        parser.register_prefix(TokenType::Arr, Parser::parse_identifier);
        parser.register_prefix(TokenType::Append, Parser::parse_identifier);
        parser.register_prefix(TokenType::Remove, Parser::parse_identifier);
        
        // Register dictionary/map keywords as identifier parsers
        parser.register_prefix(TokenType::Map, Parser::parse_identifier);
        parser.register_prefix(TokenType::Key, Parser::parse_identifier);
        parser.register_prefix(TokenType::Value, Parser::parse_identifier);
        
        // Register date/time keywords as identifier parsers
        parser.register_prefix(TokenType::Current, Parser::parse_identifier);
        parser.register_prefix(TokenType::Now, Parser::parse_identifier);
        parser.register_prefix(TokenType::Year, Parser::parse_identifier);
        parser.register_prefix(TokenType::Month, Parser::parse_identifier);
        parser.register_prefix(TokenType::Day, Parser::parse_identifier);
        parser.register_prefix(TokenType::Hour, Parser::parse_identifier);
        parser.register_prefix(TokenType::Minute, Parser::parse_identifier);
        parser.register_prefix(TokenType::Second, Parser::parse_identifier);
        
        // Register user-defined keywords as identifier parsers
        parser.register_prefix(TokenType::Store, Parser::parse_identifier);
        parser.register_prefix(TokenType::Box, Parser::parse_identifier);
        parser.register_prefix(TokenType::Ref, Parser::parse_identifier);
        
        // Register logical keywords as identifier parsers
        parser.register_prefix(TokenType::Is, Parser::parse_identifier);
        parser.register_prefix(TokenType::When, Parser::parse_identifier);
        
        // Register control flow keywords as identifier parsers
        parser.register_prefix(TokenType::If, Parser::parse_identifier);
        parser.register_prefix(TokenType::Else, Parser::parse_identifier);
        parser.register_prefix(TokenType::For, Parser::parse_identifier);
        parser.register_prefix(TokenType::While, Parser::parse_identifier);
        parser.register_prefix(TokenType::Load, Parser::parse_identifier);
        
        // Register library tokens as identifiers
        parser.register_prefix(TokenType::Random, Parser::parse_identifier);
        parser.register_prefix(TokenType::HTLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::Coin, Parser::parse_identifier);
        parser.register_prefix(TokenType::MathLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::Ping, Parser::parse_identifier);
        parser.register_prefix(TokenType::Bolt, Parser::parse_identifier);
        parser.register_prefix(TokenType::Seed, Parser::parse_identifier);
        parser.register_prefix(TokenType::NetLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::File, Parser::parse_identifier);
        parser.register_prefix(TokenType::Json, Parser::parse_identifier);
        parser.register_prefix(TokenType::Date, Parser::parse_identifier);
        parser.register_prefix(TokenType::StrLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::ArrLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::Os, Parser::parse_identifier);
        parser.register_prefix(TokenType::Regex, Parser::parse_identifier);
        parser.register_prefix(TokenType::Crypto, Parser::parse_identifier);
        parser.register_prefix(TokenType::Color, Parser::parse_identifier);
        parser.register_prefix(TokenType::System, Parser::parse_identifier);
        parser.register_prefix(TokenType::Ui, Parser::parse_identifier);
        parser.register_prefix(TokenType::Storage, Parser::parse_identifier);
        parser.register_prefix(TokenType::Audio, Parser::parse_identifier);
        parser.register_prefix(TokenType::Image, Parser::parse_identifier);
        parser.register_prefix(TokenType::Validation, Parser::parse_identifier);
        parser.register_prefix(TokenType::LogLib, Parser::parse_identifier);
        parser.register_prefix(TokenType::Uuid, Parser::parse_identifier);
        parser.register_prefix(TokenType::Read, Parser::parse_identifier);
        parser.register_prefix(TokenType::Debug, Parser::parse_identifier);
        parser.register_prefix(TokenType::Assert, Parser::parse_identifier);
        parser.register_prefix(TokenType::Trace, Parser::parse_identifier);
        parser.register_prefix(TokenType::Show, Parser::parse_identifier);
        parser.register_prefix(TokenType::Exit, Parser::parse_identifier);
        parser.register_prefix(TokenType::Api, Parser::parse_identifier);
        parser.register_prefix(TokenType::Call, Parser::parse_identifier);
        parser.register_prefix(TokenType::Connect, Parser::parse_identifier);
        parser.register_prefix(TokenType::To, Parser::parse_identifier);
        parser.register_prefix(TokenType::Import, Parser::parse_identifier);
        parser.register_prefix(TokenType::Export, Parser::parse_identifier);
        parser.register_prefix(TokenType::From, Parser::parse_identifier);
        parser.register_prefix(TokenType::As, Parser::parse_identifier);
        parser.register_prefix(TokenType::Get, Parser::parse_identifier);
        parser.register_prefix(TokenType::Post, Parser::parse_identifier);
        
        // Register infix parse functions
        parser.register_infix(TokenType::Plus, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Minus, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Slash, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Asterisk, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Percent, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Power, Parser::parse_infix_expression);
        parser.register_infix(TokenType::FloorDiv, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Equal, Parser::parse_infix_expression);
        parser.register_infix(TokenType::NotEqual, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Less, Parser::parse_infix_expression);
        parser.register_infix(TokenType::LessEqual, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Greater, Parser::parse_infix_expression);
        parser.register_infix(TokenType::GreaterEqual, Parser::parse_infix_expression);
        parser.register_infix(TokenType::And, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Or, Parser::parse_infix_expression);
        parser.register_infix(TokenType::Assign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::PlusAssign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::MinusAssign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::AsteriskAssign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::SlashAssign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::PercentAssign, Parser::parse_assignment_expression);
        parser.register_infix(TokenType::LeftParen, Parser::parse_call_expression);
        parser.register_infix(TokenType::LeftBracket, Parser::parse_index_expression);
        parser.register_infix(TokenType::Dot, Parser::parse_dot_expression);
        
        parser
    }
    
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self, String> {
        match Lexer::from_file(path) {
            Ok(lexer) => Ok(Parser::new(lexer)),
            Err(e) => Err(e),
        }
    }
    
    fn register_prefix(&mut self, token_type: TokenType, func: fn(&mut Parser) -> Option<Expression>) {
        self.prefix_parse_fns.insert(token_type, func);
    }
    
    fn register_infix(&mut self, token_type: TokenType, func: fn(&mut Parser, Expression) -> Option<Expression>) {
        self.infix_parse_fns.insert(token_type, func);
    }
    
    fn next_token(&mut self) {
        self.current_token = self.peek_token.clone();
        self.peek_token = self.lexer.next_token();
    }
    
    fn current_token_is(&self, token_type: TokenType) -> bool {
        self.current_token.token_type == token_type
    }
    
    fn peek_token_is(&self, token_type: TokenType) -> bool {
        self.peek_token.token_type == token_type
    }
    
    fn expect_peek(&mut self, token_type: TokenType) -> bool {
        if self.peek_token_is(token_type.clone()) {
            self.next_token();
            true
        } else {
            self.peek_error(token_type);
            false
        }
    }
    
    fn peek_error(&mut self, token_type: TokenType) {
        let msg = format!(
            "Expected next token to be {:?}, got {:?} instead at line {}, column {}",
            token_type,
            self.peek_token.token_type,
            self.peek_token.line,
            self.peek_token.column
        );
        self.errors.push(msg);
    }
    
    pub fn get_errors(&self) -> &[String] {
        &self.errors
    }
    
    pub fn parse_program(&mut self) -> Program {
        let mut program = Program::new();
        
        while !self.current_token_is(TokenType::EOF) {
            if let Some(stmt) = self.parse_statement() {
                program.statements.push(stmt);
            }
            self.next_token();
        }
        
        program
    }
    
    fn parse_statement(&mut self) -> Option<Statement> {
        match self.current_token.token_type {
            // Variable declaration keywords
            TokenType::Let | TokenType::Take | TokenType::Hold | TokenType::Put | 
            TokenType::Sum | TokenType::Diff | TokenType::Prod | TokenType::Div | TokenType::Mod |
            TokenType::Text | TokenType::Concat | TokenType::Slice | TokenType::Len |
            TokenType::List | TokenType::Arr | TokenType::Append | TokenType::Remove |
            TokenType::Map | TokenType::Key | TokenType::Value |
            TokenType::Current | TokenType::Now | TokenType::Year | TokenType::Month | 
            TokenType::Day | TokenType::Hour | TokenType::Minute | TokenType::Second |
            TokenType::Store | TokenType::Box | TokenType::Ref => self.parse_variable_declaration(),
            
            TokenType::Fun => self.parse_function_declaration(),
            TokenType::Return => self.parse_return_statement(),
            TokenType::If => self.parse_if_statement(),
            TokenType::Else => self.parse_else_statement(),
            TokenType::While => self.parse_while_statement(),
            TokenType::For => self.parse_for_statement(),
            TokenType::Break => self.parse_break_statement(),
            TokenType::Continue => self.parse_continue_statement(),
            TokenType::Show => self.parse_show_statement(),
            TokenType::Read => self.parse_read_statement(),
            TokenType::Exit => self.parse_exit_statement(),
            TokenType::Load => self.parse_load_statement(),
            TokenType::Try => self.parse_try_statement(),
            TokenType::Throw => self.parse_throw_statement(),
            TokenType::DocumentType => self.parse_document_type_declaration(),
            TokenType::Is => self.parse_is_statement(),
            TokenType::When => self.parse_when_statement(),
            
            // Module system
            TokenType::Use => self.parse_module_import(),
            TokenType::Export => self.parse_module_export(),
            TokenType::Import => self.parse_import_statement(),
            
            // Developer tools
            TokenType::Debug => self.parse_debug_statement(),
            TokenType::Assert => self.parse_assert_statement(),
            TokenType::Trace => self.parse_trace_statement(),
            
            // OOP Keywords
            TokenType::Class => self.parse_class_declaration(),
            
            // API Keywords
            TokenType::Api => self.parse_api_declaration(),
            TokenType::Call => self.parse_api_call(),
            
            // Connection Keywords
            TokenType::Connect => self.parse_connect_statement(),
            
            // Library Keywords
            TokenType::Lib => self.parse_lib_statement(),
            
            TokenType::Comment => {
                // Skip comments and return None to continue parsing
                None
            },
            _ => self.parse_expression_statement(),
        }
    }
    
    fn parse_variable_declaration(&mut self) -> Option<Statement> {
        let var_type = self.current_token.literal.clone();
        
        if !self.expect_peek(TokenType::Identifier) {
            return None;
        }
        
        let name = self.current_token.literal.clone();
        
        if !self.expect_peek(TokenType::Assign) {
            return None;
        }
        
        self.next_token();
        
        let value = self.parse_expression(Precedence::Lowest)?;
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::VariableDeclaration {
            var_type,
            name,
            value: Some(value),
        })
    }
    
    fn parse_function_declaration(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::Identifier) {
            return None;
        }
        
        let name = self.current_token.literal.clone();
        
        if !self.expect_peek(TokenType::LeftParen) {
            return None;
        }
        
        let parameters = self.parse_function_parameters();
        
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        let body = self.parse_block_statement();
        
        Some(Statement::FunctionDeclaration {
            name,
            parameters,
            body,
        })
    }
    
    fn parse_function_parameters(&mut self) -> Vec<String> {
        let mut parameters = Vec::new();
        
        if self.peek_token_is(TokenType::RightParen) {
            self.next_token();
            return parameters;
        }
        
        self.next_token();
        
        parameters.push(self.current_token.literal.clone());
        
        while self.peek_token_is(TokenType::Comma) {
            self.next_token(); // Skip comma
            self.next_token(); // Move to next parameter
            parameters.push(self.current_token.literal.clone());
        }
        
        if !self.expect_peek(TokenType::RightParen) {
            return Vec::new();
        }
        
        parameters
    }
    
    fn parse_return_statement(&mut self) -> Option<Statement> {
        self.next_token();
        
        let value = if self.current_token_is(TokenType::Semicolon) {
            None
        } else {
            let expr = self.parse_expression(Precedence::Lowest)?;
            Some(expr)
        };
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ReturnStatement { value })
    }
    
    fn parse_expression_statement(&mut self) -> Option<Statement> {
        let expr = self.parse_expression(Precedence::Lowest)?;
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ExpressionStatement { expression: expr })
    }
    
    fn parse_block_statement(&mut self) -> Vec<Statement> {
        let mut statements = Vec::new();
        
        self.next_token();
        
        while !self.current_token_is(TokenType::RightBrace) && !self.current_token_is(TokenType::EOF) {
            if let Some(stmt) = self.parse_statement() {
                statements.push(stmt);
            }
            self.next_token();
        }
        
        statements
    }
    
    fn parse_if_statement(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::LeftParen) {
            return None;
        }
        
        self.next_token();
        let condition = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::RightParen) {
            return None;
        }
        
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        let consequence = self.parse_block_statement();
        
        let alternative = if self.peek_token_is(TokenType::Else) {
            self.next_token();
            
            if !self.expect_peek(TokenType::LeftBrace) {
                return None;
            }
            
            Some(self.parse_block_statement())
        } else {
            None
        };
        
        Some(Statement::IfStatement {
            condition,
            consequence,
            alternative,
        })
    }
    
    fn parse_while_statement(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::LeftParen) {
            return None;
        }
        
        self.next_token();
        let condition = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::RightParen) {
            return None;
        }
        
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        let body = self.parse_block_statement();
        
        Some(Statement::WhileStatement {
            condition,
            body,
        })
    }
    
    fn parse_for_statement(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::LeftParen) {
            return None;
        }
        
        self.next_token();
        let iterator = self.current_token.literal.clone();
        
        if !self.expect_peek(TokenType::In) {
            return None;
        }
        
        self.next_token();
        let iterable = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::RightParen) {
            return None;
        }
        
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        let body = self.parse_block_statement();
        
        Some(Statement::ForStatement {
            iterator,
            iterable,
            body,
        })
    }
    
    fn parse_break_statement(&mut self) -> Option<Statement> {
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::BreakStatement)
    }
    
    fn parse_continue_statement(&mut self) -> Option<Statement> {
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ContinueStatement)
    }
    
    fn parse_show_statement(&mut self) -> Option<Statement> {
        self.next_token();
        
        let value = self.parse_expression(Precedence::Lowest)?;
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ShowStatement { value })
    }
    
    fn parse_try_statement(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        let try_block = self.parse_block_statement();
        
        let catch_block = if self.peek_token_is(TokenType::Catch) {
            self.next_token();
            
            if !self.expect_peek(TokenType::LeftBrace) {
                return None;
            }
            
            Some(self.parse_block_statement())
        } else {
            None
        };
        
        let finally_block = if self.peek_token_is(TokenType::Finally) {
            self.next_token();
            
            if !self.expect_peek(TokenType::LeftBrace) {
                return None;
            }
            
            Some(self.parse_block_statement())
        } else {
            None
        };
        
        Some(Statement::TryStatement {
            try_block,
            catch_block,
            finally_block,
        })
    }
    
    fn parse_throw_statement(&mut self) -> Option<Statement> {
        self.next_token();
        
        let value = self.parse_expression(Precedence::Lowest)?;
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ThrowStatement { value })
    }
    
    fn parse_read_statement(&mut self) -> Option<Statement> {
        if !self.expect_peek(TokenType::Identifier) {
            return None;
        }
        
        let name = self.current_token.literal.clone();
        
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ReadStatement { name })
    }
    
    fn parse_exit_statement(&mut self) -> Option<Statement> {
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ExitStatement)
    }
    
    /// Parse document type declaration (type web; type script; type cli;)
    fn parse_document_type_declaration(&mut self) -> Option<Statement> {
        // Consume the 'type' token
        self.next_token();
        
        // Check if there's an equals sign
        let has_equals = self.current_token_is(TokenType::Assign);
        if has_equals {
            self.next_token(); // Consume the equals sign
        }
        
        // Get the document type (web, script, cli, freestyle)
        if self.current_token_is(TokenType::Identifier) {
            let doc_type = self.current_token.literal.clone();
            
            // Expect semicolon
            if self.peek_token_is(TokenType::Semicolon) {
                self.next_token();
            }
            
            Some(Statement::DocumentTypeDeclaration { doc_type })
        } else {
            self.errors.push(format!("Expected document type after 'type{}', got {:?}", 
                                    if has_equals { " =" } else { "" }, 
                                    self.current_token.token_type));
            None
        }
    }
    
    /// Parse module import statement (use name from "module"; or use name1, name2 from "module"; or use module as alias from "module";)
    fn parse_module_import(&mut self) -> Option<Statement> {
        // Skip 'use' token
        self.next_token();
        
        // Parse import names
        let mut names = Vec::new();
        let mut alias = None;
        
        // First name must be an identifier
        if !self.current_token_is(TokenType::Identifier) {
            self.errors.push(format!("Expected identifier after 'use', got {:?}", self.current_token.token_type));
            return None;
        }
        
        names.push(self.current_token.literal.clone());
        self.next_token();
        
        // Check for 'as' keyword for namespace alias
        if self.current_token_is(TokenType::As) {
            self.next_token(); // Skip 'as'
            
            if !self.current_token_is(TokenType::Identifier) {
                self.errors.push(format!("Expected identifier after 'as', got {:?}", self.current_token.token_type));
                return None;
            }
            
            alias = Some(self.current_token.literal.clone());
            self.next_token();
        } else {
            // Parse additional names if there's a comma
            while self.current_token_is(TokenType::Comma) {
                self.next_token(); // Skip comma
                
                if !self.current_token_is(TokenType::Identifier) {
                    self.errors.push(format!("Expected identifier after comma, got {:?}", self.current_token.token_type));
                    return None;
                }
                
                names.push(self.current_token.literal.clone());
                self.next_token();
            }
        }
        
        // Expect 'from' keyword
        if !self.current_token_is(TokenType::From) {
            self.errors.push(format!("Expected 'from' after import names, got {:?}", self.current_token.token_type));
            return None;
        }
        
        // Skip 'from'
        self.next_token();
        
        // Expect string literal for module path
        if !self.current_token_is(TokenType::StringLiteral) {
            self.errors.push(format!("Expected string literal for module path, got {:?}", self.current_token.token_type));
            return None;
        }
        
        let source = self.current_token.literal.clone();
        
        // Skip string literal
        self.next_token();
        
        // Expect semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ModuleImport { names, alias, source })
    }
    
    /// Parse module export statement (export name;)
    fn parse_module_export(&mut self) -> Option<Statement> {
        // Skip 'export' token
        self.next_token();
        
        if !self.current_token_is(TokenType::Identifier) {
            self.errors.push(format!("Expected identifier after 'export', got {:?}", self.current_token.token_type));
            return None;
        }
        
        let name = self.current_token.literal.clone();
        
        // Skip identifier
        self.next_token();
        
        // Expect semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ModuleExport { name })
    }
    
    /// Parse debug statement (debug expression;)
    fn parse_debug_statement(&mut self) -> Option<Statement> {
        // Skip 'debug' token
        self.next_token();
        
        let value = match self.parse_expression(Precedence::Lowest) {
            Some(expr) => expr,
            None => return None,
        };
        
        // Expect semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::DebugStatement { value })
    }
    
    /// Parse assert statement (assert(condition, message?);)
    fn parse_assert_statement(&mut self) -> Option<Statement> {
        // Skip 'assert' token
        self.next_token();
        
        // Expect left parenthesis
        if !self.expect_peek(TokenType::LeftParen) {
            return None;
        }
        
        // Skip left parenthesis and move to condition
        self.next_token();
        
        let condition = match self.parse_expression(Precedence::Lowest) {
            Some(expr) => expr,
            None => return None,
        };
        
        let mut message = None;
        
        // Check for comma (optional message)
        if self.peek_token_is(TokenType::Comma) {
            self.next_token(); // Move to comma
            self.next_token(); // Move past comma to message expression
            
            message = match self.parse_expression(Precedence::Lowest) {
                Some(expr) => Some(expr),
                None => return None,
            };
        }
        
        // Expect right parenthesis
        if !self.expect_peek(TokenType::RightParen) {
            return None;
        }
        
        // Expect semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::AssertStatement { condition, message })
    }
    
    /// Parse trace statement (trace expression;)
    fn parse_trace_statement(&mut self) -> Option<Statement> {
        // Skip 'trace' token
        self.next_token();
        
        let value = match self.parse_expression(Precedence::Lowest) {
            Some(expr) => expr,
            None => return None,
        };
        
        // Expect semicolon
        if self.current_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::TraceStatement { value })
    }
    
    fn parse_expression(&mut self, precedence: Precedence) -> Option<Expression> {
        // Skip comments
        if self.current_token.token_type == TokenType::Comment {
            return None;
        }
        
        // Try to get a prefix parse function for the current token
        let prefix = self.prefix_parse_fns.get(&self.current_token.token_type).cloned();
        
        if prefix.is_none() {
            self.errors.push(format!(
                "No prefix parse function for {:?} found at line {}, column {}",
                self.current_token.token_type,
                self.current_token.line,
                self.current_token.column
            ));
            return None;
        }
        
        let mut left_exp = prefix.unwrap()(self)?;
        
        while !self.peek_token_is(TokenType::Semicolon) && precedence < self.peek_precedence() {
            let infix = self.infix_parse_fns.get(&self.peek_token.token_type).cloned();
            
            if infix.is_none() {
                return Some(left_exp);
            }
            
            self.next_token();
            
            left_exp = infix.unwrap()(self, left_exp)?;
        }
        
        Some(left_exp)
    }
    
    fn parse_identifier(&mut self) -> Option<Expression> {
        // Convert library tokens to identifiers when used in expressions
        let identifier = match self.current_token.token_type {
            TokenType::Random | TokenType::HTLib | TokenType::Coin | TokenType::MathLib | 
            TokenType::Ping | TokenType::Bolt | TokenType::Seed | TokenType::NetLib | 
            TokenType::File | TokenType::Json | TokenType::Date | TokenType::StrLib | 
            TokenType::ArrLib | TokenType::Os | TokenType::Regex | TokenType::Crypto | 
            TokenType::Color | TokenType::System | TokenType::Ui | TokenType::Storage | 
            TokenType::Audio | TokenType::Image | TokenType::Validation | 
            TokenType::LogLib | TokenType::Uuid => {
                self.current_token.literal.clone()
            },
            _ => self.current_token.literal.clone()
        };
        Some(Expression::Identifier(identifier))
    }
    
    fn parse_string_literal(&mut self) -> Option<Expression> {
        Some(Expression::StringLiteral(self.current_token.literal.clone()))
    }
    
    fn parse_number_literal(&mut self) -> Option<Expression> {
        match self.current_token.literal.parse::<f64>() {
            Ok(value) => Some(Expression::NumberLiteral(value)),
            Err(_) => {
                self.errors.push(format!(
                    "Could not parse {} as number at line {}, column {}",
                    self.current_token.literal,
                    self.current_token.line,
                    self.current_token.column
                ));
                None
            }
        }
    }
    
    fn parse_boolean_literal(&mut self) -> Option<Expression> {
        Some(Expression::BooleanLiteral(self.current_token_is(TokenType::True)))
    }
    
    fn parse_null_literal(&mut self) -> Option<Expression> {
        Some(Expression::NullLiteral)
    }
    
    fn parse_prefix_expression(&mut self) -> Option<Expression> {
        let operator = self.current_token.literal.clone();
        
        self.next_token();
        
        let right = self.parse_expression(Precedence::Prefix)?;
        
        Some(Expression::PrefixExpression {
            operator,
            right: Box::new(right),
        })
    }
    
    fn parse_infix_expression(&mut self, left: Expression) -> Option<Expression> {
        let operator = self.current_token.literal.clone();
        let precedence = self.current_precedence();
        
        self.next_token();
        
        let right = self.parse_expression(precedence)?;
        
        Some(Expression::InfixExpression {
            left: Box::new(left),
            operator,
            right: Box::new(right),
        })
    }
    
    fn parse_assignment_expression(&mut self, left: Expression) -> Option<Expression> {
        let operator = self.current_token.literal.clone();
        
        self.next_token();
        
        let right = self.parse_expression(Precedence::Lowest)?;
        
        Some(Expression::AssignmentExpression {
            left: Box::new(left),
            operator,
            right: Box::new(right),
        })
    }
    
    fn parse_grouped_expression(&mut self) -> Option<Expression> {
        self.next_token();
        
        let expr = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::RightParen) {
            return None;
        }
        
        Some(expr)
    }
    
    fn parse_array_literal(&mut self) -> Option<Expression> {
        let elements = self.parse_expression_list(TokenType::RightBracket)?;
        
        Some(Expression::ArrayLiteral { elements })
    }
    
    fn parse_map_literal(&mut self) -> Option<Expression> {
        let mut pairs = Vec::new();
        
        while !self.peek_token_is(TokenType::RightBrace) {
            self.next_token();
            
            let key = self.parse_expression(Precedence::Lowest)?;
            
            if !self.expect_peek(TokenType::Colon) {
                return None;
            }
            
            self.next_token();
            
            let value = self.parse_expression(Precedence::Lowest)?;
            
            pairs.push((key, value));
            
            if !self.peek_token_is(TokenType::RightBrace) && !self.expect_peek(TokenType::Comma) {
                return None;
            }
        }
        
        if !self.expect_peek(TokenType::RightBrace) {
            return None;
        }
        
        Some(Expression::MapLiteral { pairs })
    }
    
    fn parse_call_expression(&mut self, function: Expression) -> Option<Expression> {
        let arguments = self.parse_expression_list(TokenType::RightParen)?;
        
        Some(Expression::CallExpression {
            function: Box::new(function),
            arguments,
        })
    }
    
    fn parse_index_expression(&mut self, left: Expression) -> Option<Expression> {
        self.next_token();
        
        let index = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::RightBracket) {
            return None;
        }
        
        // Check if this is a library function call (e.g., ArrLib[push](1, 2))
        if self.peek_token_is(TokenType::LeftParen) {
            // This is a library function call
            self.next_token(); // Consume the left paren
            
            let arguments = self.parse_expression_list(TokenType::RightParen)?;
            
            return Some(Expression::LibraryCall {
                library: Box::new(left),
                function: Box::new(index),
                arguments,
            });
        }
        
        Some(Expression::IndexExpression {
            left: Box::new(left),
            index: Box::new(index),
        })
    }
    
    fn parse_dot_expression(&mut self, left: Expression) -> Option<Expression> {
        self.next_token(); // Skip '.' token
        
        if !self.current_token_is(TokenType::Identifier) {
            // Handle library tokens as identifiers
            let is_library_token = match self.current_token.token_type {
                TokenType::Random | TokenType::HTLib | TokenType::Coin | TokenType::MathLib | 
                TokenType::Ping | TokenType::Bolt | TokenType::Seed | TokenType::NetLib | 
                TokenType::File | TokenType::Json | TokenType::Date | TokenType::StrLib | 
                TokenType::ArrLib | TokenType::Os | TokenType::Regex | TokenType::Crypto | 
                TokenType::Color | TokenType::System | TokenType::Ui | TokenType::Storage | 
                TokenType::Audio | TokenType::Image | TokenType::Validation | 
                TokenType::LogLib | TokenType::Uuid | TokenType::Get | TokenType::Post |
                TokenType::Read | TokenType::Debug | TokenType::Assert | TokenType::Trace |
                TokenType::Show | TokenType::Exit | TokenType::Api | TokenType::Call |
                TokenType::Connect | TokenType::To | TokenType::Import | TokenType::Export |
                TokenType::From | TokenType::As => true,
                _ => false
            };
            
            if !is_library_token {
                self.errors.push(format!(
                    "Expected identifier after '.', got {:?} at line {}, column {}",
                    self.current_token.token_type, self.current_token.line, self.current_token.column
                ));
                return None;
            }
        }
        
        // Get the property name
        let property = self.current_token.literal.clone();
        
        // Create a property access expression
        Some(Expression::InfixExpression {
            left: Box::new(left),
            operator: ".".to_string(),
            right: Box::new(Expression::Identifier(property)),
        })
    }
    
    fn parse_expression_list(&mut self, end: TokenType) -> Option<Vec<Expression>> {
        let mut list = Vec::new();
        
        if self.peek_token_is(end.clone()) {
            self.next_token();
            return Some(list);
        }
        
        self.next_token();
        
        list.push(self.parse_expression(Precedence::Lowest)?);
        
        while self.peek_token_is(TokenType::Comma) {
            self.next_token();
            self.next_token();
            list.push(self.parse_expression(Precedence::Lowest)?);
        }
        
        if !self.expect_peek(end) {
            return None;
        }
        
        Some(list)
    }
    
    fn current_precedence(&self) -> Precedence {
        Self::token_precedence(&self.current_token.token_type)
    }
    
    fn peek_precedence(&self) -> Precedence {
        Self::token_precedence(&self.peek_token.token_type)
    }
    
    fn token_precedence(token_type: &TokenType) -> Precedence {
        match token_type {
            TokenType::Assign | TokenType::PlusAssign | TokenType::MinusAssign | 
            TokenType::AsteriskAssign | TokenType::SlashAssign | TokenType::PercentAssign => Precedence::Assignment,
            TokenType::Or => Precedence::LogicalOr,
            TokenType::And => Precedence::LogicalAnd,
            TokenType::Equal | TokenType::NotEqual => Precedence::Equals,
            TokenType::Less | TokenType::LessEqual | TokenType::Greater | TokenType::GreaterEqual => Precedence::LessGreater,
            TokenType::Plus | TokenType::Minus => Precedence::Sum,
            TokenType::Slash | TokenType::Asterisk | TokenType::Percent | TokenType::FloorDiv => Precedence::Product,
            TokenType::Power => Precedence::Power,
            TokenType::LeftParen => Precedence::Call,
            TokenType::LeftBracket => Precedence::Index,
            TokenType::Dot => Precedence::Call, // Dot has same precedence as function call
            _ => Precedence::Lowest,
        }
    }
    // Parse class declaration (class Name { ... })
    fn parse_class_declaration(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Expect class name (identifier)
        if !self.expect_peek(TokenType::Identifier) {
            self.errors.push(format!(
                "Expected class name after 'class' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        let class_name = self.current_token.literal.clone();
        
        // Expect opening brace
        if !self.expect_peek(TokenType::LeftBrace) {
            self.errors.push(format!(
                "Expected '{{' after class name at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Parse class body
        let body = self.parse_block_statement();
        
        Some(Statement::ClassDeclaration {
            name: class_name,
            body,
        })
    }
    
    // Parse API declaration (api name = from("url"))
    fn parse_api_declaration(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Expect API name (identifier)
        if !self.expect_peek(TokenType::Identifier) {
            self.errors.push(format!(
                "Expected API name after 'api' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        let api_name = self.current_token.literal.clone();
        
        // Expect assignment operator
        if !self.expect_peek(TokenType::Assign) {
            self.errors.push(format!(
                "Expected '=' after API name at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect 'from' keyword
        if !self.expect_peek(TokenType::From) {
            self.errors.push(format!(
                "Expected 'from' after '=' in API declaration at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect opening parenthesis
        if !self.expect_peek(TokenType::LeftParen) {
            self.errors.push(format!(
                "Expected '(' after 'from' in API declaration at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect URL string
        if !self.expect_peek(TokenType::StringLiteral) {
            self.errors.push(format!(
                "Expected string literal in API declaration, got {:?} instead at line {}, column {}",
                self.current_token.token_type,
                self.current_token.line,
                self.current_token.column
            ));
            return None;
        }
        
        let url = self.current_token.literal.clone();
        
        // Expect closing parenthesis
        if !self.expect_peek(TokenType::RightParen) {
            self.errors.push(format!(
                "Expected ')' after URL in API declaration at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Check for optional semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ApiDeclaration {
            name: api_name,
            url,
        })
    }
    
    // Parse API call (call api_name { ... })
    fn parse_api_call(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Expect API name (identifier)
        if !self.expect_peek(TokenType::Identifier) {
            self.errors.push(format!(
                "Expected API name after 'call' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        let api_name = self.current_token.literal.clone();
        
        // Expect opening brace
        if !self.expect_peek(TokenType::LeftBrace) {
            self.errors.push(format!(
                "Expected '{{' after API name in call statement at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Parse API call body
        let body = self.parse_block_statement();
        
        Some(Statement::ApiCall {
            name: api_name,
            body,
        })
    }
    
    // Parse connect statement (connect name = from("url") { options })
    fn parse_connect_statement(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Expect connection name (identifier)
        if !self.expect_peek(TokenType::Identifier) {
            self.errors.push(format!(
                "Expected connection name after 'connect' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        let connection_name = self.current_token.literal.clone();
        
        // Expect assignment operator
        if !self.expect_peek(TokenType::Assign) {
            self.errors.push(format!(
                "Expected '=' after connection name at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect 'from' keyword
        if !self.expect_peek(TokenType::From) {
            self.errors.push(format!(
                "Expected 'from' after '=' in connect statement, got {:?} instead at line {}, column {}",
                self.current_token.token_type,
                self.current_token.line,
                self.current_token.column
            ));
            return None;
        }
        
        // Expect opening parenthesis
        if !self.expect_peek(TokenType::LeftParen) {
            self.errors.push(format!(
                "Expected '(' after 'from' in connect statement at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect URL string
        if !self.expect_peek(TokenType::StringLiteral) {
            self.errors.push(format!(
                "Expected string literal in connect statement, got {:?} instead at line {}, column {}",
                self.current_token.token_type,
                self.current_token.line,
                self.current_token.column
            ));
            return None;
        }
        
        let url = self.current_token.literal.clone();
        
        // Expect closing parenthesis
        if !self.expect_peek(TokenType::RightParen) {
            self.errors.push(format!(
                "Expected ')' after URL in connect statement at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        let mut options = Vec::new();
        
        // Check for optional configuration block
        if self.peek_token_is(TokenType::LeftBrace) {
            self.next_token(); // Move to {
            
            // Parse configuration options
            if !self.expect_peek(TokenType::RightBrace) {
                // Parse options until we reach the closing brace
                loop {
                    // Expect option name (identifier)
                    if !self.current_token_is(TokenType::Identifier) {
                        self.errors.push(format!(
                            "Expected option name in connect configuration at line {}, column {}",
                            self.current_token.line, self.current_token.column
                        ));
                        return None;
                    }
                    
                    let option_name = self.current_token.literal.clone();
                    self.next_token();
                    
                    // Parse option value expression
                    let option_value = if let Some(expr) = self.parse_expression(Precedence::Lowest) {
                        expr
                    } else {
                        self.errors.push(format!(
                            "Expected expression for option '{}' at line {}, column {}",
                            option_name,
                            self.current_token.line,
                            self.current_token.column
                        ));
                        return None;
                    };
                    
                    options.push((option_name, option_value));
                    
                    // Skip semicolon if present
                    if self.current_token_is(TokenType::Semicolon) {
                        self.next_token();
                    }
                    
                    // Break if we've reached the end of the options block
                    if self.current_token_is(TokenType::RightBrace) {
                        break;
                    }
                    
                    // If we haven't reached the end, there should be more options
                    if self.current_token_is(TokenType::EOF) {
                        self.errors.push(format!(
                            "Unexpected end of file in connect configuration at line {}, column {}",
                            self.current_token.line, self.current_token.column
                        ));
                        return None;
                    }
                }
            }
        }
        
        // Check for optional semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ConnectStatement {
            name: connection_name,
            url,
            options,
        })
    }
    
    // Parse import statement (import {name} from(./path/to/file))
    fn parse_import_statement(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Check for { to start import list
        if !self.expect_peek(TokenType::LeftBrace) {
            self.errors.push(format!(
                "Expected '{{' after 'import' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        let mut imports = Vec::new();
        
        // Parse import names
        self.next_token(); // Move past {
        
        // Handle empty import list
        if self.current_token_is(TokenType::RightBrace) {
            self.errors.push(format!(
                "Empty import list at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Parse import names
        while !self.current_token_is(TokenType::RightBrace) && !self.current_token_is(TokenType::EOF) {
            if self.current_token_is(TokenType::Identifier) {
                imports.push(self.current_token.literal.clone());
            } else {
                self.errors.push(format!(
                    "Expected identifier in import list, got {:?} instead at line {}, column {}",
                    self.current_token.token_type,
                    self.current_token.line,
                    self.current_token.column
                ));
                return None;
            }
            
            // Move to next token
            self.next_token();
            
            // Check for comma or closing brace
            if self.current_token_is(TokenType::Comma) {
                self.next_token(); // Skip comma and continue
            } else if !self.current_token_is(TokenType::RightBrace) {
                self.errors.push(format!(
                    "Expected ',' or '}}' after import name, got {:?} instead at line {}, column {}",
                    self.current_token.token_type,
                    self.current_token.line,
                    self.current_token.column
                ));
                return None;
            }
        }
        
        // Check for from keyword
        if !self.expect_peek(TokenType::From) {
            self.errors.push(format!(
                "Expected 'from' after import list at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Check for opening parenthesis
        if !self.expect_peek(TokenType::LeftParen) {
            self.errors.push(format!(
                "Expected '(' after 'from' in import statement at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Parse path
        self.next_token(); // Move past (
        
        // Path can be either a string literal or an identifier (for relative paths)
        let path = if self.current_token_is(TokenType::StringLiteral) {
            // String literal path
            self.current_token.literal.clone()
        } else if self.current_token_is(TokenType::Identifier) || self.current_token_is(TokenType::Dot) {
            // Relative path starting with identifier or dot
            let mut path_str = self.current_token.literal.clone();
            
            // Continue parsing path components
            while self.peek_token_is(TokenType::Dot) || self.peek_token_is(TokenType::Slash) {
                self.next_token();
                path_str.push_str(&self.current_token.literal);
                
                // Check for path component after dot or slash
                if self.peek_token_is(TokenType::Identifier) {
                    self.next_token();
                    path_str.push_str(&self.current_token.literal);
                }
            }
            
            path_str
        } else {
            self.errors.push(format!(
                "Expected string literal or path in import statement, got {:?} instead at line {}, column {}",
                self.current_token.token_type,
                self.current_token.line,
                self.current_token.column
            ));
            return None;
        };
        
        // Check for closing parenthesis
        if !self.expect_peek(TokenType::RightParen) {
            self.errors.push(format!(
                "Expected ')' after path in import statement at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Check for optional semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::ImportStatement {
            imports,
            path,
        })
    }
    
    // Parse library import statement (lib name)
    fn parse_lib_statement(&mut self) -> Option<Statement> {
        // Get the current token position for error reporting
        let token_line = self.current_token.line;
        let token_column = self.current_token.column;
        
        // Move to the next token
        self.next_token();
        
        // Check if the next token is a valid library name (either an identifier or a library token)
        let is_valid_library = match self.current_token.token_type {
            TokenType::Identifier | 
            TokenType::Random | TokenType::HTLib | TokenType::Coin | TokenType::MathLib | 
            TokenType::Ping | TokenType::Bolt | TokenType::Seed | TokenType::NetLib | 
            TokenType::File | TokenType::Json | TokenType::Date | TokenType::StrLib | 
            TokenType::ArrLib | TokenType::Os | TokenType::Regex | TokenType::Crypto | 
            TokenType::Color | TokenType::System | TokenType::Ui | TokenType::Storage | 
            TokenType::Audio | TokenType::Image | TokenType::Validation | 
            TokenType::LogLib | TokenType::Uuid | TokenType::BoxLib | TokenType::IOLib |
            TokenType::NumLib | TokenType::RefLib | TokenType::TimeLib | 
            TokenType::TypeCheckLib | TokenType::TypeConvertLib => true,
            _ => false
        };
        
        if !is_valid_library {
            self.errors.push(format!(
                "Expected library name after 'lib' keyword at line {}, column {}",
                token_line, token_column
            ));
            return None;
        }
        
        // Get library name and convert to lowercase for case-insensitive comparison
        let lib_name = self.current_token.literal.clone();
        let lib_name_lower = lib_name.to_lowercase();
        
        // No need to validate library names anymore - the compiler will dynamically scan the properties/libs folder
        // and register all available libraries. This makes the system more extensible.
        
        // Check for optional semicolon
        if self.peek_token_is(TokenType::Semicolon) {
            self.next_token();
        }
        
        Some(Statement::LibStatement {
            name: lib_name,
        })
    }
    
    fn parse_load_statement(&mut self) -> Option<Statement> {
        // Expect: load ( <number> ) { ... }
        
        // Expect opening parenthesis
        if !self.expect_peek(TokenType::LeftParen) {
            self.errors.push(format!(
                "Expected '(' after 'load' keyword at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Move past the '(' to the number
        self.next_token();
        
        // Parse the number of cycles expression
        let cycles = match self.parse_expression(Precedence::Lowest) {
            Some(expr) => expr,
            None => {
                self.errors.push(format!(
                    "Expected number after 'load(' at line {}, column {}",
                    self.current_token.line, self.current_token.column
                ));
                return None;
            }
        };
        
        // Expect closing parenthesis
        if !self.expect_peek(TokenType::RightParen) {
            self.errors.push(format!(
                "Expected ')' after load count at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Expect opening brace for block
        if !self.expect_peek(TokenType::LeftBrace) {
            self.errors.push(format!(
                "Expected '{{' after 'load()' at line {}, column {}",
                self.current_token.line, self.current_token.column
            ));
            return None;
        }
        
        // Parse the block of statements inside the load
        let block = self.parse_block_statement();
        
        // Validate that all statements in the block are 'show' statements
        for stmt in &block {
            if !matches!(stmt, Statement::ShowStatement { .. }) {
                self.errors.push(format!(
                    "Only 'show' statements are allowed inside 'load' blocks at line {}, column {}",
                    self.current_token.line, self.current_token.column
                ));
                break;
            }
        }
        
        Some(Statement::LoadStatement { cycles, block })
    }
    
    fn parse_is_statement(&mut self) -> Option<Statement> {
        // 'is' is a comparison operator that works similar to '==' but can be used as a statement
        // Example: is x 5 (checks if x equals 5)
        
        self.next_token(); // Move past 'is' to the identifier

        if !self.current_token_is(TokenType::Identifier) {
            self.errors.push(format!("Expected identifier after 'is' at line {}, column {}", 
                self.current_token.line, self.current_token.column));
            return None;
        }
        
        let name = self.current_token.literal.clone();
        self.next_token(); // Move to the value
        
        let value = self.parse_expression(Precedence::Lowest)?;
        
        // Create an expression that compares name == value
        let left = Expression::Identifier(name);
        let operator = String::from("==");
        let right = value;
        
        let condition = Expression::InfixExpression {
            left: Box::new(left),
            operator,
            right: Box::new(right),
        };
        
        // Parse the block if there's a brace
        let consequence = if self.peek_token_is(TokenType::LeftBrace) {
            self.next_token(); // Move to '{'
            self.parse_block_statement()
        } else {
            Vec::new()
        };
        
        // Check for else block
        let alternative = if self.peek_token_is(TokenType::Else) {
            self.next_token(); // Move to 'else'
            
            if !self.expect_peek(TokenType::LeftBrace) {
                return None;
            }
            
            Some(self.parse_block_statement())
        } else {
            None
        };
        
        // This is effectively an if statement with a different syntax
        Some(Statement::IfStatement {
            condition,
            consequence,
            alternative,
        })
    }
    
    fn parse_when_statement(&mut self) -> Option<Statement> {
        // 'when' is a pattern matching statement, similar to a switch/case
        // Example: when x { 1 => { ... }, 2 => { ... }, _ => { ... } }
        
        self.next_token(); // Move past 'when' to the expression
        
        let value = self.parse_expression(Precedence::Lowest)?;
        
        if !self.expect_peek(TokenType::LeftBrace) {
            return None;
        }
        
        // TODO: Implement pattern matching statements
        // For now, we'll just parse a block and return it directly
        let block = self.parse_block_statement();
        
        // Return a simple block statement until pattern matching is implemented
        Some(Statement::BlockStatement {
            statements: block,
        })
    }
    
    fn parse_else_statement(&mut self) -> Option<Statement> {
        // 'else' should only appear after an 'if' statement
        // This is a syntax error if it appears standalone
        
        self.errors.push(format!("Unexpected 'else' statement without matching 'if' at line {}, column {}",
            self.current_token.line, self.current_token.column));
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_variable_declaration() {
        let input = "let x = 5;";
        let lexer = Lexer::new(input.to_string());
        let mut parser = Parser::new(lexer);
        
        let program = parser.parse_program();
        
        assert_eq!(parser.get_errors().len(), 0, "Parser errors: {:?}", parser.get_errors());
        assert_eq!(program.statements.len(), 1);
        
        match &program.statements[0] {
            Statement::VariableDeclaration { var_type, name, value } => {
                assert_eq!(var_type, "let");
                assert_eq!(name, "x");
                
                match value {
                    Some(Expression::NumberLiteral(val)) => assert_eq!(*val, 5.0),
                    _ => panic!("Expected NumberLiteral, got {:?}", value),
                }
            },
            _ => panic!("Expected VariableDeclaration, got {:?}", program.statements[0]),
        }
    }
    
    #[test]
    fn test_function_declaration() {
        let input = "fun add(x, y) { return x + y; }";
        let lexer = Lexer::new(input.to_string());
        let mut parser = Parser::new(lexer);
        
        let program = parser.parse_program();
        
        assert_eq!(parser.get_errors().len(), 0, "Parser errors: {:?}", parser.get_errors());
        assert_eq!(program.statements.len(), 1);
        
        match &program.statements[0] {
            Statement::FunctionDeclaration { name, parameters, body } => {
                assert_eq!(name, "add");
                assert_eq!(parameters, &vec!["x".to_string(), "y".to_string()]);
                assert_eq!(body.len(), 1);
                
                match &body[0] {
                    Statement::ReturnStatement { value } => {
                        match value {
                            Some(Expression::InfixExpression { left, operator, right }) => {
                                match **left {
                                    Expression::Identifier(ref id) => assert_eq!(id, "x"),
                                    _ => panic!("Expected Identifier, got {:?}", left),
                                }
                                
                                assert_eq!(operator, "+");
                                
                                match **right {
                                    Expression::Identifier(ref id) => assert_eq!(id, "y"),
                                    _ => panic!("Expected Identifier, got {:?}", right),
                                }
                            },
                            _ => panic!("Expected InfixExpression, got {:?}", value),
                        }
                    },
                    _ => panic!("Expected ReturnStatement, got {:?}", body[0]),
                }
            },
            _ => panic!("Expected FunctionDeclaration, got {:?}", program.statements[0]),
        }
    }
}