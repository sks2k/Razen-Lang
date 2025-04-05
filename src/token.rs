use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum TokenType {
    // Variable declaration keywords
    Let,    // Integer, Float, Number
    Take,   // String, Text
    Hold,   // Boolean
    Put,    // Any
    
    // Mathematical operators
    Plus,       // +
    Minus,      // -
    Asterisk,   // *
    Slash,      // /
    Percent,    // %
    Power,      // **
    FloorDiv,   // //
    
    // Assignment operators
    Assign,         // =
    PlusAssign,     // +=
    MinusAssign,    // -=
    AsteriskAssign, // *=
    SlashAssign,    // /=
    PercentAssign,  // %=
    
    // Comparison operators
    Equal,      // ==
    NotEqual,   // !=
    Greater,    // >
    GreaterEqual, // >=
    Less,       // <
    LessEqual,  // <=
    
    // Logical operators
    And,    // &&
    Or,     // ||
    Not,    // !
    
    // Control flow keywords
    If,
    Else,
    Elif,
    While,
    For,
    In,
    Break,
    Continue,
    Return,
    
    // Function declaration
    Fun,
    
    // Exception handling
    Try,
    Catch,
    Throw,
    Finally,
    
    // I/O keywords
    Show,
    Read,
    Exit,
    
    // Boolean literals
    True,
    False,
    Null,
    
    // Document Type Declaration
    DocumentType,  // type declaration (web, script, cli)
    
    // Document Structure
    Webpage,    // root element for web documents
    Top,        // container for metadata
    Bottom,     // container for visible content
    
    // Web-specific tokens - Element Access
    Find,       // find element by ID
    Search,     // search element by selector
    FindAll,    // find all elements matching selector
    
    // Web-specific tokens - Content Manipulation
    Insert,     // set/get inner content with markup
    Write,      // set/get text-only content
    Property,   // set/get attribute
    Look,       // set/get style
    Type,       // type manipulation (replaces class)
    Add,        // add type
    Remove,     // remove type
    Toggle,     // toggle type
    Contains,   // check if element has type
    
    // Web-specific tokens - Interaction Handling
    When,       // add event listener
    Stop,       // remove event listener
    Simulate,   // trigger event
    
    // Web-specific tokens - Form Processing
    EntryForm,  // form selector
    Check,      // form validation
    Send,       // form submission
    
    // Web-specific tokens - Data Communication
    Request,    // fetch request
    SendData,   // post request
    GetData,    // get request
    
    // Web-specific tokens - Data Storage
    Save,       // localStorage
    Keep,       // sessionStorage
    Remember,   // cookie management
    
    // Web-specific tokens - Utility Functions
    Pause,      // setTimeout
    Repeat,     // setInterval
    Stop,       // clear interval/timeout
    Adjust,     // window resize
    Goto,       // page navigation
    Refresh,    // page reload
    
    // Delimiters
    LeftParen,      // (
    RightParen,     // )
    LeftBrace,      // {
    RightBrace,     // }
    LeftBracket,    // [
    RightBracket,   // ]
    Comma,          // ,
    Dot,            // .
    Semicolon,      // ;
    Colon,          // :
    
    // Literals
    Identifier,     // Variable names, function names, etc.
    StringLiteral,  // "hello"
    NumberLiteral,  // 123, 3.14
    
    // Comments
    Comment,        // # Comment
    
    // Special
    EOF,            // End of file
    Illegal,        // Invalid token
}

impl fmt::Display for TokenType {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            // Variable declaration keywords
            TokenType::Let => write!(f, "LET"),
            TokenType::Take => write!(f, "TAKE"),
            TokenType::Hold => write!(f, "HOLD"),
            TokenType::Put => write!(f, "PUT"),
            
            // Mathematical operators
            TokenType::Plus => write!(f, "+"),
            TokenType::Minus => write!(f, "-"),
            TokenType::Asterisk => write!(f, "*"),
            TokenType::Slash => write!(f, "/"),
            TokenType::Percent => write!(f, "%"),
            TokenType::Power => write!(f, "**"),
            TokenType::FloorDiv => write!(f, "//"),
            
