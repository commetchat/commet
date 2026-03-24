use serde::{Deserialize, Serialize};

pub mod data_channels;
pub mod peer_connections;

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum JsToRust {
    CreatePeer {
        id: String,
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
        data: Vec<u8>,
    },
}

pub async fn handle(command: String) {
    #[cfg(not(target_os = "linux"))]
    return;

    let msg = serde_json::from_str::<JsToRust>(&command).unwrap();

    match msg {
        JsToRust::CreatePeer { id } => peer_connections::create(id).await,
        JsToRust::ClosePeer { id } => peer_connections::close(id).await,
        JsToRust::CreateDataChannel { pc_id, id, label } => {
            data_channels::create(pc_id, id, label).await
        }
        JsToRust::CreateOffer { pc_id } => peer_connections::create_offer(&pc_id).await,
        JsToRust::SetLocalDescription { pc_id, sdp } => todo!(),
        JsToRust::SetRemoteDescription { pc_id, sdp } => todo!(),
        JsToRust::AddIceCandidate { pc_id, candidate } => todo!(),
        JsToRust::SendData { dc_id, data } => todo!(),
    }
}
