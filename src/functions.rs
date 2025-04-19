use std::collections::HashMap;
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};
use std::thread;
use std::time::Duration;
use rand::Rng;
use crate::value::Value;

// Array library functions
pub mod arrlib {
    use super::*;

    pub fn push(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("ArrLib[push] requires exactly 2 arguments: array and value".to_string());
        }
        
        let mut array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("First argument to push must be an array, got {:?}", args[0])),
        };
        
        array.push(args[1].clone());
        
        Ok(Value::Array(array))
    }

    pub fn pop(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("ArrLib[pop] requires exactly 1 argument: array".to_string());
        }
        
        let mut array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("Argument to pop must be an array, got {:?}", args[0])),
        };
        
        if array.is_empty() {
            return Err("Cannot pop from empty array".to_string());
        }
        
        let popped = array.pop().unwrap();
        
        Ok(popped)
    }

    pub fn join(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("ArrLib[join] requires exactly 2 arguments: array and separator".to_string());
        }
        
        let array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("First argument to join must be an array, got {:?}", args[0])),
        };
        
        let separator = args[1].as_string()?;
        
        let strings: Result<Vec<String>, String> = array.iter()
            .map(|v| v.as_string())
            .collect();
            
        match strings {
            Ok(s) => Ok(Value::String(s.join(&separator))),
            Err(e) => Err(e),
        }
    }

    pub fn length(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("ArrLib[length] requires exactly 1 argument: array".to_string());
        }
        
        let array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("Argument to length must be an array, got {:?}", args[0])),
        };
        
        Ok(Value::Int(array.len() as i64))
    }

    pub fn map(_args: Vec<Value>) -> Result<Value, String> {
        // This would require function values which are not yet implemented
        Err("ArrLib[map] is not yet implemented".to_string())
    }

    pub fn filter(_args: Vec<Value>) -> Result<Value, String> {
        // This would require function values which are not yet implemented
        Err("ArrLib[filter] is not yet implemented".to_string())
    }

    pub fn unique(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("ArrLib[unique] requires exactly 1 argument: array".to_string());
        }
        
        let array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("Argument to unique must be an array, got {:?}", args[0])),
        };
        
        let mut result = Vec::new();
        
        for item in array {
            if !result.contains(&item) {
                result.push(item);
            }
        }
        
        Ok(Value::Array(result))
    }
}

// String library functions
pub mod strlib {
    use super::*;

    pub fn upper(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("StrLib[upper] requires exactly 1 argument: string".to_string());
        }
        
        let string = args[0].as_string()?;
        
        Ok(Value::String(string.to_uppercase()))
    }

    pub fn lower(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("StrLib[lower] requires exactly 1 argument: string".to_string());
        }
        
        let string = args[0].as_string()?;
        
        Ok(Value::String(string.to_lowercase()))
    }

    pub fn substring(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 3 {
            return Err("StrLib[substring] requires exactly 3 arguments: string, start, end".to_string());
        }
        
        let string = args[0].as_string()?;
        let start = args[1].as_int()? as usize;
        let end = args[2].as_int()? as usize;
        
        if start > end || end > string.len() {
            return Err(format!("Invalid substring range: start={}, end={}, length={}", start, end, string.len()));
        }
        
        Ok(Value::String(string[start..end].to_string()))
    }

    pub fn replace(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 3 {
            return Err("StrLib[replace] requires exactly 3 arguments: string, pattern, replacement".to_string());
        }
        
        let string = args[0].as_string()?;
        let pattern = args[1].as_string()?;
        let replacement = args[2].as_string()?;
        
        Ok(Value::String(string.replace(&pattern, &replacement)))
    }

    pub fn length(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("StrLib[length] requires exactly 1 argument: string".to_string());
        }
        
        let string = args[0].as_string()?;
        
        Ok(Value::Int(string.len() as i64))
    }

    pub fn split(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("StrLib[split] requires exactly 2 arguments: string, separator".to_string());
        }
        
        let string = args[0].as_string()?;
        let separator = args[1].as_string()?;
        
        let parts: Vec<Value> = string.split(&separator)
            .map(|s| Value::String(s.to_string()))
            .collect();
            
        Ok(Value::Array(parts))
    }

    pub fn trim(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("StrLib[trim] requires exactly 1 argument: string".to_string());
        }
        
        let string = args[0].as_string()?;
        
        Ok(Value::String(string.trim().to_string()))
    }

    pub fn starts_with(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("StrLib[starts_with] requires exactly 2 arguments: string, prefix".to_string());
        }
        
        let string = args[0].as_string()?;
        let prefix = args[1].as_string()?;
        
        Ok(Value::Bool(string.starts_with(&prefix)))
    }

    pub fn ends_with(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("StrLib[ends_with] requires exactly 2 arguments: string, suffix".to_string());
        }
        
        let string = args[0].as_string()?;
        let suffix = args[1].as_string()?;
        
        Ok(Value::Bool(string.ends_with(&suffix)))
    }

    pub fn contains(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("StrLib[contains] requires exactly 2 arguments: string, substring".to_string());
        }
        
        let string = args[0].as_string()?;
        let substring = args[1].as_string()?;
        
        Ok(Value::Bool(string.contains(&substring)))
    }

    pub fn repeat(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("StrLib[repeat] requires exactly 2 arguments: string, count".to_string());
        }
        
        let string = args[0].as_string()?;
        let count = args[1].as_int()? as usize;
        
        Ok(Value::String(string.repeat(count)))
    }
}

