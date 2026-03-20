use std::{sync::Arc, thread};

#[cfg(target_os = "linux")]
use ::webrtc::mdns::message::builder;
use log::{error, info};
use tao::{
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoopBuilder},
    platform::unix::{EventLoopBuilderExtUnix, WindowBuilderExtUnix},
    window::WindowBuilder,
};
use tokio::{runtime::Runtime, sync::mpsc};
use wry::WebViewBuilder;

use crate::app;
mod webrtc;

#[derive(Debug)]
enum RuntimeMessage {
    HandleWebIpcCommand(String),
}

pub fn run() {
    stderrlog::new()
        .verbosity(log::LevelFilter::Debug)
        .module(module_path!())
        .init()
        .unwrap();

    let (tx, mut rx) = mpsc::channel::<RuntimeMessage>(32);

    thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_time()
            .enable_io()
            .build()
            .unwrap();
        info!("Spawning tokio runtime");

        rt.block_on(async {
            loop {
                let val = rx.recv().await;

                info!("Handling IPC Request: {:?}", val);

                match val {
                    Some(val) => match val {
                        RuntimeMessage::HandleWebIpcCommand(val) => {
                            app::webrtc::handle(val).await;
                        }
                    },
                    None => (),
                }
            }
        });

        info!("Finished task, shutting down");
    });

    // https://github.com/tauri-apps/tauri/issues/14251#issuecomment-3522660786
    if cfg!(target_os = "linux") {
        std::env::set_var("GDK_BACKEND", "x11");
        std::env::set_var("WAYLAND_DISPLAY", "");
        std::env::set_var("__NV_DISABLE_EXPLICIT_SYNC", "1");
    }

    let event_loop = EventLoopBuilder::new().build();

    let window = WindowBuilder::new()
        .with_skip_taskbar(false)
        .with_decorations(true)
        .build(&event_loop)
        .unwrap();

    let tx = Arc::new(tx);

    let builder = WebViewBuilder::new()
        .with_url("https://draw-bevy.netlify.app/?room=3aefe4fc-8d3b-4ece-9329-cde00d4f688d")
        .with_ipc_handler(move |data| {
            let result = tx
                .clone()
                .blocking_send(RuntimeMessage::HandleWebIpcCommand(data.body().clone()));

            match result {
                Ok(_) => (),
                Err(v) => {
                    error!("Send error: {:#?}", v.0)
                }
            }
        })
        .with_new_window_req_handler(|url, features| {
            println!("new window req: {url} {features:?}");
            wry::NewWindowResponse::Allow
        });

    #[cfg(any(
        target_os = "windows",
        target_os = "macos",
        target_os = "ios",
        target_os = "android"
    ))]
    let _webview = builder.build(&window)?;

    #[cfg(target_os = "linux")]
    let builder =
        builder.with_initialization_script(include_str!("../javascript/webrtc_polyfill.js"));

    let _webview = {
        use tao::platform::unix::WindowExtUnix;
        use wry::WebViewBuilderExtUnix;
        let vbox = window.default_vbox().unwrap();
        builder.build_gtk(vbox).unwrap()
    };

    _webview.open_devtools();

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        if let Event::WindowEvent {
            event: WindowEvent::CloseRequested,
            ..
        } = event
        {
            *control_flow = ControlFlow::Exit;
        }
    });
}