            // Assignment operators
            TokenType::Assign => write!(f, "="),
            TokenType::PlusAssign => write!(f, "+="),
            TokenType::MinusAssign => write!(f, "-="),
            TokenType::AsteriskAssign => write!(f, "*="),
            TokenType::SlashAssign => write!(f, "/="),
            TokenType::PercentAssign => write!(f, "%="),
            
            // Comparison operators
            TokenType::Equal => write!(f, "=="),
            TokenType::NotEqual => write!(f, "!="),
            TokenType::Greater => write!(f, ">"),
            TokenType::GreaterEqual => write!(f, ">="),
            TokenType::Less => write!(f, "<"),
            TokenType::LessEqual => write!(f, "<="),
            
            // Logical operators
            TokenType::And => write!(f, "&&"),
            TokenType::Or => write!(f, "||"),
            TokenType::Not => write!(f, "!"),
            
            // Control flow keywords
            TokenType::If => write!(f, "IF"),
            TokenType::Else => write!(f, "ELSE"),
            TokenType::Elif => write!(f, "ELIF"),
            TokenType::While => write!(f, "WHILE"),
            TokenType::For => write!(f, "FOR"),
            TokenType::In => write!(f, "IN"),
            TokenType::Break => write!(f, "BREAK"),
            TokenType::Continue => write!(f, "CONTINUE"),
            TokenType::Return => write!(f, "RETURN"),
            
            // Function declaration
            TokenType::Fun => write!(f, "FUN"),
            
            // Exception handling
            TokenType::Try => write!(f, "TRY"),
            TokenType::Catch => write!(f, "CATCH"),
            TokenType::Throw => write!(f, "THROW"),
            TokenType::Finally => write!(f, "FINALLY"),
            
            // I/O keywords
            TokenType::Show => write!(f, "SHOW"),
            TokenType::Read => write!(f, "READ"),
            TokenType::Exit => write!(f, "EXIT"),
            
            // Boolean literals
            TokenType::True => write!(f, "TRUE"),
            TokenType::False => write!(f, "FALSE"),
            TokenType::Null => write!(f, "NULL"),
            
            // Web-specific tokens - Element Access
            TokenType::Get => write!(f, "GET"),
            TokenType::Query => write!(f, "QUERY"),
            TokenType::All => write!(f, "ALL"),
            
            // Web-specific tokens - DOM Manipulation
            TokenType::Html => write!(f, "HTML"),
            TokenType::Text => write!(f, "TEXT"),
            TokenType::Attr => write!(f, "ATTR"),
            TokenType::Style => write!(f, "STYLE"),
            TokenType::Class => write!(f, "CLASS"),
            TokenType::Add => write!(f, "ADD"),
            TokenType::Remove => write!(f, "REMOVE"),
            TokenType::Toggle => write!(f, "TOGGLE"),
            TokenType::Contains => write!(f, "CONTAINS"),
            
            // Web-specific tokens - Event Handling
            TokenType::On => write!(f, "ON"),
            TokenType::Off => write!(f, "OFF"),
            TokenType::Trigger => write!(f, "TRIGGER"),
            
            // Web-specific tokens - Form Handling
            TokenType::Form => write!(f, "FORM"),
            TokenType::Validate => write!(f, "VALIDATE"),
            TokenType::Submit => write!(f, "SUBMIT"),
            
            // Web-specific tokens - AJAX and Fetch
            TokenType::Fetch => write!(f, "FETCH"),
            TokenType::Post => write!(f, "POST"),
            TokenType::GetData => write!(f, "GET_DATA"),
            
            // Web-specific tokens - Storage
            TokenType::StoreLocal => write!(f, "STORE_LOCAL"),
            TokenType::StoreSession => write!(f, "STORE_SESSION"),
            TokenType::Cookie => write!(f, "COOKIE"),
            
            // Web-specific tokens - Utility
            TokenType::Wait => write!(f, "WAIT"),
            TokenType::Interval => write!(f, "INTERVAL"),
            TokenType::Clear => write!(f, "CLEAR"),
            TokenType::Resize => write!(f, "RESIZE"),
            TokenType::Redirect => write!(f, "REDIRECT"),
            TokenType::Reload => write!(f, "RELOAD"),
            
