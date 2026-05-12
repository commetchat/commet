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
    ice_servers: Vec<RTCIceServer>,
    event_sender: EventLoopProxy<UserEvent>,
) {
    info!("Creating peer connection: {}", id);
    info!("Creating with ice servers: {:?}", ice_servers);
    let api = APIBuilder::new().build();

    let config = RTCConfiguration {
        ice_servers: ice_servers,
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

    let event_id = event_callback_id.clone();
    connection.connection.on_data_channel(Box::new(move |e| {
        info!("Data channel opened! {}", e.label());

        let id = Uuid::new_v4().to_string();

        data_channels::register_data_channel_callbacks(&c, id.clone(), e.clone());

        data_channels::insert(id, e.clone());

        Box::pin(async {})
    }));

    let event_id = event_callback_id.clone();
    let sender = event_sender.clone();

    connection
        .connection
        .on_ice_gathering_state_change(Box::new(move |e| {
            info!(
                "Ice gathering state chenged: {:?}  ({})",
                e,
                event_id.clone()
            );

            let val = json!({
                "event_type": "icegatheringstatechange",
                "event_data": {
                    "type": "icegatheringstatechange",
                    "iceGatheringState": match e {
                        webrtc::ice_transport::ice_gatherer_state::RTCIceGathererState::Unspecified => "unspecified",
                        webrtc::ice_transport::ice_gatherer_state::RTCIceGathererState::New => "new",
                        webrtc::ice_transport::ice_gatherer_state::RTCIceGathererState::Gathering => "gathering",
                        webrtc::ice_transport::ice_gatherer_state::RTCIceGathererState::Complete => "complete",
                        webrtc::ice_transport::ice_gatherer_state::RTCIceGathererState::Closed => "closed",
                    },
                }
            });

            let val_str = serde_json::to_string(&val).unwrap();

            let _ =
                sender.send_event(UserEvent::RaiseEvent(event_id.clone(), val_str));

            Box::pin(async {})
        }));

    let event_id = event_callback_id.clone();
    let sender = event_sender.clone();


    connection
        .connection
        .on_ice_connection_state_change(Box::new(move |e| {
            info!(
                "Ice connection state changed: {:?}  ({})",
                e,
                event_id.clone()
            );

            

            let val = json!({
                "event_type": "iceconnectionstatechanged",
                "event_data": {
                    "type": "iceconnectionstatechanged",
                    "iceConnectionState": match e {
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Unspecified => "unspecified",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::New => "new",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Checking => "checking",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Connected => "connected",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Completed => "completed",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Disconnected => "disconnected",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Failed => "failed",
                        webrtc::ice_transport::ice_connection_state::RTCIceConnectionState::Closed => "closed",
                    },
                }
            });

            let val_str = serde_json::to_string(&val).unwrap();

            let _ =
                sender.send_event(UserEvent::RaiseEvent(event_id.clone(), val_str));

            Box::pin(async {})
        }));

    let event_id = event_callback_id.clone();
    let sender = event_sender.clone();

    connection
        .connection
        .on_negotiation_needed(Box::new(move || {
            info!(
                "Ice negotiation needed",
            );

                let val = json!({
                "event_type": "negotiationneeded",
                "event_data": {
                    "type": "negotiationneeded",

                }
            });

            let val_str = serde_json::to_string(&val).unwrap();

            let _ =
                sender.send_event(UserEvent::RaiseEvent(event_id.clone(), val_str));


            Box::pin(async {})
        }));

    let event_id = event_callback_id.clone();
    let sender = event_sender.clone();


    connection.connection.on_signaling_state_change(Box::new(move |e| {
            info!(
                "Ice gathering state chenged: {:?}  ({})",
                e,
                event_id.clone()
            );

            let val = json!({
                "event_type": "signalingstatechange",
                "event_data": {
                    "type": "signalingstatechange",
                    "signalingState": match e {
                        webrtc::peer_connection::signaling_state::RTCSignalingState::Unspecified => "unspecified",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::Stable => "stable",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::HaveLocalOffer => "have-local-offer",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::HaveRemoteOffer => "have-remote-offer",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::HaveLocalPranswer => "have-local-pranswer",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::HaveRemotePranswer => "have-local-pranswer",
                        webrtc::peer_connection::signaling_state::RTCSignalingState::Closed => "closed",
                    },
                }
            });

            let val_str = serde_json::to_string(&val).unwrap();

            let _ =
                sender.send_event(UserEvent::RaiseEvent(event_id.clone(), val_str));

            Box::pin(async {})
        }));

    let event_id = event_callback_id.clone();
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
                    "event_type": "icecandidate",
                    "event_data": {
                        "type": "icecandidate",
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
                });

                let val_str = serde_json::to_string(&val).unwrap();

                let _ = event_sender
                    .send_event(UserEvent::RaiseEvent(event_callback_id.clone(), val_str));
            }
            None => {
                let val = json!({
                    "event_type": "icecandidate",
                    "event_data": {
                        "type": "icecandidate",
                        "candidate": serde_json::Value::Null
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


pub async fn create_answer(id: &String, promise_id: String) -> ResolvedPromise {
    info!("Creating answer for connection: {}", id);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {
            let offer = v.connection.create_answer(None).await;

            match offer {
                Ok(offer) => {

                    
                    return ResolvedPromise {
                        promise_id,
                        value: json!({
                            "sdp": offer.clone().sdp
                        }),
                    };
                },
                Err(e) => return ResolvedPromise {
                        promise_id,
                        value: json!({
                            "error": format!("{}", e)
                        }),
                    },
            }
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
    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(conn) => {
            let stats = conn.connection.get_stats().await;

            let mut root = Map::<String, serde_json::Value>::new();

            for report in stats.reports {
                let id = report.0.clone();

                let m = serde_json::to_value(report.1);

                match m {
                    Ok(val) => {
                        root.insert(id, val);
                    }
                    Err(_) => todo!(),
                }
            }

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

pub async fn set_remote_description(id: &String, sdp: String, description_type: String) {
    info!("Setting remote description: {} -> {}", id, sdp);

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(v) => {

            let desc = match description_type.as_str() {
                "offer" => RTCSessionDescription::offer(sdp).unwrap(),
                "answer" => RTCSessionDescription::answer(sdp).unwrap(),
                _=>panic!()
            };

            let _ = v
                .connection
                .set_remote_description(desc)
                .await;
        }
        None => {}
    }
}

pub async fn set_local_description(id: &String, sdp: Option<String>) {
    info!("Setting local description: {} {:?}", id, sdp);

    let conn = internal_get_peer_connection(id).await;

    match sdp {
        Some(sdp)    => {
            match conn {
            
                Some(v) => {
                    let _ = v
                    .connection
                    .set_local_description(RTCSessionDescription::offer(sdp).unwrap())
                    .await;
            }
            None => (),
        }
    },
    None => {

        info!("Did not receive local description, so generating one instead");

    let conn = internal_get_peer_connection(id).await;

    match conn {
        Some(c) => {
            let offer = c.connection.create_offer(None).await.unwrap();
            c.connection.set_local_description(offer).await.unwrap();
        },
        None => (),
    }
    },
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
