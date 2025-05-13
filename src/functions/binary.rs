use crate::value::Value;
use std::fs::{File, OpenOptions};
use std::io::{self, Read, Write, Seek, SeekFrom};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

// Global file handle manager to track open file handles
lazy_static::lazy_static! {
    static ref FILE_MANAGER: Arc<Mutex<FileManager>> = Arc::new(Mutex::new(FileManager::new()));
}

// File manager to track open file handles
struct FileManager {
    files: HashMap<usize, File>,
    next_file_id: usize,
}

impl FileManager {
    fn new() -> Self {
        FileManager {
            files: HashMap::new(),
            next_file_id: 1,
        }
    }

    fn register_file(&mut self, file: File) -> usize {
        let id = self.next_file_id;
        self.next_file_id += 1;
        self.files.insert(id, file);
        id
    }

    fn get_file(&mut self, id: usize) -> Result<&mut File, String> {
        self.files.get_mut(&id)
            .ok_or_else(|| format!("Invalid file handle: {}", id))
    }

    fn close_file(&mut self, id: usize) -> Result<(), String> {
        if self.files.remove(&id).is_some() {
            Ok(())
        } else {
            Err(format!("Invalid file handle: {}", id))
        }
    }
}

/// Create a new binary file
/// Example: create("test.bin") => true
pub fn create(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Binary.create requires exactly 1 argument: path".to_string());
    }
    
    let path = args[0].as_string()?;
    
    match File::create(&path) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(format!("Failed to create binary file '{}': {}", path, e)),
    }
}

/// Open a binary file
/// Example: open("test.bin", "rb") => file_handle
pub fn open(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Binary.open requires exactly 2 arguments: path, mode".to_string());
    }
    
    let path = args[0].as_string()?;
    let mode = args[1].as_string()?;
    
    let file = match mode.as_str() {
        "rb" => OpenOptions::new().read(true).open(&path),
        "wb" => OpenOptions::new().write(true).create(true).truncate(true).open(&path),
        "ab" => OpenOptions::new().write(true).append(true).create(true).open(&path),
        "r+b" => OpenOptions::new().read(true).write(true).open(&path),
        "w+b" => OpenOptions::new().read(true).write(true).create(true).truncate(true).open(&path),
        "a+b" => OpenOptions::new().read(true).write(true).append(true).create(true).open(&path),
        _ => return Err(format!("Invalid file mode: {}. Use 'rb', 'wb', 'ab', 'r+b', 'w+b', or 'a+b'", mode)),
    };
    
    match file {
        Ok(file) => {
            let id = FILE_MANAGER.lock().unwrap().register_file(file);
            Ok(Value::Int(id as i64))
        },
        Err(e) => Err(format!("Failed to open binary file '{}': {}", path, e)),
    }
}

/// Close a binary file
/// Example: close(file_handle) => true
pub fn close(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Binary.close requires exactly 1 argument: file_handle".to_string());
    }
    
    let handle = args[0].as_int()? as usize;
    
    match FILE_MANAGER.lock().unwrap().close_file(handle) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}

/// Write bytes to a binary file
/// Example: write(file_handle, [65, 66, 67]) => 3
pub fn write_bytes(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Binary.write_bytes requires exactly 2 arguments: file_handle, bytes".to_string());
    }
    
    let handle = args[0].as_int()? as usize;
    
    let bytes = match &args[1] {
        Value::Array(arr) => {
            let mut bytes = Vec::with_capacity(arr.len());
            for val in arr {
                bytes.push(val.as_int()? as u8);
            }
            bytes
        },
        Value::String(s) => s.as_bytes().to_vec(),
        _ => return Err("Second argument must be an array of bytes or a string".to_string()),
    };
    
    // Write bytes to file
    let mut file_manager = FILE_MANAGER.lock().unwrap();
    let file = file_manager.get_file(handle)?;
    
    match file.write_all(&bytes) {
        Ok(_) => Ok(Value::Int(bytes.len() as i64)),
        Err(e) => Err(format!("Failed to write bytes: {}", e)),
    }
}

