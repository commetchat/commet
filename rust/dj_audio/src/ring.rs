//! Single-producer single-consumer ring of stereo `f32` frames.
//!
//! The decoder thread is the only producer and `pull` (under the consumer
//! lock) the only consumer. Indices are monotonic frame counters, so
//! `write - read` is the fill level without an extra flag.

use std::cell::UnsafeCell;
use std::sync::atomic::{AtomicUsize, Ordering};

pub(crate) type Frame = [f32; 2];

pub(crate) struct Ring {
    buf: Box<[UnsafeCell<Frame>]>,
    write: AtomicUsize,
    read: AtomicUsize,
}

// The producer only touches slots in [read + len, read + cap) and the
// consumer only [read, write); the atomics hand slots over.
unsafe impl Sync for Ring {}

impl Ring {
    pub fn new(capacity: usize) -> Self {
        let buf = (0..capacity.max(1))
            .map(|_| UnsafeCell::new([0.0; 2]))
            .collect();
        Ring {
            buf,
            write: AtomicUsize::new(0),
            read: AtomicUsize::new(0),
        }
    }

    pub fn available(&self) -> usize {
        let w = self.write.load(Ordering::Acquire);
        let r = self.read.load(Ordering::Acquire);
        w.wrapping_sub(r)
    }

    /// Producer side. Returns how many frames fit.
    pub fn push(&self, data: &[Frame]) -> usize {
        let cap = self.buf.len();
        let w = self.write.load(Ordering::Relaxed);
        let r = self.read.load(Ordering::Acquire);
        let n = data.len().min(cap - w.wrapping_sub(r));
        for (i, f) in data[..n].iter().enumerate() {
            unsafe { *self.buf[w.wrapping_add(i) % cap].get() = *f };
        }
        self.write.store(w.wrapping_add(n), Ordering::Release);
        n
    }

    /// Consumer side. Returns how many frames were read.
    pub fn pop(&self, out: &mut [Frame]) -> usize {
        let cap = self.buf.len();
        let r = self.read.load(Ordering::Relaxed);
        let w = self.write.load(Ordering::Acquire);
        let n = out.len().min(w.wrapping_sub(r));
        for (i, f) in out[..n].iter_mut().enumerate() {
            *f = unsafe { *self.buf[r.wrapping_add(i) % cap].get() };
        }
        self.read.store(r.wrapping_add(n), Ordering::Release);
        n
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wraps_and_bounds() {
        let ring = Ring::new(5);
        let data: Vec<Frame> = (0..8).map(|i| [i as f32, -(i as f32)]).collect();
        assert_eq!(ring.push(&data), 5);
        let mut out = [[0.0; 2]; 3];
        assert_eq!(ring.pop(&mut out), 3);
        assert_eq!(out[2], [2.0, -2.0]);
        assert_eq!(ring.push(&data[5..]), 3);
        let mut out = [[0.0; 2]; 10];
        assert_eq!(ring.pop(&mut out), 5);
        let got: Vec<f32> = out[..5].iter().map(|f| f[0]).collect();
        assert_eq!(got, vec![3.0, 4.0, 5.0, 6.0, 7.0]);
        assert_eq!(ring.available(), 0);
    }
}
