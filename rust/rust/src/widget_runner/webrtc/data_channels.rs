use std::{collections::HashMap, sync::Arc};

use base64::prelude::*;
use bytes::Bytes;
use log::info;
use once_cell::sync::Lazy;
use serde_json::json;
use tokio::sync::Mutex;
use webrtc::data_channel::RTCDataChannel;

use crate::widget_runner::{
    webrtc::peer_connections::{self, PeerConnection},
    UserEvent,
};

static DATA_CHANNELS: Lazy<Mutex<HashMap<String, Arc<RTCDataChannel>>>> = Lazy::new(|| {
    let m = HashMap::new();
    Mutex::new(m)
});

pub async fn create(pc_id: String, id: String, label: String) {
    info!("Creating data channel: {}", label);

    let pc = peer_connections::internal_get_peer_connection(&pc_id).await;

    match pc {
        Some(pc) => {
            let channel = pc
                .connection
                .create_data_channel(label.as_str(), None)
                .await;

            let channel = channel.unwrap();

            let mut channels = DATA_CHANNELS.lock().await;

            if channels.contains_key(&id) {
                info!("Data channel {} already exists!", id);
                return;
            }

            let e = channel.clone();
            let id2 = id.clone();

            register_data_channel_callbacks(&pc, id2, e);

            info!("Created data channel: {} ({})", id, label);

            channels.insert(id, channel);
        }
        None => todo!(),
    }
}

pub async fn send(data_channel_id: String, data: String) {
    let channels = DATA_CHANNELS.lock().await;
    let channel = channels.get(&data_channel_id);

    match channel {
        Some(channel) => {
            let decoded = BASE64_STANDARD.decode(data);

            match decoded {
                Ok(bytes) => {
                    info!("Sending data: ({}) {}", bytes.len(), hex::encode(&bytes));
                    let _ = channel.send(&Bytes::from(bytes)).await;
                }
                Err(_) => (),
            }
        }
        None => (),
    }
}

pub fn insert(data_channel_id: String, channel: Arc<RTCDataChannel>) {
    let mut channels = DATA_CHANNELS.blocking_lock();

    channels.insert(data_channel_id.clone(), channel);
}

pub fn register_data_channel_callbacks(
    peer_connection: &PeerConnection,
    data_channel_id: String,
    data_channel: Arc<RTCDataChannel>,
) {
    let id = peer_connection.id.clone();
    let id2 = id.clone();

    let sender = peer_connection.event_sender.clone();
    let callback_id = peer_connection.event_callback_id.clone();
    let id = data_channel_id.clone();

    data_channel.on_message(Box::new(move |x| {
        let data = x.data;

        info!(
            "Received Data: ({}) {}",
            data.len(),
            hex::encode(data.clone())
        );

        let val = json!({
            "event_type": "data_channel_on_message",
            "event_data": {
                "channel": id,
                "data":  BASE64_STANDARD.encode(data)
            }
        });

        let val_str = serde_json::to_string(&val).unwrap();

        _ = sender.send_event(UserEvent::RaiseEvent(callback_id.clone(), val_str));

        Box::pin(async {})
    }));

    let sender = peer_connection.event_sender.clone();
    let callback_id = peer_connection.event_callback_id.clone();
    let id = data_channel_id.clone();

    data_channel.on_open(Box::new(move || {
        let val = json!({
            "event_type": "data_channel_opened",
            "event_data": {
                "channel": id
            }
        });

        let val_str = serde_json::to_string(&val).unwrap();

        _ = sender.send_event(UserEvent::RaiseEvent(callback_id.clone(), val_str));

        info!("{} Data channel opened!", id);

        Box::pin(async {})
    }));

    let sender = peer_connection.event_sender.clone();
    let callback_id = peer_connection.event_callback_id.clone();
    let id = data_channel_id.clone();

    data_channel.on_close(Box::new(move || {
        let val = json!({
            "event_type": "data_channel_closed",
            "event_data": {
                "channel": id
            }
        });

        let val_str = serde_json::to_string(&val).unwrap();

        _ = sender.send_event(UserEvent::RaiseEvent(callback_id.clone(), val_str));

        info!("{} Data channel Closed!", id);

        Box::pin(async {})
    }));

    let sender = peer_connection.event_sender.clone();
    let callback_id = peer_connection.event_callback_id.clone();
    let id = data_channel_id.clone();

    data_channel.on_error(Box::new(move |e| {
        info!("{} Data channel error! {}", id, e);

        let val = json!({
            "event_type": "data_channel_error",
            "event_data": {
                "channel": id
            }
        });

        let val_str = serde_json::to_string(&val).unwrap();

        _ = sender.send_event(UserEvent::RaiseEvent(callback_id.clone(), val_str));

        info!("{} Data channel Error!", id);

        Box::pin(async {})
    }));
}
