use crate::process::{self, ProcessInfo};
use sysinfo::System;
use tauri::State;
use std::sync::Mutex;

pub struct SystemState(pub Mutex<System>);

#[tauri::command]
pub fn get_processes(state: State<SystemState>) -> Result<Vec<ProcessInfo>, String> {
    let mut system = state.0.lock().map_err(|e| e.to_string())?;
    Ok(process::get_all_processes(&mut system))
}

#[tauri::command]
pub fn kill_process(pid: u32, state: State<SystemState>) -> Result<(), String> {
    let mut system = state.0.lock().map_err(|e| e.to_string())?;
    process::kill_process(&mut system, pid)
}
