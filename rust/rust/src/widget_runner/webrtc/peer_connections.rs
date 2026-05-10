use std::{
    collections::HashMap,
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};

use once_cell::sync::Lazy;

use serde_json::{json, Map};
use tao::event_loop::EventLoopProxy;
use tokio::sync::Mutex;
use uuid::Uuid;
use webrtc::{
    api::APIBuilder,
    ice_transport::ice_server::RTCIceServer,
    peer_connection::{
        configuration::RTCConfiguration, sdp::session_description::RTCSessionDescription,
        RTCPeerConnection,
    },
    stats::StatsReportType,
};

use log::info;

use crate::widget_runner::{
    webrtc::{data_channels, ResolvedPromise},
    UserEvent,
};

#[derive(Clone)]
pub struct PeerConnection {
    pub connection: Arc<RTCPeerConnection>,
    pub event_sender: EventLoopProxy<UserEvent>,
    pub event_callback_id: String,
}

static PEER_CONNECTIONS: Lazy<Mutex<HashMap<String, PeerConnection>>> = Lazy::new(|| {
    let m = HashMap::new();
    Mutex::new(m)
});

pub async fn create(
    id: String,
    event_callback_id: String,
    event_sender: EventLoopProxy<UserEvent>,
) {
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
    let sender = event_sender.clone();

    let connection = PeerConnection {
        event_sender: sender,
        connection: peer_connection,
        event_callback_id: event_callback_id.clone(),
    };

    let mut connections = PEER_CONNECTIONS.lock().await;

    if connections.contains_key(&id) {
        info!("Peer connection {} already exists!", &id);
        return;
    }

    let c = connection.clone();

    connection.connection.on_data_channel(Box::new(move |e| {
        info!("Data channel opened! {}", e.label());

        let id = Uuid::new_v4().to_string();

        data_channels::register_data_channel_callbacks(&c, id.clone(), e.clone());

        data_channels::insert(id, e.clone());

        Box::pin(async {})
    }));

    connection.connection.on_ice_candidate(Box::new(move |e| {
        info!("Received Ice Candidate: {:?}  ({})", e, event_callback_id);

        match e {
            Some(e) => {
                let candidate_type = match e.typ {
                    webrtc::ice_transport::ice_candidate_type::RTCIceCandidateType::Unspecified => {
                        ""
                    }
                    webrtc::ice_transport::ice_candidate_type::RTCIceCandidateType::Host => "host",
                    webrtc::ice_transport::ice_candidate_type::RTCIceCandidateType::Srflx => {
                        "srflx"
                    }
                    webrtc::ice_transport::ice_candidate_type::RTCIceCandidateType::Prflx => {
                        "prflx"
                    }
                    webrtc::ice_transport::ice_candidate_type::RTCIceCandidateType::Relay => {
                        "relay"
                    }
                };

                let protocol_str = match e.protocol {
                    webrtc::ice_transport::ice_protocol::RTCIceProtocol::Unspecified => "",
                    webrtc::ice_transport::ice_protocol::RTCIceProtocol::Udp => "udp",
                    webrtc::ice_transport::ice_protocol::RTCIceProtocol::Tcp => "tcp",
                };

                let candidate_str = format!(
                    "{} {} {} {} {} {} typ {}",
                    e.stats_id,
                    e.component,
                    protocol_str,
                    e.priority,
                    e.address,
                    e.port,
                    candidate_type
                );

                let val = json!({
                    "event_type": "onicecandidate",
                    "event_data": {
                        "type": "icecandidate",
                        "options": {
                            "candidate": {
                                "candidate": candidate_str,
                                "address": e.address,
                                "port": e.port,
                                "priority": e.priority,
                                "protocol":  protocol_str,
                                "relatedAddress": e.related_address,
                                "relatedPort": e.related_port,
                                "type": candidate_type,
                                "foundation": e.foundation,
                            }
                        }
                    }
                });

                let val_str = serde_json::to_string(&val).unwrap();

                let _ = event_sender
                    .send_event(UserEvent::RaiseEvent(event_callback_id.clone(), val_str));
            }
            None => {
                let val = json!({
                    "event_type": "onicecandidate",
                    "event_data": {
                        "type": "icecandidate",
                        "options": {
                            "candidate": serde_json::Value::Null
                        }
                    }
                });

                let val_str = serde_json::to_string(&val).unwrap();

                let _ = event_sender
                    .send_event(UserEvent::RaiseEvent(event_callback_id.clone(), val_str));
            }
        }

        Box::pin(async {})
    }));

    connections.insert(id.clone(), connection);
}

