//! Diagnostic: attenuation, VAD and allocation counts for synthetic inputs.
//! cargo run -p audio_dsp --example diag
use audio_dsp::{level_dbfs, Dsp, Params, FRAME_SIZE};
use std::alloc::{GlobalAlloc, Layout, System};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};

struct Counting;
static COUNT: AtomicUsize = AtomicUsize::new(0);
static ARMED: AtomicBool = AtomicBool::new(false);
unsafe impl GlobalAlloc for Counting {
    unsafe fn alloc(&self, l: Layout) -> *mut u8 {
        if ARMED.load(Ordering::Relaxed) { COUNT.fetch_add(1, Ordering::Relaxed); }
        System.alloc(l)
    }
    unsafe fn dealloc(&self, p: *mut u8, l: Layout) { System.dealloc(p, l) }
}
#[global_allocator]
static A: Counting = Counting;

struct Lcg(u64);
impl Lcg {
    fn next(&mut self) -> f32 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 33) as f32 / (1u64 << 31) as f32) * 2.0 - 1.0
    }
}

fn main() {
    for amp in [30.0f32, 300.0, 3000.0, 10000.0] {
        for lowpass in [false, true] {
            let p = Params { gate_mode: 0, far_end_ducking: 0, ..Default::default() };
            let mut dsp = Dsp::new(p);
            let mut r = Lcg(7);
            let mut sig: Vec<f32> = (0..FRAME_SIZE * 100).map(|_| r.next() * amp).collect();
            if lowpass {
                let mut y = 0.0;
                for s in sig.iter_mut() { y += (*s - y) * 0.1; *s = y * 3.0; }
            }
            let in_db = level_dbfs(&sig);
            let mut vads = Vec::new();
            for block in sig.chunks_mut(FRAME_SIZE) {
                dsp.process_block(block);
                vads.push(dsp.report().vad);
            }
            let out_db = level_dbfs(&sig[FRAME_SIZE * 50..]);
            let vad_avg: f32 = vads[50..].iter().sum::<f32>() / 50.0;
            println!("amp {amp:>6} lowpass {lowpass:<5} in {in_db:6.1} dBFS  atten {:5.1} dB  vad {vad_avg:.2}", in_db - out_db);
        }
    }

    let mut dsp = Dsp::new(Params::default());
    let mut r = Lcg(3);
    let mut sig: Vec<f32> = (0..FRAME_SIZE * 10).map(|_| r.next() * 1000.0).collect();
    let render: Vec<f32> = (0..FRAME_SIZE).map(|_| r.next() * 1000.0).collect();
    for (name, f) in [
        ("process_block", Box::new(|d: &mut Dsp, s: &mut [f32]| d.process_block(s)) as Box<dyn Fn(&mut Dsp, &mut [f32])>),
        ("feed_render", Box::new(|d: &mut Dsp, _s: &mut [f32]| d.feed_render(&render))),
    ] {
        COUNT.store(0, Ordering::Relaxed);
        ARMED.store(true, Ordering::Relaxed);
        for block in sig.chunks_mut(FRAME_SIZE) { f(&mut dsp, block); }
        ARMED.store(false, Ordering::Relaxed);
        println!("{name}: {} allocations over 10 calls", COUNT.load(Ordering::Relaxed));
    }
    let mut stream: Vec<f32> = (0..128 * 40).map(|_| r.next() * 0.01).collect();
    COUNT.store(0, Ordering::Relaxed);
    ARMED.store(true, Ordering::Relaxed);
    for block in stream.chunks_mut(128) { dsp.process_stream(block); }
    ARMED.store(false, Ordering::Relaxed);
    println!("process_stream: {} allocations over 40 calls", COUNT.load(Ordering::Relaxed));
}