// Math library functions
pub mod mathlib {
    use super::*;

    pub fn add(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[add] requires exactly 2 arguments: a, b".to_string());
        }
        
        let a = args[0].as_float()?;
        let b = args[1].as_float()?;
        
        Ok(Value::Float(a + b))
    }

    pub fn subtract(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[subtract] requires exactly 2 arguments: a, b".to_string());
        }
        
        let a = args[0].as_float()?;
        let b = args[1].as_float()?;
        
        Ok(Value::Float(a - b))
    }

    pub fn multiply(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[multiply] requires exactly 2 arguments: a, b".to_string());
        }
        
        let a = args[0].as_float()?;
        let b = args[1].as_float()?;
        
        Ok(Value::Float(a * b))
    }

    pub fn divide(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[divide] requires exactly 2 arguments: a, b".to_string());
        }
        
        let a = args[0].as_float()?;
        let b = args[1].as_float()?;
        
        if b == 0.0 {
            return Err("Division by zero".to_string());
        }
        
        Ok(Value::Float(a / b))
    }

    pub fn power(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[power] requires exactly 2 arguments: base, exponent".to_string());
        }
        
        let base = args[0].as_float()?;
        let exponent = args[1].as_float()?;
        
        Ok(Value::Float(base.powf(exponent)))
    }

    pub fn sqrt(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[sqrt] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        if value < 0.0 {
            return Err("Cannot compute square root of negative number".to_string());
        }
        
        Ok(Value::Float(value.sqrt()))
    }

    pub fn abs(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[abs] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        Ok(Value::Float(value.abs()))
    }

    pub fn round(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[round] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        Ok(Value::Float(value.round()))
    }

    pub fn floor(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[floor] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        Ok(Value::Float(value.floor()))
    }

    pub fn ceil(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[ceil] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        Ok(Value::Float(value.ceil()))
    }

    pub fn sin(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[sin] requires exactly 1 argument: angle".to_string());
        }
        
        let angle = args[0].as_float()?;
        
        Ok(Value::Float(angle.sin()))
    }

    pub fn cos(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[cos] requires exactly 1 argument: angle".to_string());
        }
        
        let angle = args[0].as_float()?;
        
        Ok(Value::Float(angle.cos()))
    }

    pub fn tan(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[tan] requires exactly 1 argument: angle".to_string());
        }
        
        let angle = args[0].as_float()?;
        
        Ok(Value::Float(angle.tan()))
    }

    pub fn log(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[log] requires exactly 2 arguments: value, base".to_string());
        }
        
        let value = args[0].as_float()?;
        let base = args[1].as_float()?;
        
        if value <= 0.0 || base <= 0.0 || base == 1.0 {
            return Err("Invalid arguments for logarithm".to_string());
        }
        
        Ok(Value::Float(value.log(base)))
    }

    pub fn exp(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("MathLib[exp] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].as_float()?;
        
        Ok(Value::Float(value.exp()))
    }

    pub fn random(args: Vec<Value>) -> Result<Value, String> {
        if !args.is_empty() {
            return Err("MathLib[random] takes no arguments".to_string());
        }
        
        use rand::Rng;
        let mut rng = rand::thread_rng();
        
        Ok(Value::Float(rng.gen_range(0.0..1.0)))
    }

    pub fn max(args: Vec<Value>) -> Result<Value, String> {
        if args.len() < 2 {
            return Err("MathLib[max] requires at least 2 arguments".to_string());
        }
        
        let mut max_value = args[0].as_float()?;
        
        for i in 1..args.len() {
            let value = args[i].as_float()?;
            if value > max_value {
                max_value = value;
            }
        }
        
        Ok(Value::Float(max_value))
    }

    pub fn min(args: Vec<Value>) -> Result<Value, String> {
        if args.len() < 2 {
            return Err("MathLib[min] requires at least 2 arguments".to_string());
        }
        
        let mut min_value = args[0].as_float()?;
        
        for i in 1..args.len() {
            let value = args[i].as_float()?;
            if value < min_value {
                min_value = value;
            }
        }
        
        Ok(Value::Float(min_value))
    }

    pub fn modulo(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("MathLib[modulo] requires exactly 2 arguments: a, b".to_string());
        }
        
        let a = args[0].as_float()?;
        let b = args[1].as_float()?;
        
        if b == 0.0 {
            return Err("Modulo by zero".to_string());
        }
        
        Ok(Value::Float(a % b))
    }
}

