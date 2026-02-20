use std::{collections::HashMap, str, sync::Arc};

use flutter_rust_bridge::frb;
use livekit::{Room, RoomOptions};
use once_cell::sync::Lazy;
use tokio::{
    runtime::{self, Runtime},
    sync::RwLock,
};

use crate::api::livekit::livekit_session::LivekitSession;

type SessionID = u64;

static SESSIONS: Lazy<RwLock<HashMap<SessionID, LivekitSession>>> =
    Lazy::new(|| RwLock::new(HashMap::new()));

pub static RUNTIME: Lazy<Runtime> = Lazy::new(|| {
    runtime::Builder::new_multi_thread()
        .enable_io()
        .enable_time()
        .build()
        .unwrap()
});

#[derive(Clone)]
pub struct LivekitSessionReference {
    pub id: SessionID,
}

pub struct LivekitRemoteParticipant {
    pub id: String,
}

pub struct LivekitTrack {
    pub id: String,
    pub owner: String,
}

impl LivekitSessionReference {
    #[frb(sync)]
    pub fn remote_tracks(&self) -> Vec<LivekitTrack> {
        let sessions = SESSIONS.blocking_read();

        let session = sessions.get(&self.id);

        let s = match session {
            Some(s) => s,
            None => return Vec::new(),
        };

        let mut result = Vec::new();

        for i in s.room.clone().remote_participants().values() {
            for x in i.track_publications() {
                result.push(LivekitTrack {
                    id: x.0.as_str().to_string(),
                    owner: i.identity().0,
                });
            }
        }

        result
    }
}

#[frb()]
pub async fn create_session(url: String, token: String) -> Option<LivekitSessionReference> {
    _create_session(url, token).await
}

async fn _create_session(url: String, token: String) -> Option<LivekitSessionReference> {
    let (room, _) = match Room::connect(&url, &token, RoomOptions::default()).await {
        Ok(v) => v,
        Err(_) => return None,
    };

    let mut sessions = SESSIONS.write().await;

    let mut id: u64 = rand::random();

    while sessions.contains_key(&id) {
        id = rand::random();
    }

    let session = LivekitSession::new(Arc::new(room));

    sessions.insert(id, session);
    let reference = LivekitSessionReference { id: id };

    RUNTIME.spawn(run_session(reference.clone()));

    Some(reference)
}

async fn run_session(reference: LivekitSessionReference) {
    let mut sessions = SESSIONS.write().await;
    let session = sessions.get_mut(&reference.id).unwrap();

    session.start().await;
}
