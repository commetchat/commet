use log::info;
use serde::{Deserialize, Serialize};
use tao::event_loop::EventLoopProxy;
use tokio::io::AsyncBufReadExt;
use tokio::io::{self, AsyncWriteExt, BufReader};

use crate::widget_runner::{webrtc::ResolvedPromise, UserEvent};

#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type")]
pub enum JsToRust {
    PostMessage { message: String },
}

pub async fn read_stdin(event_sender: EventLoopProxy<UserEvent>) {
    tokio::spawn(async move {
        let stdin = io::stdin();
        // Create a buffered wrapper, which implements BufRead
        let reader = BufReader::new(stdin);
        // Take a stream of lines from this
        let mut lines = reader.lines();

        loop {
            let line = lines.next_line().await.unwrap();

            match line {
                Some(line) => {
                    info!("Received line from stdin = {}", line);

                    event_sender
                        .send_event(UserEvent::PostMessage(line))
                        .unwrap();
                }
                None => {
                    info!("Received None from stdin")
                }
            };
        }
    });
}

pub async fn handle(
    command: String,
    event_sender: EventLoopProxy<UserEvent>,
) -> Option<ResolvedPromise> {
    let msg = serde_json::from_str::<JsToRust>(&command).unwrap();
    info!("Received command: {:?}", msg);

    match msg {
        JsToRust::PostMessage { message } => {
            let mut stdout = io::stdout();

            let result = message + "\n";
            let _ = stdout.write_all(result.as_bytes()).await;
            info!("Wrote out data! {}", result);
        }
    }

    None
}
