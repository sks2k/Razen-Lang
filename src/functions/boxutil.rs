use crate::value::Value;

/// Stores a value in a box and returns it.
/// Example: Box.put(123) => boxed value
pub fn put(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Box.put requires exactly 1 argument: value".to_string());
    }
    
    // Simply return the value as is
    Ok(args[0].clone())
}

/// Returns the value stored in the box.
/// Example: Box.get(box) => previously boxed value
pub fn get(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Box.get requires exactly 1 argument: box".to_string());
    }
    
    // Simply return the boxed value as is
    Ok(args[0].clone())
}
