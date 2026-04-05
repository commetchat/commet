use serde::{Deserialize, Serialize};
use tao::event_loop::EventLoopProxy;

use crate::widget_runner::UserEvent;

pub mod data_channels;
pub mod peer_connections;

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum JsToRust {
    CreatePeer {
        id: String,
        event_callback_id: String,
    },
    ClosePeer {
        id: String,
    },
    CreateDataChannel {
        pc_id: String,
        id: String,
        label: String,
    },
    CreateOffer {
        pc_id: String,
        promise_id: String,
    },
    SetLocalDescription {
        pc_id: String,
        sdp: String,
    },
    SetRemoteDescription {
        pc_id: String,
        sdp: String,
    },
    AddIceCandidate {
        pc_id: String,
        candidate: String,
    },
    SendData {
        dc_id: String,
        data: String,
    },
}

pub struct ResolvedPromise {
    pub promise_id: String,
    pub value: serde_json::Value,
}

pub async fn handle(
    command: String,
    event_sender: EventLoopProxy<UserEvent>,
) -> Option<ResolvedPromise> {
    #[cfg(not(target_os = "linux"))]
    return;

    let msg = serde_json::from_str::<JsToRust>(&command).unwrap();

    match msg {
        JsToRust::CreatePeer {
            id,
            event_callback_id,
        } => peer_connections::create(id, event_callback_id, event_sender).await,
        JsToRust::ClosePeer { id } => peer_connections::close(id).await,
        JsToRust::CreateDataChannel { pc_id, id, label } => {
            data_channels::create(pc_id, id, label).await
        }
        JsToRust::CreateOffer { pc_id, promise_id } => {
            let result = peer_connections::create_offer(&pc_id, promise_id).await;
            return Some(result);
        }
        JsToRust::SetLocalDescription { pc_id, sdp } => {
            peer_connections::set_local_description(&pc_id, sdp).await;
        }
        JsToRust::SetRemoteDescription { pc_id, sdp } => {
            peer_connections::set_remote_description(&pc_id, sdp).await
        }
        JsToRust::AddIceCandidate { pc_id, candidate } => {
            peer_connections::add_ice_candidate(&pc_id, candidate).await;
        }
        JsToRust::SendData { dc_id, data } => data_channels::send(dc_id, data).await,
    };

    None
}
