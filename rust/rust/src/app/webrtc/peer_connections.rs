use std::{collections::HashMap, sync::Arc};

use once_cell::sync::Lazy;

use tokio::sync::Mutex;
use webrtc::{
    api::APIBuilder,
    ice_transport::ice_server::RTCIceServer,
    peer_connection::{configuration::RTCConfiguration, RTCPeerConnection},
};

use log::info;

static PEER_CONNECTIONS: Lazy<Mutex<HashMap<String, Arc<RTCPeerConnection>>>> = Lazy::new(|| {
    let m = HashMap::new();
    Mutex::new(m)
});

pub async fn create(id: String) {
    info!("Creating peer connection: {}", id);

    let api = APIBuilder::new().build();

    let config = RTCConfiguration {
        ice_servers: vec![RTCIceServer {
            urls: vec!["stun:stun.l.google.com:19302".to_owned()],
            ..Default::default()
        }],
        ..Default::default()
    };

    let peer_connection = Arc::new(api.new_peer_connection(config).await.unwrap());

    let mut connections = PEER_CONNECTIONS.lock().await;

    if connections.contains_key(&id) {
        info!("Peer connection {} already exists!", id);
        return;
    }

    peer_connection.on_ice_candidate(Box::new(move |e| {
        info!("Received Ice Candidate: {:?}", e);

        Box::pin(async {})
    }));

    connections.insert(id.clone(), peer_connection);
}

pub async fn close(id: String) {
    info!("Closing peer connection: {}", id);

    let mut connections = PEER_CONNECTIONS.lock().await;

    let connection = connections.remove(&id);

    match connection {
        Some(connection) => connection.close().await.unwrap(),
        None => (),
    }
}

pub async fn create_offer(id: &String) {
    info!("Creating offer for connection: {}", id);
    let connections = PEER_CONNECTIONS.lock().await;
    let conn: Option<&Arc<RTCPeerConnection>> = connections.get(id);

    match conn {
        Some(v) => {
            let offer = v.create_offer(None).await;

            info!("Offer: {}", offer.unwrap().sdp);
        }
        None => (),
    }
}

pub async fn internal_get_peer_connection(id: &String) -> Option<Arc<RTCPeerConnection>> {
    let connections = PEER_CONNECTIONS.lock().await;
    let conn = connections.get(id);

    match conn {
        Some(v) => Some(v.clone()),
        None => None,
    }
}