            // Delimiters
            TokenType::LeftParen => write!(f, "("),
            TokenType::RightParen => write!(f, ")"),
            TokenType::LeftBrace => write!(f, "{{"),
            TokenType::RightBrace => write!(f, "}}"),
            TokenType::LeftBracket => write!(f, "["),
            TokenType::RightBracket => write!(f, "]"),
            TokenType::Comma => write!(f, ","),
            TokenType::Dot => write!(f, "."),
            TokenType::Semicolon => write!(f, ";"),
            TokenType::Colon => write!(f, ":"),
            
            // Literals
            TokenType::Identifier => write!(f, "IDENTIFIER"),
            TokenType::StringLiteral => write!(f, "STRING"),
            TokenType::NumberLiteral => write!(f, "NUMBER"),
            
            // Comments
            TokenType::Comment => write!(f, "COMMENT"),
            
            // Special
            TokenType::EOF => write!(f, "EOF"),
            TokenType::Illegal => write!(f, "ILLEGAL"),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Token {
    pub token_type: TokenType,
    pub literal: String,
    pub line: usize,
    pub column: usize,
}

impl Token {
    pub fn new(token_type: TokenType, literal: impl Into<String>, line: usize, column: usize) -> Self {
        Token {
            token_type,
            literal: literal.into(),
            line,
            column,
        }
    }
}

impl fmt::Display for Token {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}:'{}' at {}:{}", self.token_type, self.literal, self.line, self.column)
    }
}

// Helper function to lookup keywords
pub fn lookup_identifier(identifier: &str) -> TokenType {
    match identifier {
        // Variable declaration keywords
        "let" => TokenType::Let,
        "take" => TokenType::Take,
        "hold" => TokenType::Hold,
        "put" => TokenType::Put,
        
        // Control flow keywords
        "if" => TokenType::If,
        "else" => TokenType::Else,
        "elif" => TokenType::Elif,
        "while" => TokenType::While,
        "for" => TokenType::For,
        "in" => TokenType::In,
        "break" => TokenType::Break,
        "continue" => TokenType::Continue,
        "return" => TokenType::Return,
        
        // Function declaration
        "fun" => TokenType::Fun,
        
        // Exception handling
        "try" => TokenType::Try,
        "catch" => TokenType::Catch,
        "throw" => TokenType::Throw,
        "finally" => TokenType::Finally,
        
        // I/O keywords
        "show" => TokenType::Show,
        "read" => TokenType::Read,
        "exit" => TokenType::Exit,
        
        // Boolean literals
        "true" => TokenType::True,
        "false" => TokenType::False,
        "null" => TokenType::Null,
        
        // Document Type Declaration
        "type" => TokenType::DocumentType,
        
        // Document Structure
        "webpage" => TokenType::Webpage,
        "top" => TokenType::Top,
        "bottom" => TokenType::Bottom,
        
        // Web-specific tokens - Element Access
        "find" => TokenType::Find,
        "search" => TokenType::Search,
        "findall" => TokenType::FindAll,
        
        // Web-specific tokens - Content Manipulation
        "insert" => TokenType::Insert,
        "write" => TokenType::Write,
        "property" => TokenType::Property,
        "look" => TokenType::Look,
        "elemtype" => TokenType::Type,  // renamed from 'type' to avoid conflict
        "add" => TokenType::Add,
        "remove" => TokenType::Remove,
        "toggle" => TokenType::Toggle,
        "contains" => TokenType::Contains,
        
        // Web-specific tokens - Interaction Handling
        "when" => TokenType::When,
        "stop" => TokenType::Stop,
        "simulate" => TokenType::Simulate,
        
        // Web-specific tokens - Form Processing
        "entryform" => TokenType::EntryForm,
        "check" => TokenType::Check,
        "send" => TokenType::Send,
        
        // Web-specific tokens - Data Communication
        "request" => TokenType::Request,
        "senddata" => TokenType::SendData,
        "getdata" => TokenType::GetData,
        
        // Web-specific tokens - Data Storage
        "save" => TokenType::Save,
        "keep" => TokenType::Keep,
        "remember" => TokenType::Remember,
        
        // Web-specific tokens - Utility Functions
        "pause" => TokenType::Pause,
        "repeat" => TokenType::Repeat,
        "adjust" => TokenType::Adjust,
        "goto" => TokenType::Goto,
        "refresh" => TokenType::Refresh,
        
        // If not a keyword, it's an identifier
        _ => TokenType::Identifier,
    }
}