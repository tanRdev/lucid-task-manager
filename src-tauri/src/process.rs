use crate::dictionary::{self, Safety};
use serde::Serialize;
use sysinfo::{ProcessRefreshKind, System, UpdateKind};

#[derive(Debug, Clone, Serialize)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    pub description: String,
    pub cpu_usage: f32,
    pub memory_bytes: u64,
    pub safety: Safety,
    pub exe_path: String,
}

/// Enumerates all processes and returns a vector of ProcessInfo
pub fn get_all_processes(system: &mut System) -> Vec<ProcessInfo> {
    // Refresh process information
    system.refresh_processes_specifics(
        sysinfo::ProcessesToUpdate::All,
        true,
        ProcessRefreshKind::new()
            .with_cpu()
            .with_memory()
            .with_exe(UpdateKind::Always),
    );

    let mut processes = Vec::new();

    for (pid, process) in system.processes() {
        let process_name = process.name().to_string_lossy().to_string();
        let cpu_usage = process.cpu_usage();
        let memory_bytes = process.memory();

        // Get exe path as fallback
        let exe_path = process
            .exe()
            .and_then(|p| p.to_str())
            .unwrap_or("")
            .to_string();

        // Look up process in dictionary - skip unknown processes
        let (description, safety) = match dictionary::lookup(&process_name) {
            Some((desc, safety_cat)) => (desc.to_string(), safety_cat),
            None => continue, // Skip processes not in dictionary
        };

        processes.push(ProcessInfo {
            pid: pid.as_u32(),
            name: process_name,
            description,
            cpu_usage,
            memory_bytes,
            safety,
            exe_path,
        });
    }

    processes
}

/// Attempts to kill a process by PID
pub fn kill_process(system: &mut System, pid: u32) -> Result<(), String> {
    system.refresh_processes_specifics(
        sysinfo::ProcessesToUpdate::All,
        false,
        ProcessRefreshKind::new(),
    );

    let pid_obj = sysinfo::Pid::from_u32(pid);

    match system.process(pid_obj) {
        Some(process) => {
            if process.kill() {
                Ok(())
            } else {
                Err(format!("Failed to kill process {}", pid))
            }
        }
        None => Err(format!("Process {} not found", pid)),
    }
}