// Time library functions
pub mod timelib {
    use super::*;
    use chrono::{DateTime, Utc, Local, TimeZone, NaiveDateTime, Datelike};

    pub fn now(args: Vec<Value>) -> Result<Value, String> {
        if !args.is_empty() {
            return Err("TimeLib[now] takes no arguments".to_string());
        }
        
        let now = SystemTime::now();
        match now.duration_since(UNIX_EPOCH) {
            Ok(duration) => Ok(Value::Int(duration.as_secs() as i64)),
            Err(_) => Err("Failed to get current time".to_string()),
        }
    }

    pub fn format(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("TimeLib[format] requires exactly 2 arguments: timestamp, format_string".to_string());
        }
        
        let timestamp = args[0].as_int()?;
        let format_string = args[1].as_string()?;
        
        let datetime = match Local.timestamp_opt(timestamp, 0) {
            chrono::LocalResult::Single(dt) => dt,
            _ => return Err("Invalid timestamp".to_string()),
        };
        
        Ok(Value::String(datetime.format(&format_string).to_string()))
    }

    pub fn parse(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("TimeLib[parse] requires exactly 2 arguments: date_string, format_string".to_string());
        }
        
        let date_string = args[0].as_string()?;
        let format_string = args[1].as_string()?;
        
        match NaiveDateTime::parse_from_str(&date_string, &format_string) {
            Ok(dt) => {
                let timestamp = dt.timestamp();
                Ok(Value::Int(timestamp))
            },
            Err(_) => Err("Failed to parse date string".to_string()),
        }
    }

    pub fn add(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 3 {
            return Err("TimeLib[add] requires exactly 3 arguments: timestamp, amount, unit".to_string());
        }
        
        let timestamp = args[0].as_int()?;
        let amount = args[1].as_int()?;
        let unit = args[2].as_string()?;
        
        let datetime = match Local.timestamp_opt(timestamp, 0) {
            chrono::LocalResult::Single(dt) => dt,
            _ => return Err("Invalid timestamp".to_string()),
        };
        
        let result = match unit.as_str() {
            "seconds" => datetime + chrono::Duration::seconds(amount),
            "minutes" => datetime + chrono::Duration::minutes(amount),
            "hours" => datetime + chrono::Duration::hours(amount),
            "days" => datetime + chrono::Duration::days(amount),
            "weeks" => datetime + chrono::Duration::weeks(amount),
            _ => return Err(format!("Unknown time unit: {}", unit)),
        };
        
        Ok(Value::Int(result.timestamp()))
    }

    pub fn year(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("TimeLib[year] requires exactly 1 argument: timestamp".to_string());
        }
        
        let timestamp = args[0].as_int()?;
        
        let datetime = match Local.timestamp_opt(timestamp, 0) {
            chrono::LocalResult::Single(dt) => dt,
            _ => return Err("Invalid timestamp".to_string()),
        };
        
        Ok(Value::Int(datetime.year() as i64))
    }

    pub fn month(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("TimeLib[month] requires exactly 1 argument: timestamp".to_string());
        }
        
        let timestamp = args[0].as_int()?;
        
        let datetime = match Local.timestamp_opt(timestamp, 0) {
            chrono::LocalResult::Single(dt) => dt,
            _ => return Err("Invalid timestamp".to_string()),
        };
        
        Ok(Value::Int(datetime.month() as i64))
    }

    pub fn day(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("TimeLib[day] requires exactly 1 argument: timestamp".to_string());
        }
        
        let timestamp = args[0].as_int()?;
        
        let datetime = match Local.timestamp_opt(timestamp, 0) {
            chrono::LocalResult::Single(dt) => dt,
            _ => return Err("Invalid timestamp".to_string()),
        };
        
        Ok(Value::Int(datetime.day() as i64))
    }
}

