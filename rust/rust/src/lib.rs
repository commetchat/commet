pub mod api;
mod frb_generated;

// Voice DSP (noise suppression, gate, ducking). Re-exported so its C ABI
// symbols are linked into this library; Dart loads them from here.
pub use audio_dsp;

// Soundboard clip decoder (MP3/Ogg/FLAC/WAV to PCM), same C ABI arrangement.
pub use audio_decode;

#[cfg(any(target_os = "windows", target_os = "linux"))]
mod widget_runner;

#[no_mangle]
pub extern "C" fn commet_widget_runner() {
    #[cfg(any(target_os = "windows", target_os = "linux"))]
    {
        widget_runner::run();
    }
}