pub async fn close(id: String) {
    info!("Closing peer connection: {}", id);

    let mut connections = PEER_CONNECTIONS.lock().await;

    let connection = connections.remove(&id);

    match connection {
        Some(connection) => connection.connection.close().await.unwrap(),
        None => (),
    }
}

pub async fn create_offer(id: &String, promise_id: String) -> ResolvedPromise {
    info!("Creating offer for connection: {}", id);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {
            let offer = v.connection.create_offer(None).await.unwrap();

            return ResolvedPromise {
                promise_id,
                value: json!({
                    "sdp": offer.clone().sdp
                }),
            };
        }
        None => {
            return ResolvedPromise {
                promise_id,
                value: json!({}),
            }
        }
    }
}

pub async fn add_ice_candidate(id: &String, candidate: String) {
    info!("Adding ice candidate: {} -> {}", id, candidate);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {
            let _ = v
                .connection
                .add_ice_candidate(serde_json::from_str(&candidate).unwrap())
                .await;
        }
        None => {}
    }
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as u64
}

pub async fn get_stats(id: &String, promise_id: String) -> ResolvedPromise {
    info!("Gettings stats");

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(conn) => {
            let stats = conn.connection.get_stats().await;

            let mut root = Map::<String, serde_json::Value>::new();

            for report in stats.reports {
                let id = report.0.clone();

                let value = match report.1 {
                    StatsReportType::InboundRTP(stats) => {
                        json!({
                            "id": stats.id,
                            "type": "inbound-rtp",
                            "timestamp": now_ms(),
                            "ssrc": stats.ssrc,
                            "kind": stats.kind,
                            "packetsReceived": stats.packets_received,
                            "bytesReceived": stats.bytes_received,
                        })
                    }

                    StatsReportType::OutboundRTP(stats) => {
                        json!({
                            "id": stats.id,
                            "type": "outbound-rtp",
                            "timestamp": now_ms(),
                            "ssrc": stats.ssrc,
                            "kind": stats.kind,

                            "packetsSent": stats.packets_sent,
                            "bytesSent": stats.bytes_sent,


                        })
                    }

                    StatsReportType::CandidatePair(stats) => {
                        json!({
                            "id": stats.id,
                            "type": "candidate-pair",
                            "timestamp": now_ms(),

                            "state": stats.state,
                            "nominated": stats.nominated,

                            "bytesSent": stats.bytes_sent,
                            "bytesReceived": stats.bytes_received,

                            "currentRoundTripTime":
                                stats.current_round_trip_time,

                            "localCandidateId": stats.local_candidate_id,
                            "remoteCandidateId": stats.remote_candidate_id,
                        })
                    }

                    StatsReportType::LocalCandidate(stats) => {
                        json!({
                            "id": stats.id,
                            "type": "local-candidate",
                            "timestamp": now_ms(),

                            "candidateType": stats.candidate_type,
                            "ip": stats.ip,
                            "port": stats.port,
                        })
                    }

                    StatsReportType::RemoteCandidate(stats) => {
                        json!({
                            "id": stats.id,
                            "type": "remote-candidate",
                            "timestamp": now_ms(),

                            "candidateType": stats.candidate_type,
                            "ip": stats.ip,
                            "port": stats.port,
                        })
                    }

                    other => {
                        json!({
                            "id": id,
                            "type": format!("{:?}", other),
                        })
                    }
                };

                root.insert(id, value);
            }

            info!("Got stats: {:#?}", root);

            return ResolvedPromise {
                promise_id,
                value: serde_json::Value::Object(root),
            };
        }
        None => {
            return ResolvedPromise {
                promise_id,
                value: json!({}),
            };
        }
    }
}

pub async fn set_remote_description(id: &String, sdp: String) {
    info!("Setting remote description: {} -> {}", id, sdp);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {
            let _ = v
                .connection
                .set_remote_description(RTCSessionDescription::answer(sdp).unwrap())
                .await;
        }
        None => {}
    }
}

pub async fn set_local_description(id: &String, sdp: String) {
    info!("Setting local description: {} {}", id, sdp);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {
            let _ = v
                .connection
                .set_local_description(RTCSessionDescription::offer(sdp).unwrap())
                .await;
        }
        None => (),
    }
}

pub async fn internal_get_peer_connection(id: &String) -> Option<PeerConnection> {
    let connections = PEER_CONNECTIONS.lock().await;
    let conn = connections.get(id);

    match conn {
        Some(v) => Some(v.clone()),
        None => None,
    }
}
