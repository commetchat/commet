pub mod api;
mod frb_generated;

#[no_mangle]
pub extern "C" fn commet_entry() {
    println!("Hello from the commet rust entrypoint!")
}
