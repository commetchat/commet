pub mod api;
mod frb_generated;

#[cfg(any(target_os = "windows", target_os = "linux"))]
mod widget_runner;

#[no_mangle]
pub extern "C" fn commet_widget_runner() {
    #[cfg(any(target_os = "windows", target_os = "linux"))]
    {
        widget_runner::run();
    }
}

#[no_mangle]
pub extern "C" fn commet_overlay() {
    #[cfg(any(target_os = "windows", target_os = "linux"))]
    {
        overlay::run_overlay();
    }
}
