use std::{collections::HashMap, sync::Arc};

use log::info;
use once_cell::sync::Lazy;
use tokio::sync::Mutex;
use webrtc::data_channel::RTCDataChannel;

use crate::app::webrtc::peer_connections;

static DATA_CHANNELS: Lazy<Mutex<HashMap<String, Arc<RTCDataChannel>>>> = Lazy::new(|| {
    let m = HashMap::new();
    Mutex::new(m)
});

pub async fn create(pc_id: String, id: String, label: String) {
    info!("Creating data channel: {}", label);

    let pc = peer_connections::internal_get_peer_connection(&pc_id).await;

    match pc {
        Some(pc) => {
            let channel = pc.create_data_channel(label.as_str(), None).await;

            let channel = channel.unwrap();

            let mut channels = DATA_CHANNELS.lock().await;

            let key = format!("{}_{}", pc_id, id);

            if channels.contains_key(&key) {
                info!("Data channel {} already exists!", key);
                return;
            }

            info!("Created data channel: {} ({})", key, label);

            channels.insert(key, channel);
        }
        None => todo!(),
    }
}
