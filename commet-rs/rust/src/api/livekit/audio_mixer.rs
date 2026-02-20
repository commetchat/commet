use flutter_rust_bridge::frb;
use std::sync::{Arc, Mutex};
use tokio::sync::mpsc;

#[derive(Clone)]
#[frb(ignore)]
pub struct AudioMixer {
    buffer: Arc<Mutex<std::collections::VecDeque<i16>>>,
    sample_rate: u32,
    channels: u32,
    volume: f32,
    max_buffer_size: usize,
    // Channel to send reference audio for echo cancellation
    reference_audio_tx: Option<mpsc::UnboundedSender<Vec<i16>>>,
}

impl AudioMixer {
    pub fn new(sample_rate: u32, channels: u32, volume: f32) -> Self {
        // Buffer for 1 second of audio
        let max_buffer_size = sample_rate as usize * channels as usize;

        Self {
            buffer: Arc::new(Mutex::new(std::collections::VecDeque::with_capacity(
                max_buffer_size,
            ))),
            sample_rate,
            channels,
            volume: volume.clamp(0.0, 1.0),
            max_buffer_size,
            reference_audio_tx: None,
        }
    }

    pub fn with_db_meter(sample_rate: u32, channels: u32, volume: f32) -> Self {
        // Buffer for 1 second of audio
        let max_buffer_size = sample_rate as usize * channels as usize;

        Self {
            buffer: Arc::new(Mutex::new(std::collections::VecDeque::with_capacity(
                max_buffer_size,
            ))),
            sample_rate,
            channels,
            volume: volume.clamp(0.0, 1.0),
            max_buffer_size,
            reference_audio_tx: None,
        }
    }

    pub fn with_reference_audio(
        sample_rate: u32,
        channels: u32,
        volume: f32,
        reference_audio_tx: mpsc::UnboundedSender<Vec<i16>>,
    ) -> Self {
        // Buffer for 1 second of audio
        let max_buffer_size = sample_rate as usize * channels as usize;

        Self {
            buffer: Arc::new(Mutex::new(std::collections::VecDeque::with_capacity(
                max_buffer_size,
            ))),
            sample_rate,
            channels,
            volume: volume.clamp(0.0, 1.0),
            max_buffer_size,
            reference_audio_tx: Some(reference_audio_tx),
        }
    }

    pub fn add_audio_data(&self, data: &[i16]) {
        let mut buffer = self.buffer.lock().unwrap();

        // Apply volume scaling and add to buffer
        for &sample in data.iter() {
            let scaled_sample = (sample as f32 * self.volume) as i16;
            buffer.push_back(scaled_sample);

            // Prevent buffer from growing too large
            if buffer.len() > self.max_buffer_size {
                buffer.pop_front();
            }
        }
    }

    pub fn get_samples(&self, requested_samples: usize) -> Vec<i16> {
        let mut buffer = self.buffer.lock().unwrap();
        let mut result = Vec::with_capacity(requested_samples);

        // Fill the requested samples
        for _ in 0..requested_samples {
            if let Some(sample) = buffer.pop_front() {
                result.push(sample);
            } else {
                result.push(0); // Silence when no data available
            }
        }

        // Send copy to reference audio channel for echo cancellation
        // Send ALL audio frames (including silence) for proper timing synchronization
        if let Some(ref ref_tx) = self.reference_audio_tx {
            if let Err(_) = ref_tx.send(result.clone()) {
                // Only log occasionally to avoid spam
                static mut LOG_COUNTER: u32 = 0;
                unsafe {
                    LOG_COUNTER += 1;
                    if LOG_COUNTER % 1000 == 0 {
                        log::warn!(
                            "Reference audio channel closed or full (logged every 1000 attempts)"
                        );
                    }
                }
            }
        }

        result
    }

    pub fn buffer_size(&self) -> usize {
        self.buffer.lock().unwrap().len()
    }
}
