use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum TokenType {
    // Variable declaration keywords
    Let,    // Integer, Float, Number
    Take,   // String, Text
    Hold,   // Boolean
    Put,    // Any
    Sum,    // Numeric sum (alias for let)
    
    // Mathematical Variable Keywords
    Diff,   // Difference (subtraction)
    Prod,   // Product (multiplication)
    Div,    // Division
    Mod,    // Modulus/Remainder
    
    // String Variables
    Text,   // String data storage
    Concat, // String joining
    Slice,  // Substring extraction
    Len,    // String length
    
    // List & Array Variables
    List,   // Dynamic arrays
    Arr,    // Fixed-size arrays
    Append, // Add elements to lists
    Remove, // Remove elements from lists
    
    // Dictionary/Map Variables
    Map,    // Key-value storage
    Key,    // Dictionary keys
    Value,  // Dictionary values
    
    // Date & Time Variables
    Current, // Current date/time
    Now,     // Current timestamp
    Year,    // Year component
    Month,   // Month component
    Day,     // Day component
    Hour,    // Hour component
    Minute,  // Minute component
    Second,  // Second component
    
    // User-Defined Variables
    Store,  // Persistent storage
    Box,    // Temporary storage
    Ref,    // Reference variables
    
    // Logical Variables
    Is,     // Equality comparison
    When,   // Pattern matching
    
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
    Load,    // Loading animation
    
    // Boolean literals
    True,
    False,
    Null,
    
    // Document Type Declaration
    DocumentType,  // type declaration (script, cli)
    
    // Module system
    Use,           // use module imports
    Export,        // export module items
    As,            // namespace alias
    From,          // module source
    
    // Debug and developer tools
    Debug,         // debug mode
    Assert,        // assertions
    Trace,         // execution tracing
    
    // 12 - OOP Keywords
    Class,         // class declaration
    
    // 13 - API Keywords
    Api,           // API declaration
    Call,          // API calls
    Get,           // API responses
    Post,          // API requests
    Await,         // For async operations
    
    // 14 - Connection Keywords
    Connect,       // connecting to external services
    To,            // for export destination
    
    // 15 - Import/Export Keywords
    Import,        // importing modules
    
    // 16 - Library Keywords
    Lib,           // libraries
    Random,        // random number generation
    Ht,            // head and tails
    Coin,          // coin toss
    Math,          // math operations
    Ping,          // website ping
    Bolt,          // performance optimization
    Seed,          // seed generation
    Net,           // network operations
    File,          // file operations
    Json,          // JSON operations
    Date,          // date and time operations
    String,        // string utilities
    Array,         // array utilities
    Os,            // operating system info
    Regex,         // regular expressions
    Crypto,        // cryptography
    Color,         // color manipulation
    System,        // system commands
    Ui,            // user interface
    Storage,       // persistent storage
    Audio,         // audio operations
    Image,         // image processing
    Validation,    // data validation
    Log,           // logging utilities
    Uuid,          // UUID generation
    
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
            TokenType::Sum => write!(f, "SUM"),
            
            // Mathematical Variable Keywords
            TokenType::Diff => write!(f, "DIFF"),
            TokenType::Prod => write!(f, "PROD"),
            TokenType::Div => write!(f, "DIV"),
            TokenType::Mod => write!(f, "MOD"),
            
            // String Variables
            TokenType::Text => write!(f, "TEXT"),
            TokenType::Concat => write!(f, "CONCAT"),
            TokenType::Slice => write!(f, "SLICE"),
            TokenType::Len => write!(f, "LEN"),
            
            // List & Array Variables
            TokenType::List => write!(f, "LIST"),
            TokenType::Arr => write!(f, "ARR"),
            TokenType::Append => write!(f, "APPEND"),
            TokenType::Remove => write!(f, "REMOVE"),
            
            // Dictionary/Map Variables
            TokenType::Map => write!(f, "MAP"),
            TokenType::Key => write!(f, "KEY"),
            TokenType::Value => write!(f, "VALUE"),
            
            // Date & Time Variables
            TokenType::Current => write!(f, "CURRENT"),
            TokenType::Now => write!(f, "NOW"),
            TokenType::Year => write!(f, "YEAR"),
            TokenType::Month => write!(f, "MONTH"),
            TokenType::Day => write!(f, "DAY"),
            TokenType::Hour => write!(f, "HOUR"),
            TokenType::Minute => write!(f, "MINUTE"),
            TokenType::Second => write!(f, "SECOND"),
            
            // User-Defined Variables
            TokenType::Store => write!(f, "STORE"),
            TokenType::Box => write!(f, "BOX"),
            TokenType::Ref => write!(f, "REF"),
            
            // Logical Variables
            TokenType::Is => write!(f, "IS"),
            TokenType::When => write!(f, "WHEN"),
            
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
            TokenType::Load => write!(f, "LOAD"),
            
            // Boolean literals
            TokenType::True => write!(f, "TRUE"),
            TokenType::False => write!(f, "FALSE"),
            TokenType::Null => write!(f, "NULL"),
            
            // Document Type Declaration
            TokenType::DocumentType => write!(f, "TYPE"),
            
            // Module system
            TokenType::Use => write!(f, "USE"),
            TokenType::Export => write!(f, "EXPORT"),
            TokenType::As => write!(f, "AS"),
            TokenType::From => write!(f, "FROM"),
            
            // Debug and developer tools
            TokenType::Debug => write!(f, "DEBUG"),
            TokenType::Assert => write!(f, "ASSERT"),
            TokenType::Trace => write!(f, "TRACE"),
            
            // OOP Keywords
            TokenType::Class => write!(f, "CLASS"),
            
            // API Keywords
            TokenType::Api => write!(f, "API"),
            TokenType::Call => write!(f, "CALL"),
            TokenType::Get => write!(f, "GET"),
            TokenType::Post => write!(f, "POST"),
            TokenType::Await => write!(f, "AWAIT"),
            
            // Connection Keywords
            TokenType::Connect => write!(f, "CONNECT"),
            TokenType::To => write!(f, "TO"),
            
            // Import/Export Keywords
            TokenType::Import => write!(f, "IMPORT"),
            
            // Library Keywords
            TokenType::Lib => write!(f, "LIB"),
            TokenType::Random => write!(f, "RANDOM"),
            TokenType::Ht => write!(f, "HT"),
            TokenType::Coin => write!(f, "COIN"),
            TokenType::Math => write!(f, "MATH"),
            TokenType::Ping => write!(f, "PING"),
            TokenType::Bolt => write!(f, "BOLT"),
            TokenType::Seed => write!(f, "SEED"),
            TokenType::Net => write!(f, "NET"),
            TokenType::File => write!(f, "FILE"),
            TokenType::Json => write!(f, "JSON"),
            TokenType::Date => write!(f, "DATE"),
            TokenType::String => write!(f, "STRING"),
            TokenType::Array => write!(f, "ARRAY"),
            TokenType::Os => write!(f, "OS"),
            TokenType::Regex => write!(f, "REGEX"),
            TokenType::Crypto => write!(f, "CRYPTO"),
            TokenType::Color => write!(f, "COLOR"),
            TokenType::System => write!(f, "SYSTEM"),
            TokenType::Ui => write!(f, "UI"),
            TokenType::Storage => write!(f, "STORAGE"),
            TokenType::Audio => write!(f, "AUDIO"),
            TokenType::Image => write!(f, "IMAGE"),
            TokenType::Validation => write!(f, "VALIDATION"),
            TokenType::Log => write!(f, "LOG"),
            TokenType::Uuid => write!(f, "UUID"),
            
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
        "sum" => TokenType::Sum,
        
        // Mathematical Variable Keywords
        "diff" => TokenType::Diff,
        "prod" => TokenType::Prod,
        "div" => TokenType::Div,
        "mod" => TokenType::Mod,
        
        // String Variables
        "text" => TokenType::Text,
        "concat" => TokenType::Concat,
        "slice" => TokenType::Slice,
        "len" => TokenType::Len,
        
        // List & Array Variables
        "list" => TokenType::List,
        "arr" => TokenType::Arr,
        "append" => TokenType::Append,
        "remove" => TokenType::Remove,
        
        // Dictionary/Map Variables
        "map" => TokenType::Map,
        "key" => TokenType::Key,
        "value" => TokenType::Value,
        
        // Date & Time Variables
        "current" => TokenType::Current,
        "now" => TokenType::Now,
        "year" => TokenType::Year,
        "month" => TokenType::Month,
        "day" => TokenType::Day,
        "hour" => TokenType::Hour,
        "minute" => TokenType::Minute,
        "second" => TokenType::Second,
        
        // User-Defined Variables
        "store" => TokenType::Store,
        "box" => TokenType::Box,
        "ref" => TokenType::Ref,
        
        // Logical Variables
        "is" => TokenType::Is,
        "when" => TokenType::When,
        
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
        "load" => TokenType::Load,
        
        // Boolean literals
        "true" => TokenType::True,
        "false" => TokenType::False,
        "null" => TokenType::Null,
        
        // Document Type Declaration
        "type" => TokenType::DocumentType,
        
        // Module system
        "use" => TokenType::Use,
        "export" => TokenType::Export,
        "as" => TokenType::As,
        "from" => TokenType::From,
        
        // Debug and developer tools
        "debug" => TokenType::Debug,
        "assert" => TokenType::Assert,
        "trace" => TokenType::Trace,
        
        // OOP Keywords (Section 12)
        "class" => TokenType::Class,
        
        // API Keywords (Section 13)
        "api" => TokenType::Api,
        "call" => TokenType::Call,
        "get" => TokenType::Get,
        "post" => TokenType::Post,
        "await" => TokenType::Await,
        
        // Connection Keywords (Section 14)
        "connect" => TokenType::Connect,
        "to" => TokenType::To,
        
        // Import/Export Keywords (Section 15)
        "import" => TokenType::Import,
        
        // Library Keywords (Section 16)
        "lib" => TokenType::Lib,
        "random" => TokenType::Random,
        "ht" => TokenType::Ht,
        "coin" => TokenType::Coin,
        "math" => TokenType::Math,
        "ping" => TokenType::Ping,
        "bolt" => TokenType::Bolt,
        "seed" => TokenType::Seed,
        "net" => TokenType::Net,
        "file" => TokenType::File,
        "json" => TokenType::Json,
        "date" => TokenType::Date,
        "string" => TokenType::String,
        "array" => TokenType::Array,
        "os" => TokenType::Os,
        "regex" => TokenType::Regex,
        "crypto" => TokenType::Crypto,
        "color" => TokenType::Color,
        "system" => TokenType::System,
        "ui" => TokenType::Ui,
        "storage" => TokenType::Storage,
        "audio" => TokenType::Audio,
        "image" => TokenType::Image,
        "validation" => TokenType::Validation,
        "log" => TokenType::Log,
        "uuid" => TokenType::Uuid,
        
        // If not a keyword, it's an identifier
        _ => TokenType::Identifier,
    }
}