/// Read bytes from a binary file
/// Example: read_bytes(file_handle, 5) => [65, 66, 67, 68, 69]
pub fn read_bytes(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Binary.read_bytes requires exactly 2 arguments: file_handle, count".to_string());
    }
    
    let handle = args[0].as_int()? as usize;
    let count = args[1].as_int()? as usize;
    
    if count == 0 {
        return Ok(Value::Array(Vec::new()));
    }
    
    // Read bytes from file
    let mut file_manager = FILE_MANAGER.lock().unwrap();
    let file = file_manager.get_file(handle)?;
    
    let mut buffer = vec![0u8; count];
    match file.read_exact(&mut buffer) {
        Ok(_) => {
            // Convert bytes to array of values
            let values: Vec<Value> = buffer.into_iter()
                .map(|b| Value::Int(b as i64))
                .collect();
            
            Ok(Value::Array(values))
        },
        Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => {
            // Handle case where we hit EOF before reading 'count' bytes
            Err(format!("End of file reached before reading {} bytes", count))
        },
        Err(e) => Err(format!("Failed to read bytes: {}", e)),
    }
}

/// Seek to a position in a binary file
/// Example: seek(file_handle, 10, "start") => true
pub fn seek(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 3 {
        return Err("Binary.seek requires exactly 3 arguments: file_handle, offset, whence".to_string());
    }
    
    let handle = args[0].as_int()? as usize;
    let offset = args[1].as_int()? as i64;
    let whence = args[2].as_string()?;
    
    let seek_from = match whence.as_str() {
        "start" => SeekFrom::Start(offset as u64),
        "current" => SeekFrom::Current(offset),
        "end" => SeekFrom::End(offset),
        _ => return Err(format!("Invalid seek whence: {}. Use 'start', 'current', or 'end'", whence)),
    };
    
    // Seek in file
    let mut file_manager = FILE_MANAGER.lock().unwrap();
    let file = file_manager.get_file(handle)?;
    
    match file.seek(seek_from) {
        Ok(position) => Ok(Value::Int(position as i64)),
        Err(e) => Err(format!("Failed to seek: {}", e)),
    }
}

/// Get the current position in a binary file
/// Example: tell(file_handle) => 10
pub fn tell(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Binary.tell requires exactly 1 argument: file_handle".to_string());
    }
    
    let handle = args[0].as_int()? as usize;
    
    // Get current position
    let mut file_manager = FILE_MANAGER.lock().unwrap();
    let file = file_manager.get_file(handle)?;
    
    match file.stream_position() {
        Ok(position) => Ok(Value::Int(position as i64)),
        Err(e) => Err(format!("Failed to get file position: {}", e)),
    }
}

/// Convert bytes to a string
/// Example: bytes_to_string([65, 66, 67]) => "ABC"
pub fn bytes_to_string(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Binary.bytes_to_string requires exactly 1 argument: bytes".to_string());
    }
    
    let bytes = args[0].as_array()?;
    
    // Convert array of values to bytes
    let mut buffer = Vec::with_capacity(bytes.len());
    for value in bytes {
        match value {
            Value::Int(n) => {
                if n < 0 || n > 255 {
                    return Err(format!("Invalid byte value: {}. Must be an integer between 0 and 255", n));
                }
                buffer.push(n as u8);
            },
            _ => return Err(format!("Invalid byte value: {:?}. Must be a Int between 0 and 255", value)),
        }
    }
    
    // Convert bytes to string
    match String::from_utf8(buffer) {
        Ok(s) => Ok(Value::String(s)),
        Err(_) => Err("Bytes contain invalid UTF-8 data".to_string()),
    }
}

/// Convert a string to bytes
/// Example: string_to_bytes("ABC") => [65, 66, 67]
pub fn string_to_bytes(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Binary.string_to_bytes requires exactly 1 argument: string".to_string());
    }
    
    let string = args[0].as_string()?;
    
    // Convert string to bytes
    let bytes = string.as_bytes();
    
    // Convert bytes to array of values
    let values: Vec<Value> = bytes.iter()
        .map(|&b| Value::Int(b as i64))
        .collect();
    
    Ok(Value::Array(values))
}
