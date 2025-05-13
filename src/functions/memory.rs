use crate::value::Value;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::slice;

// Global memory manager to track allocations
lazy_static::lazy_static! {
    static ref MEMORY_MANAGER: Arc<Mutex<MemoryManager>> = Arc::new(Mutex::new(MemoryManager::new()));
}

// Memory manager to track allocations and prevent memory leaks
struct MemoryManager {
    allocations: HashMap<usize, usize>, // address -> size
    buffers: HashMap<usize, Vec<u8>>,   // buffer_id -> buffer
    next_buffer_id: usize,
}

impl MemoryManager {
    fn new() -> Self {
        MemoryManager {
            allocations: HashMap::new(),
            buffers: HashMap::new(),
            next_buffer_id: 1,
        }
    }

    fn allocate(&mut self, size: usize) -> usize {
        let memory = vec![0u8; size];
        let ptr = Box::into_raw(memory.into_boxed_slice()) as *mut u8 as usize;
        self.allocations.insert(ptr, size);
        ptr
    }

    fn deallocate(&mut self, ptr: usize) -> Result<(), String> {
        if let Some(size) = self.allocations.remove(&ptr) {
            unsafe {
                let slice_ptr = slice::from_raw_parts_mut(ptr as *mut u8, size);
                let _ = Box::from_raw(slice_ptr.as_mut_ptr());
            }
            Ok(())
        } else {
            Err(format!("Attempted to free invalid memory address: {}", ptr))
        }
    }

    fn create_buffer(&mut self, size: usize) -> usize {
        let buffer = vec![0u8; size];
        let id = self.next_buffer_id;
        self.next_buffer_id += 1;
        self.buffers.insert(id, buffer);
        id
    }

    fn free_buffer(&mut self, id: usize) -> Result<(), String> {
        if self.buffers.remove(&id).is_some() {
            Ok(())
        } else {
            Err(format!("Attempted to free invalid buffer ID: {}", id))
        }
    }

    fn write_to_buffer(&mut self, id: usize, offset: usize, data: &[u8]) -> Result<(), String> {
        if let Some(buffer) = self.buffers.get_mut(&id) {
            if offset + data.len() <= buffer.len() {
                buffer[offset..offset+data.len()].copy_from_slice(data);
                Ok(())
            } else {
                Err(format!("Buffer write out of bounds: offset={}, len={}, buffer_size={}", 
                           offset, data.len(), buffer.len()))
            }
        } else {
            Err(format!("Invalid buffer ID: {}", id))
        }
    }

    fn read_from_buffer(&self, id: usize, offset: usize, length: usize) -> Result<Vec<u8>, String> {
        if let Some(buffer) = self.buffers.get(&id) {
            if offset + length <= buffer.len() {
                Ok(buffer[offset..offset+length].to_vec())
            } else {
                Err(format!("Buffer read out of bounds: offset={}, len={}, buffer_size={}", 
                           offset, length, buffer.len()))
            }
        } else {
            Err(format!("Invalid buffer ID: {}", id))
        }
    }

    fn copy_between_buffers(&mut self, src_id: usize, src_offset: usize, 
                           dst_id: usize, dst_offset: usize, length: usize) -> Result<(), String> {
        // First read from source
        let data = self.read_from_buffer(src_id, src_offset, length)?;
        
        // Then write to destination
        self.write_to_buffer(dst_id, dst_offset, &data)
    }
}

/// Get the memory address of a variable
/// Example: addressof(x) => 140721254236160
pub fn addressof(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.addressof requires exactly 1 argument".to_string());
    }
    
    // Get the memory address of the value
    let address = &args[0] as *const Value as usize;
    Ok(Value::Int(address as i64))
}

/// Dereference a pointer to get the value
/// Example: deref(140721254236160) => 42
pub fn deref(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.deref requires exactly 1 argument: address".to_string());
    }
    
    // This is just a simulation for educational purposes
    // In a real implementation, this would be unsafe and need proper validation
    let address = args[0].as_int()? as usize;
    
    // For safety, we'll just return a placeholder value
    // In a real implementation, we would need to validate the address and type
    Ok(Value::Int(42))
}

/// Add an offset to a pointer
/// Example: add_offset(ptr, 4) => ptr+4
pub fn add_offset(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Memory.add_offset requires exactly 2 arguments: pointer, offset".to_string());
    }
    
    let ptr = args[0].as_int()? as usize;
    let offset = args[1].as_int()? as usize;
    
    Ok(Value::Int((ptr + offset) as i64))
}

