use crate::value::Value;
use std::thread;
use std::sync::{Arc, Mutex};
use std::collections::HashMap;
use std::time::Duration;

// Global thread manager to track threads
lazy_static::lazy_static! {
    static ref THREAD_MANAGER: Arc<Mutex<ThreadManager>> = Arc::new(Mutex::new(ThreadManager::new()));
}

// Thread manager to track running threads
struct ThreadManager {
    threads: HashMap<usize, thread::JoinHandle<()>>,
    next_thread_id: usize,
    mutexes: HashMap<usize, Arc<Mutex<()>>>,
    next_mutex_id: usize,
}

impl ThreadManager {
    fn new() -> Self {
        ThreadManager {
            threads: HashMap::new(),
            next_thread_id: 1,
            mutexes: HashMap::new(),
            next_mutex_id: 1,
        }
    }

    fn register_thread(&mut self, handle: thread::JoinHandle<()>) -> usize {
        let id = self.next_thread_id;
        self.next_thread_id += 1;
        self.threads.insert(id, handle);
        id
    }

    fn get_thread(&mut self, id: usize) -> Result<(), String> {
        if self.threads.contains_key(&id) {
            Ok(())
        } else {
            Err(format!("Invalid thread ID: {}", id))
        }
    }

    fn remove_thread(&mut self, id: usize) -> Result<thread::JoinHandle<()>, String> {
        self.threads.remove(&id)
            .ok_or_else(|| format!("Invalid thread ID: {}", id))
    }

    fn create_mutex(&mut self) -> usize {
        let id = self.next_mutex_id;
        self.next_mutex_id += 1;
        self.mutexes.insert(id, Arc::new(Mutex::new(())));
        id
    }

    fn get_mutex(&self, id: usize) -> Result<Arc<Mutex<()>>, String> {
        self.mutexes.get(&id)
            .cloned()
            .ok_or_else(|| format!("Invalid mutex ID: {}", id))
    }

    fn remove_mutex(&mut self, id: usize) -> Result<(), String> {
        if self.mutexes.remove(&id).is_some() {
            Ok(())
        } else {
            Err(format!("Invalid mutex ID: {}", id))
        }
    }
}

/// Create a new thread
/// Example: create("thread_function") => 1
pub fn create(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.create requires exactly 1 argument: function_name".to_string());
    }
    
    let function_name = args[0].as_string()?;
    
    // This is a simplified implementation
    // In a real implementation, we would need to look up the function by name
    // and execute it in a new thread
    
    // For now, just create a dummy thread that sleeps for a second
    let handle = thread::spawn(move || {
        // Simulate some work
        thread::sleep(Duration::from_secs(1));
        println!("Thread {} completed", function_name);
    });
    
    // Register the thread
    let thread_id = THREAD_MANAGER.lock().unwrap().register_thread(handle);
    
    Ok(Value::Int(thread_id as i64))
}

/// Join a thread (wait for it to complete)
/// Example: join(1) => true
pub fn join(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.join requires exactly 1 argument: thread_id".to_string());
    }
    
    let thread_id = args[0].as_int()? as usize;
    
    // Remove the thread from the manager
    let handle = THREAD_MANAGER.lock().unwrap().remove_thread(thread_id)?;
    
    // Wait for the thread to complete
    match handle.join() {
        Ok(_) => Ok(Value::Bool(true)),
        Err(_) => Err("Thread panicked".to_string()),
    }
}

/// Check if a thread is running
/// Example: is_running(1) => true
pub fn is_running(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.is_running requires exactly 1 argument: thread_id".to_string());
    }
    
    let thread_id = args[0].as_int()? as usize;
    
    // Check if the thread exists
    match THREAD_MANAGER.lock().unwrap().get_thread(thread_id) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(_) => Ok(Value::Bool(false)),
    }
}

/// Sleep for a specified Int of milliseconds
/// Example: sleep(1000) => true (sleeps for 1 second)
pub fn sleep(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.sleep requires exactly 1 argument: milliseconds".to_string());
    }
    
    let ms = args[0].as_int()? as u64;
    
    // Sleep for the specified duration
    thread::sleep(Duration::from_millis(ms));
    
    Ok(Value::Bool(true))
}

/// Create a mutex
/// Example: mutex_create() => 1
pub fn mutex_create(args: Vec<Value>) -> Result<Value, String> {
    if !args.is_empty() {
        return Err("Thread.mutex_create takes no arguments".to_string());
    }
    
    // Create a mutex
    let mutex_id = THREAD_MANAGER.lock().unwrap().create_mutex();
    
    Ok(Value::Int(mutex_id as i64))
}

/// Lock a mutex
/// Example: mutex_lock(1) => true
pub fn mutex_lock(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.mutex_lock requires exactly 1 argument: mutex_id".to_string());
    }
    
    let mutex_id = args[0].as_int()? as usize;
    
    // Get the mutex
    let mutex = THREAD_MANAGER.lock().unwrap().get_mutex(mutex_id)?;
    
    // Lock the mutex
    let lock_result = mutex.lock();
    match lock_result {
        Ok(_) => Ok(Value::Bool(true)),
        Err(_) => Err("Mutex lock failed".to_string()),
    }
}

/// Unlock a mutex
/// Example: mutex_unlock(1) => true
pub fn mutex_unlock(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.mutex_unlock requires exactly 1 argument: mutex_id".to_string());
    }
    
    let mutex_id = args[0].as_int()? as usize;
    
    // Get the mutex
    let mutex = THREAD_MANAGER.lock().unwrap().get_mutex(mutex_id)?;
    
    // The mutex will be unlocked when the guard is dropped
    // This is a simplified implementation
    
    Ok(Value::Bool(true))
}

/// Destroy a mutex
/// Example: mutex_destroy(1) => true
pub fn mutex_destroy(args: Vec<Value>) -> Result<Value, String> {
    if args.len() != 1 {
        return Err("Thread.mutex_destroy requires exactly 1 argument: mutex_id".to_string());
    }
    
    let mutex_id = args[0].as_int()? as usize;
    
    // Remove the mutex
    match THREAD_MANAGER.lock().unwrap().remove_mutex(mutex_id) {
        Ok(_) => Ok(Value::Bool(true)),
        Err(e) => Err(e),
    }
}

/// Get the current thread ID
/// Example: current() => 1
pub fn current(args: Vec<Value>) -> Result<Value, String> {
    if !args.is_empty() {
        return Err("Thread.current takes no arguments".to_string());
    }
    
    // This is a simplified implementation
    // In a real implementation, we would need to track thread IDs
    
    // For now, just return a dummy ID
    Ok(Value::Int(0))
}

/// Get the Int of available CPU cores
/// Example: cpu_count() => 8
pub fn cpu_count(args: Vec<Value>) -> Result<Value, String> {
    if !args.is_empty() {
        return Err("Thread.cpu_count takes no arguments".to_string());
    }
    
    // Get the Int of available CPU cores
    let count = num_cpus::get();
    
    Ok(Value::Int(count as i64))
}
