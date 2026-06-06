#[cfg(any(target_os = "windows", target_os = "linux"))]
mod widget_runner;

pub fn main() {
    println!("Hello!");

    #[cfg(any(target_os = "windows", target_os = "linux"))]
    {
        widget_runner::run();
    }
}
