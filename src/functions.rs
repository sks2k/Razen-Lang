// Import modules from the functions directory
mod array;
mod string;
mod math;
mod time;
mod random;
mod file;
mod json;
mod net;
mod bolt;
mod seed;
mod color;
mod crypto;
mod regex;
mod uuid;
mod os;
mod validation;
mod system;

// Re-export common utilities and types
use crate::value::Value;

// Library function modules for external use
pub mod arrlib {
    pub use super::array::*;
}

pub mod strlib {
    pub use super::string::*;
}

pub mod mathlib {
    pub use super::math::*;
}

pub mod timelib {
    pub use super::time::*;
}

pub mod randomlib {
    pub use super::random::*;
}

pub mod filelib {
    pub use super::file::*;
}

pub mod jsonlib {
    pub use super::json::*;
}

pub mod netlib {
    pub use super::net::*;
}

pub mod boltlib {
    pub use super::bolt::*;
}

pub mod seedlib {
    pub use super::seed::*;
}

pub mod colorlib {
    pub use super::color::*;
}

pub mod cryptolib {
    pub use super::crypto::*;
}

pub mod regexlib {
    pub use super::regex::*;
}

pub mod uuidlib {
    pub use super::uuid::*;
}

pub mod oslib {
    pub use super::os::*;
}

pub mod validationlib {
    pub use super::validation::*;
}

pub mod systemlib {
    pub use super::system::*;
}