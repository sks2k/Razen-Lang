use crate::value::Value;
use std::process::Command;

/// Ping a host to check connectivity
/// Example: ping("google.com") => true
pub fn ping(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Net.ping requires exactly 1 argument: host".to_string());
    }
    
    let host = args[0].as_string()?;
    
    // Use the system ping command with a timeout
    #[cfg(target_os = "windows")]
    let output = Command::new("ping")
        .args(["-n", "1", "-w", "1000", &host])
        .output();
        
    #[cfg(not(target_os = "windows"))]
    let output = Command::new("ping")
        .args(["-c", "1", "-W", "1", &host])
        .output();
    
    match output {
        Ok(output) => {
            // Check if ping was successful (exit code 0)
            Ok(Value::Bool(output.status.success()))
        },
        Err(_) => Ok(Value::Bool(false)),
    }
}