// Random library functions
pub mod random {
    use super::*;
    use rand::Rng;
    use rand::SeedableRng;
    use rand_chacha::ChaCha8Rng;

    pub fn int(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("Random[int] requires exactly 2 arguments: min, max".to_string());
        }
        
        let min = args[0].as_int()?;
        let max = args[1].as_int()?;
        
        if min > max {
            return Err(format!("Min value {} is greater than max value {}", min, max));
        }
        
        let result = rand::thread_rng().gen_range(min..=max);
        
        Ok(Value::Int(result))
    }

    pub fn float(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("Random[float] requires exactly 2 arguments: min, max".to_string());
        }
        
        let min = args[0].as_float()?;
        let max = args[1].as_float()?;
        
        if min > max {
            return Err(format!("Min value {} is greater than max value {}", min, max));
        }
        
        let result = rand::thread_rng().gen_range(min..=max);
        
        Ok(Value::Float(result))
    }

    pub fn choice(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("Random[choice] requires exactly 1 argument: array".to_string());
        }
        
        let array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("Argument to choice must be an array, got {:?}", args[0])),
        };
        
        if array.is_empty() {
            return Err("Cannot choose from empty array".to_string());
        }
        
        let index = rand::thread_rng().gen_range(0..array.len());
        
        Ok(array[index].clone())
    }

    pub fn shuffle(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("Random[shuffle] requires exactly 1 argument: array".to_string());
        }
        
        let mut array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("Argument to shuffle must be an array, got {:?}", args[0])),
        };
        
        let mut rng = rand::thread_rng();
        for i in (1..array.len()).rev() {
            let j = rng.gen_range(0..=i);
            array.swap(i, j);
        }
        
        Ok(Value::Array(array))
    }
}

// File library functions
pub mod file {
    use super::*;
    use std::fs;
    use std::io::Write;

    pub fn read(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("File[read] requires exactly 1 argument: path".to_string());
        }
        
        let path = args[0].as_string()?;
        
