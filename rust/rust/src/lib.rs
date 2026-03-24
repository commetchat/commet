pub mod api;
mod app;
mod frb_generated;

#[no_mangle]
pub extern "C" fn commet_entry() {
    app::run();
}
