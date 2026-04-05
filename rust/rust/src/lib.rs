pub mod api;
mod frb_generated;
mod widget_runner;

#[no_mangle]
pub extern "C" fn commet_entry() {
    widget_runner::run();
}
