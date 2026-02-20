use anyhow::{anyhow, Result};
use cpal::traits::{DeviceTrait, StreamTrait};
use cpal::{Device, FromSample, Sample, SampleFormat, SizedSample, Stream, StreamConfig};
use flutter_rust_bridge::frb;
use log::{error, info};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use crate::api::livekit::audio_mixer::AudioMixer;

#[frb(ignore)]
pub struct AudioPlayback {
    _stream: Stream,
    is_running: Arc<AtomicBool>,
}

impl AudioPlayback {
    pub async fn new(
        device: Device,
        config: StreamConfig,
        sample_format: SampleFormat,
        mixer: AudioMixer,
    ) -> Result<Self> {
        let is_running = Arc::new(AtomicBool::new(true));
        let is_running_clone = is_running.clone();

        let stream = match sample_format {
            SampleFormat::F32 => {
                Self::create_output_stream::<f32>(device, config, mixer, is_running_clone)?
            }
            SampleFormat::I16 => {
                Self::create_output_stream::<i16>(device, config, mixer, is_running_clone)?
            }
            SampleFormat::U16 => {
                Self::create_output_stream::<u16>(device, config, mixer, is_running_clone)?
            }
            sample_format => {
                return Err(anyhow!("Unsupported sample format: {:?}", sample_format));
            }
        };

        stream.play()?;
        info!("Audio playback stream started");

        Ok(AudioPlayback {
            _stream: stream,
            is_running,
        })
    }

    fn create_output_stream<T>(
        device: Device,
        config: StreamConfig,
        mixer: AudioMixer,
        is_running: Arc<AtomicBool>,
    ) -> Result<Stream>
    where
        T: SizedSample + Sample + Send + 'static + FromSample<f32>,
    {
        let stream = device.build_output_stream(
            &config,
            move |data: &mut [T], _: &cpal::OutputCallbackInfo| {
                if !is_running.load(Ordering::Relaxed) {
                    // Fill with silence if not running
                    for sample in data.iter_mut() {
                        *sample = Sample::from_sample(0.0f32);
                    }
                    return;
                }

                let mixed_samples = mixer.get_samples(data.len());

                // Convert mixed i16 samples to output format
                for (i, sample) in data.iter_mut().enumerate() {
                    *sample = Self::convert_i16_to_sample::<T>(mixed_samples[i]);
                }
            },
            move |err| {
                error!("Audio output stream error: {}", err);
            },
            None,
        )?;

        Ok(stream)
    }

    fn convert_i16_to_sample<T: SizedSample + Sample + FromSample<f32>>(sample: i16) -> T {
        if std::mem::size_of::<T>() == std::mem::size_of::<f32>() {
            let sample_f32 = sample as f32 / i16::MAX as f32;
            unsafe { std::mem::transmute_copy::<f32, T>(&sample_f32) }
        } else if std::mem::size_of::<T>() == std::mem::size_of::<i16>() {
            unsafe { std::mem::transmute_copy::<i16, T>(&sample) }
        } else if std::mem::size_of::<T>() == std::mem::size_of::<u16>() {
            let sample_u16 = ((sample as i32) + (u16::MAX as i32 / 2)) as u16;
            unsafe { std::mem::transmute_copy::<u16, T>(&sample_u16) }
        } else {
            Sample::from_sample(0.0f32)
        }
    }

    pub fn stop(&self) {
        self.is_running.store(false, Ordering::Relaxed);
    }
}

impl Drop for AudioPlayback {
    fn drop(&mut self) {
        self.stop();
    }
}
