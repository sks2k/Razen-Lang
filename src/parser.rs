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
            TokenType::Let | TokenType::Take | TokenType::Hold | TokenType::Put => self.parse_variable_declaration(),
            TokenType::Fun => self.parse_function_declaration(),
            TokenType::Return => self.parse_return_statement(),
            TokenType::If => self.parse_if_statement(),
            TokenType::While => self.parse_while_statement(),
            TokenType::For => self.parse_for_statement(),
            TokenType::Break => self.parse_break_statement(),
            TokenType::Continue => self.parse_continue_statement(),
            TokenType::Show => self.parse_show_statement(),
            TokenType::Read => self.parse_read_statement(),
            TokenType::Exit => self.parse_exit_statement(),
            TokenType::Try => self.parse_try_statement(),
            TokenType::Throw => self.parse_throw_statement(),
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
        Some(Expression::Identifier(self.current_token.literal.clone()))
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
        
        Some(Expression::IndexExpression {
            left: Box::new(left),
            index: Box::new(index),
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
            _ => Precedence::Lowest,
        }
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