        match fs::read_to_string(path) {
            Ok(content) => Ok(Value::String(content)),
            Err(e) => Err(format!("Failed to read file: {}", e)),
        }
    }

    pub fn write(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("File[write] requires exactly 2 arguments: path, content".to_string());
        }
        
        let path = args[0].as_string()?;
        let content = args[1].as_string()?;
        
        match fs::write(path, content) {
            Ok(_) => Ok(Value::Bool(true)),
            Err(e) => Err(format!("Failed to write file: {}", e)),
        }
    }

    pub fn append(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("File[append] requires exactly 2 arguments: path, content".to_string());
        }
        
        let path = args[0].as_string()?;
        let content = args[1].as_string()?;
        
        match fs::OpenOptions::new().append(true).create(true).open(path) {
            Ok(mut file) => {
                match file.write_all(content.as_bytes()) {
                    Ok(_) => Ok(Value::Bool(true)),
                    Err(e) => Err(format!("Failed to append to file: {}", e)),
                }
            },
            Err(e) => Err(format!("Failed to open file for appending: {}", e)),
        }
    }

    pub fn exists(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("File[exists] requires exactly 1 argument: path".to_string());
        }
        
        let path = args[0].as_string()?;
        
        Ok(Value::Bool(fs::metadata(path).is_ok()))
    }

    pub fn delete(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("File[delete] requires exactly 1 argument: path".to_string());
        }
        
        let path = args[0].as_string()?;
        
        match fs::remove_file(path) {
            Ok(_) => Ok(Value::Bool(true)),
            Err(e) => Err(format!("Failed to delete file: {}", e)),
        }
    }
}

// JSON library functions
pub mod json {
    use super::*;
    use serde_json::{Value as JsonValue, from_str, to_string};

    // Helper function to convert JsonValue to Value
    fn json_to_value(json: JsonValue) -> Value {
        match json {
            JsonValue::Null => Value::Null,
            JsonValue::Bool(b) => Value::Bool(b),
            JsonValue::Number(n) => {
                if n.is_i64() {
                    Value::Int(n.as_i64().unwrap())
                } else {
                    Value::Float(n.as_f64().unwrap())
                }
            },
            JsonValue::String(s) => Value::String(s),
            JsonValue::Array(arr) => {
                let values: Vec<Value> = arr.into_iter()
                    .map(json_to_value)
                    .collect();
                Value::Array(values)
            },
            JsonValue::Object(obj) => {
                let mut map = HashMap::new();
                for (k, v) in obj {
                    map.insert(k, json_to_value(v));
                }
                Value::Map(map)
            },
        }
    }

    // Helper function to convert Value to JsonValue
    fn value_to_json(value: Value) -> Result<JsonValue, String> {
        match value {
            Value::Null => Ok(JsonValue::Null),
            Value::Bool(b) => Ok(JsonValue::Bool(b)),
            Value::Int(i) => Ok(JsonValue::Number(i.into())),
            Value::Float(f) => {
                match serde_json::Number::from_f64(f) {
                    Some(n) => Ok(JsonValue::Number(n)),
                    None => Err(format!("Cannot convert {} to JSON number", f)),
                }
            },
            Value::String(s) => Ok(JsonValue::String(s)),
            Value::Array(arr) => {
                let mut json_arr = Vec::new();
                for item in arr {
                    json_arr.push(value_to_json(item)?);
                }
                Ok(JsonValue::Array(json_arr))
            },
            Value::Map(map) => {
                let mut json_obj = serde_json::Map::new();
                for (k, v) in map {
                    json_obj.insert(k, value_to_json(v)?);
                }
                Ok(JsonValue::Object(json_obj))
            },
        }
    }

    pub fn parse(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("JSON[parse] requires exactly 1 argument: json_string".to_string());
        }
        
        let json_string = args[0].as_string()?;
        
        match from_str::<JsonValue>(&json_string) {
            Ok(json) => Ok(json_to_value(json)),
            Err(e) => Err(format!("Failed to parse JSON: {}", e)),
        }
    }

    pub fn stringify(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("JSON[stringify] requires exactly 1 argument: value".to_string());
        }
        
        let value = args[0].clone();
        
        match value_to_json(value) {
            Ok(json) => {
                match to_string(&json) {
                    Ok(s) => Ok(Value::String(s)),
                    Err(e) => Err(format!("Failed to stringify JSON: {}", e)),
                }
            },
            Err(e) => Err(e),
        }
    }
}

// Network library functions
pub mod net {
    use super::*;
    use std::process::Command;
    use std::time::Duration;