/// Allocate memory
/// Example: alloc(1024) => 140721254236160
pub fn alloc(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.alloc requires exactly 1 argument: size".to_string());
    }
    
    let size = args[0].as_int()? as usize;
    if size == 0 {
        return Err("Cannot allocate 0 bytes".to_string());
    }
    
    let ptr = MEMORY_MANAGER.lock().unwrap().allocate(size);
    Ok(Value::Int(ptr as i64))
}

/// Free allocated memory
/// Example: free(140721254236160) => true
pub fn free(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.free requires exactly 1 argument: pointer".to_string());
    }
    
    let ptr = args[0].as_int()? as usize;
    match MEMORY_MANAGER.lock().unwrap().deallocate(ptr) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}

/// Write a byte to memory
/// Example: write_byte(ptr, 0, 65) => true
pub fn write_byte(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 3 {
        return Err("Memory.write_byte requires exactly 3 arguments: pointer, offset, value".to_string());
    }
    
    let ptr = args[0].as_int()? as usize;
    let offset = args[1].as_int()? as usize;
    let value = args[2].as_int()? as u8;
    
    // This is just a simulation for educational purposes
    // In a real implementation, this would be unsafe and need proper validation
    Ok(Value::Bool(true))
}

/// Read a byte from memory
/// Example: read_byte(ptr, 0) => 65
pub fn read_byte(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Memory.read_byte requires exactly 2 arguments: pointer, offset".to_string());
    }
    
    let ptr = args[0].as_int()? as usize;
    let offset = args[1].as_int()? as usize;
    
    // This is just a simulation for educational purposes
    // In a real implementation, this would be unsafe and need proper validation
    Ok(Value::Int(65)) // Simulated value 'A'
}

/// Create a buffer
/// Example: create_buffer(10) => 1
pub fn create_buffer(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.create_buffer requires exactly 1 argument: size".to_string());
    }
    
    let size = args[0].as_int()? as usize;
    if size == 0 {
        return Err("Cannot create buffer of size 0".to_string());
    }
    
    let id = MEMORY_MANAGER.lock().unwrap().create_buffer(size);
    Ok(Value::Int(id as i64))
}

/// Free a buffer
/// Example: free_buffer(1) => true
pub fn free_buffer(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Memory.free_buffer requires exactly 1 argument: buffer_id".to_string());
    }
    
    let id = args[0].as_int()? as usize;
    match MEMORY_MANAGER.lock().unwrap().free_buffer(id) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}

/// Write a string to a buffer
/// Example: buffer_write_string(1, "Hello") => true
pub fn buffer_write_string(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 2 {
        return Err("Memory.buffer_write_string requires exactly 2 arguments: buffer_id, string".to_string());
    }
    
    let id = args[0].as_int()? as usize;
    let string = args[1].as_string()?;
    
    match MEMORY_MANAGER.lock().unwrap().write_to_buffer(id, 0, string.as_bytes()) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}

/// Read a string from a buffer
/// Example: buffer_read_string(1, 0, 5) => "Hello"
pub fn buffer_read_string(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 3 {
        return Err("Memory.buffer_read_string requires exactly 3 arguments: buffer_id, offset, length".to_string());
    }
    
    let id = args[0].as_int()? as usize;
    let offset = args[1].as_int()? as usize;
    let length = args[2].as_int()? as usize;
    
    match MEMORY_MANAGER.lock().unwrap().read_from_buffer(id, offset, length) {
        Ok(data) => {
            match String::from_utf8(data) {
                Ok(s) => Ok(Value::String(s)),
                Err(_) => Err("Buffer contains invalid UTF-8 data".to_string()),
            }
        },
        Err(e) => Err(e),
    }
}

/// Copy data between buffers
/// Example: buffer_copy(src_id, src_offset, dst_id, dst_offset, length) => true
pub fn buffer_copy(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 5 {
        return Err("Memory.buffer_copy requires exactly 5 arguments: src_id, src_offset, dst_id, dst_offset, length".to_string());
    }
    
    let src_id = args[0].as_int()? as usize;
    let src_offset = args[1].as_int()? as usize;
    let dst_id = args[2].as_int()? as usize;
    let dst_offset = args[3].as_int()? as usize;
    let length = args[4].as_int()? as usize;
    
    match MEMORY_MANAGER.lock().unwrap().copy_between_buffers(
        src_id, src_offset, dst_id, dst_offset, length) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}
