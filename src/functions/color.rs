use crate::value::Value;

/// Converts a hex color string to RGB array
/// Example: hex_to_rgb("#ff0000") => [255, 0, 0]
pub fn hex_to_rgb(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Color.hex_to_rgb requires exactly 1 argument: hex".to_string());
    }
    
    let hex = args[0].as_string()?;
    let hex = hex.trim_start_matches('#');
    
    if hex.len() != 6 {
        return Err("Invalid hex color format. Expected format: #RRGGBB".to_string());
    }
    
    // Parse the hex values
    let r = u8::from_str_radix(&hex[0..2], 16)
        .map_err(|_| "Invalid hex color format for red component".to_string())?;
    let g = u8::from_str_radix(&hex[2..4], 16)
        .map_err(|_| "Invalid hex color format for green component".to_string())?;
    let b = u8::from_str_radix(&hex[4..6], 16)
        .map_err(|_| "Invalid hex color format for blue component".to_string())?;
    
    // Create the RGB array
    let mut rgb = Vec::new();
    rgb.push(Value::Int(r as i64));
    rgb.push(Value::Int(g as i64));
    rgb.push(Value::Int(b as i64));
    
    Ok(Value::Array(rgb))
}

/// Converts an RGB array to a hex color string
/// Example: rgb_to_hex([255, 0, 0]) => "#ff0000"
pub fn rgb_to_hex(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Color.rgb_to_hex requires exactly 1 argument: rgb array".to_string());
    }
    
    let rgb = match &args[0] {
        Value::Array(arr) => arr,
        _ => return Err("Color.rgb_to_hex requires an array argument".to_string()),
    };
    
    if rgb.len() != 3 {
        return Err("RGB array must contain exactly 3 values: [r, g, b]".to_string());
    }
    
    // Extract the RGB components
    let r = match rgb[0] {
        Value::Int(val) => {
            if val < 0 || val > 255 {
                return Err("Red component must be between 0 and 255".to_string());
            }
            val as u8
        },
        _ => return Err("RGB components must be integers".to_string()),
    };
    
    let g = match rgb[1] {
        Value::Int(val) => {
            if val < 0 || val > 255 {
                return Err("Green component must be between 0 and 255".to_string());
            }
            val as u8
        },
        _ => return Err("RGB components must be integers".to_string()),
    };
    
    let b = match rgb[2] {
        Value::Int(val) => {
            if val < 0 || val > 255 {
                return Err("Blue component must be between 0 and 255".to_string());
            }
            val as u8
        },
        _ => return Err("RGB components must be integers".to_string()),
    };
    
    // Convert to hex
    let hex = format!("#{:02x}{:02x}{:02x}", r, g, b);
    
    Ok(Value::String(hex))
}

/// Lightens a hex color by a percentage
/// Example: lighten("#888888", 20) => "#aaaaaa"
pub fn lighten(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Color.lighten requires exactly 2 arguments: hex, percent".to_string());
    }
    
    let hex = args[0].as_string()?;
    let percent = match args[1] {
        Value::Int(val) => {
            if val < 0 || val > 100 {
                return Err("Percent must be between 0 and 100".to_string());
            }
            val as f64 / 100.0
        },
        Value::Float(val) => {
            if val < 0.0 || val > 100.0 {
                return Err("Percent must be between 0 and 100".to_string());
            }
            val / 100.0
        },
        _ => return Err("Percent must be a number".to_string()),
    };
    
    // Convert hex to RGB
    let rgb_args = vec![Value::String(hex.clone())];
    let rgb_value = hex_to_rgb(rgb_args)?;
    
    let rgb = match rgb_value {
        Value::Array(arr) => arr,
        _ => return Err("Failed to convert hex to RGB".to_string()),
    };
    
    // Lighten each component
    let mut lightened = Vec::new();
    for component in rgb {
        match component {
            Value::Int(val) => {
                let lightened_val = val + ((255 - val) as f64 * percent) as i64;
                lightened.push(Value::Int(lightened_val.min(255)));
            },
            _ => return Err("RGB components must be integers".to_string()),
        }
    }
    
    // Convert back to hex
    let hex_args = vec![Value::Array(lightened)];
    rgb_to_hex(hex_args)
}

/// Darkens a hex color by a percentage
/// Example: darken("#888888", 20) => "#666666"
pub fn darken(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Color.darken requires exactly 2 arguments: hex, percent".to_string());
    }
    
    let hex = args[0].as_string()?;
    let percent = match args[1] {
        Value::Int(val) => {
            if val < 0 || val > 100 {
                return Err("Percent must be between 0 and 100".to_string());
            }
            val as f64 / 100.0
        },
        Value::Float(val) => {
            if val < 0.0 || val > 100.0 {
                return Err("Percent must be between 0 and 100".to_string());
            }
            val / 100.0
        },
        _ => return Err("Percent must be a number".to_string()),
    };
    
    // Convert hex to RGB
    let rgb_args = vec![Value::String(hex.clone())];
    let rgb_value = hex_to_rgb(rgb_args)?;
    
    let rgb = match rgb_value {
        Value::Array(arr) => arr,
        _ => return Err("Failed to convert hex to RGB".to_string()),
    };
    
    // Darken each component
    let mut darkened = Vec::new();
    for component in rgb {
        match component {
            Value::Int(val) => {
                let darkened_val = val - (val as f64 * percent) as i64;
                darkened.push(Value::Int(darkened_val.max(0)));
            },
            _ => return Err("RGB components must be integers".to_string()),
        }
    }
    
    // Convert back to hex
    let hex_args = vec![Value::Array(darkened)];
    rgb_to_hex(hex_args)
}
