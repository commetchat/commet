use std::sync::Arc;

use cpal::{
    traits::{DeviceTrait, HostTrait},
    Device, StreamConfig, SupportedStreamConfig,
};
use flutter_rust_bridge::{frb, JoinHandle};
use futures_util::{future::Join, StreamExt};
use livekit::{webrtc::audio_stream::native::NativeAudioStream, Room, RoomEvent};
use log::{debug, info};

use crate::api::livekit::{
    audio_mixer::AudioMixer, audio_playback::AudioPlayback, livekit_session_manager::RUNTIME,
};

#[frb(ignore)]
pub struct LivekitSession {
    pub room: Arc<Room>,
    events_task: Option<JoinHandle<()>>,
    audio_task: Option<JoinHandle<()>>,
    playback_task: Option<JoinHandle<()>>,
    mixer: Option<AudioMixer>,
    audio_playback: Option<AudioPlayback>,
}

impl LivekitSession {
    #[frb(ignore)]
    pub fn new(room: Arc<Room>) -> LivekitSession {
        return LivekitSession {
            room,
            events_task: None,
            audio_task: None,
            playback_task: None,
            mixer: None,
            audio_playback: None,
        };
    }
}

impl LivekitSession {
    #[frb(ignore)]
    pub async fn start(&mut self) {
        let sample_rate = 49000;
        self.mixer = Some(AudioMixer::new(sample_rate, 1, 1.0));

        let mut device: Option<Device> = None;
        let mut stream_config: Option<StreamConfig> = None;
        let mut config: Option<SupportedStreamConfig> = None;

        let host = cpal::default_host();

        println!("Available audio input devices:");
        println!("─────────────────────────────");

        let input_devices = host.input_devices().unwrap();

        for (i, d) in input_devices.enumerate() {
            let name = d.name().unwrap_or_else(|_| "Unknown".to_string());
            println!("{}. {}", i + 1, name);

            if let Ok(s_cfg) = d.default_input_config() {
                println!("   └─ Sample rate: {} Hz", s_cfg.sample_rate());
                println!("   └─ Channels: {}", s_cfg.channels());
                println!("   └─ Sample format: {:?}", s_cfg.sample_format());

                if (name == "pulse") {
                    let cfg = StreamConfig {
                        channels: 1, // Fixed to mono
                        sample_rate: sample_rate,
                        buffer_size: cpal::BufferSize::Default,
                    };

                    device = Some(d);
                    stream_config = Some(cfg);
                    config = Some(s_cfg);

                    // Start audio playback
                }
            }
            println!();
        }

        let playback = AudioPlayback::new(
            device.unwrap(),
            stream_config.unwrap(),
            config.unwrap().sample_format(),
            self.mixer.clone().unwrap(),
        )
        .await;

        self.audio_playback = Some(playback.unwrap());

        self.audio_task = Some(RUNTIME.spawn(Self::handle_remote_audio_streams(
            self.room.clone(),
            self.mixer.clone().unwrap(),
            sample_rate,
        )));
    }

    async fn handle_remote_audio_streams(room: Arc<Room>, mixer: AudioMixer, sample_rate: u32) {
        let mut room_events = room.subscribe();

        info!("Starting remote audio stream handler");

        while let Some(event) = room_events.recv().await {
            match event {
                RoomEvent::ParticipantConnected(participant) => {
                    info!(
                        "Participant connected: {} ({})",
                        participant.identity(),
                        participant.name()
                    );
                }

                RoomEvent::TrackPublished {
                    participant,
                    publication,
                } => {
                    info!(
                        "Track published by {}: {} ({:?})",
                        participant.identity(),
                        publication.name(),
                        publication.kind()
                    );
                }

                RoomEvent::TrackSubscribed {
                    track, participant, ..
                } => {
                    info!(
                        "Track subscribed from {}: {} ({:?})",
                        participant.identity(),
                        track.name(),
                        track.kind()
                    );

                    if let livekit::track::RemoteTrack::Audio(audio_track) = track {
                        let participant_identity = participant.identity().to_string();
                        info!(
                            "Setting up audio stream for participant: {}",
                            participant_identity
                        );

                        // Create audio stream for this remote track (fixed to 1 channel)
                        let mut audio_stream = NativeAudioStream::new(
                            audio_track.rtc_track(),
                            sample_rate as i32,
                            1, // Fixed to mono
                        );

                        // Start processing audio frames from this participant
                        let stream_key = participant_identity.clone();
                        let mixer_clone = mixer.clone();

                        tokio::spawn(async move {
                            info!(
                                "Starting audio stream processing for participant: {}",
                                stream_key
                            );

                            while let Some(audio_frame) = audio_stream.next().await {
                                // Add this participant's audio to the mixer
                                mixer_clone.add_audio_data(audio_frame.data.as_ref());
                            }

                            info!("Audio stream ended for participant: {}", stream_key);
                        });
                    }
                }

                RoomEvent::TrackUnsubscribed {
                    track, participant, ..
                } => {
                    info!(
                        "Track unsubscribed from {}: {} ({:?})",
                        participant.identity(),
                        track.name(),
                        track.kind()
                    );

                    if let livekit::track::RemoteTrack::Audio(_) = track {
                        let participant_identity = participant.identity().to_string();
                        info!(
                            "Stopping audio stream for participant: {}",
                            participant_identity
                        );

                        // Audio stream will be automatically cleaned up when the task ends
                    }
                }

                RoomEvent::ParticipantDisconnected(participant) => {
                    let participant_identity = participant.identity().to_string();
                    info!("Participant disconnected: {}", participant_identity);

                    // Audio stream will be automatically cleaned up when the task ends
                }

                _ => {
                    // Handle other room events as needed
                    debug!("Room event: {:?}", event);
                }
            }
        }
    }
}
