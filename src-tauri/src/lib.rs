mod commands;
mod dictionary;
mod process;

use commands::SystemState;
use sysinfo::System;
use std::sync::Mutex;
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();

            #[cfg(target_os = "macos")]
            {
                use window_vibrancy::{apply_vibrancy, NSVisualEffectMaterial, NSVisualEffectState};
                apply_vibrancy(&window, NSVisualEffectMaterial::Sidebar, Some(NSVisualEffectState::Active), None)
                    .expect("Unsupported platform! 'apply_vibrancy' is only supported on macOS");
            }

            Ok(())
        })
        .manage(SystemState(Mutex::new(System::new_all())))
        .invoke_handler(tauri::generate_handler![
            commands::get_processes,
            commands::kill_process
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
