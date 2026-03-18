use log::*;
use std::io::{self, BufRead, Write};

pub mod api;
mod frb_generated;

#[no_mangle]
pub extern "C" fn commet_entry() {
    stderrlog::new()
        .verbosity(log::LevelFilter::Debug)
        .module(module_path!())
        .init()
        .unwrap();

    info!("Hello from the commet rust entrypoint!");

    let stdin = io::stdin();
    let mut stdout = io::stdout();

    loop {
        for line in stdin.lock().lines() {
            info!("received: '{}'", line.unwrap());

            stdout.write(b"Sending some data back\n").unwrap();
            stdout.flush().unwrap();
        }
    }
}