    pub fn ping(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 1 {
            return Err("Net[ping] requires exactly 1 argument: host".to_string());
        }
        
        let host = args[0].as_string()?;
        
        // Simple ping implementation using the system command
        // This is platform-dependent and may not work on all systems
        #[cfg(target_os = "windows")]
        let output = Command::new("ping")
            .args(&["-n", "1", &host])
            .output();
            
        #[cfg(not(target_os = "windows"))]
        let output = Command::new("ping")
            .args(&["-c", "1", &host])
            .output();
        
        match output {
            Ok(output) => {
                let success = output.status.success();
                Ok(Value::Bool(success))
            },
            Err(e) => Err(format!("Failed to ping host: {}", e)),
        }
    }
}

// Bolt library for intensive operations
pub mod bolt {
    use super::*;
    use std::thread;
    use std::sync::{Arc, Mutex};

    pub fn run(args: Vec<Value>) -> Result<Value, String> {
        if args.len() < 1 {
            return Err("Bolt[run] requires at least 1 argument: function".to_string());
        }
        
        // This is a placeholder for a more complex implementation
        // In a real implementation, this would execute the function in a separate thread
        // or process for better performance
        
        // For now, we'll just return a success value
        Ok(Value::Bool(true))
    }

    pub fn parallel(args: Vec<Value>) -> Result<Value, String> {
        if args.len() != 2 {
            return Err("Bolt[parallel] requires exactly 2 arguments: array, function".to_string());
        }
        
        let array = match &args[0] {
            Value::Array(arr) => arr.clone(),
            _ => return Err(format!("First argument to parallel must be an array, got {:?}", args[0])),
        };
        
        // This is a placeholder for a more complex implementation
        // In a real implementation, this would execute the function on each array element
        // in parallel using multiple threads
        
        // For now, we'll just return the original array
        Ok(Value::Array(array))
    }
}

// Seed library for generating seed codes and maps
pub mod seed {
    use super::*;
    use rand::Rng;
    use rand::SeedableRng;
    use rand_chacha::ChaCha8Rng;

    pub fn generate(args: Vec<Value>) -> Result<Value, String> {
        if args.len() > 1 {
            return Err("Seed[generate] takes at most 1 argument: length".to_string());
        }
        
        let length = if args.is_empty() {
            16
        } else {
            args[0].as_int()? as usize
        };
        
        if length < 1 || length > 1024 {
            return Err("Seed length must be between 1 and 1024".to_string());
        }
        
        let mut rng = rand::thread_rng();
        let charset: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        let seed: String = (0..length)
            .map(|_| {
                let idx = rng.gen_range(0..charset.len());
                charset[idx] as char
            })
            .collect();
        
        Ok(Value::String(seed))
    }

    pub fn map(args: Vec<Value>) -> Result<Value, String> {
        if args.len() < 1 || args.len() > 3 {
            return Err("Seed[map] takes 1-3 arguments: seed, width, height".to_string());
        }
        
        let seed_str = args[0].as_string()?;
        let width = if args.len() > 1 { args[1].as_int()? as usize } else { 10 };
        let height = if args.len() > 2 { args[2].as_int()? as usize } else { 10 };
        
        if width < 1 || width > 1000 || height < 1 || height > 1000 {
            return Err("Map dimensions must be between 1 and 1000".to_string());
        }
        
        // Create a deterministic RNG from the seed
        let seed_bytes = seed_str.as_bytes();
        let seed_u64: u64 = seed_bytes.iter()
            .enumerate()
            .fold(0, |acc, (i, &b)| acc + (b as u64) * (i as u64 + 1));
        
        let mut rng = ChaCha8Rng::seed_from_u64(seed_u64);
        
        // Generate a simple 2D map
        let mut map = Vec::new();
        for _ in 0..height {
            let mut row = Vec::new();
            for _ in 0..width {
                // Generate a value between 0 and 9
                let value = rng.gen_range(0..10);
                row.push(Value::Int(value));
            }
            map.push(Value::Array(row));
        }
        
        Ok(Value::Array(map))
    }
}