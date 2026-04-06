use std::{sync::Arc, thread};

use image::GenericImageView;
use log::{error, info};
use tao::{
    dpi::{PhysicalSize, Size},
    event::{Event, WindowEvent},
    event_loop::{ControlFlow, EventLoop, EventLoopBuilder},
    window::{Icon, WindowBuilder},
};

#[cfg(target_os = "windows")]
use tao::platform::windows::WindowBuilderExtWindows;

#[cfg(target_os = "linux")]
use tao::platform::unix::WindowBuilderExtUnix;

use tokio::sync::mpsc;
use wry::WebViewBuilder;

use crate::widget_runner;
mod webrtc;

#[derive(Debug)]
enum RuntimeMessage {
    HandleWebIpcCommand(String),
}

#[derive(Debug)]
enum UserEvent {
    ResolvePromise(String, String),
    RaiseEvent(String, String),
}

pub fn run() {
    stderrlog::new()
        .verbosity(log::LevelFilter::Debug)
        .module(module_path!())
        .init()
        .unwrap();

    // https://github.com/tauri-apps/tauri/issues/14251#issuecomment-3522660786
    if cfg!(target_os = "linux") {
        std::env::set_var("GDK_BACKEND", "x11");
        std::env::set_var("WAYLAND_DISPLAY", "");
        std::env::set_var("__NV_DISABLE_EXPLICIT_SYNC", "1");
    }

    let (tx, mut rx) = mpsc::channel::<RuntimeMessage>(32);

    let event_loop: EventLoop<UserEvent> = EventLoopBuilder::<UserEvent>::with_user_event().build();
    let event_proxy = event_loop.create_proxy();

    thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap();
        info!("Spawning tokio runtime");

        rt.block_on(async {
            loop {
                let val = rx.recv().await;

                // info!("Handling IPC Request: {:?}", val);

                match val {
                    Some(val) => match val {
                        RuntimeMessage::HandleWebIpcCommand(val) => {
                            let result =
                                widget_runner::webrtc::handle(val, event_proxy.clone()).await;

                            if let Some(result) = result {
                                event_proxy
                                    .send_event(UserEvent::ResolvePromise(
                                        result.promise_id,
                                        serde_json::to_string(&result.value).unwrap(),
                                    ))
                                    .unwrap();
                            }
                        }
                    },
                    None => (),
                }
            }
        });

        info!("Finished task, shutting down");
    });

    let img = image::load_from_memory(include_bytes!("../assets/app_icon_rounded.png"));

    let icon = match img {
        Ok(img) => {
            let (width, height) = img.dimensions();
            let rgba = img.into_rgba8();

            Some(Icon::from_rgba(rgba.into_raw(), width, height).expect("Failed to open icon"))
        }
        Err(_) => None,
    };

    let window = WindowBuilder::new()
        .with_skip_taskbar(false)
        .with_decorations(true)
        .with_window_icon(icon)
        .with_inner_size(Size::Physical(PhysicalSize::new(1920, 1080)))
        .build(&event_loop)
        .unwrap();

    let tx = Arc::new(tx);

    let builder = WebViewBuilder::new()
        .with_url("https://draw-bevy.netlify.app/?room=3aefe4fc-8d3b-4ece-9329-cde00d4f688d")
        .with_incognito(true)
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
    let _webview = builder.build(&window).unwrap();

    #[cfg(target_os = "linux")]
    let builder =
        builder.with_initialization_script(include_str!("../javascript/webrtc_polyfill.js"));

    #[cfg(target_os = "linux")]
    let _webview = {
        use tao::platform::unix::WindowExtUnix;
        use wry::WebViewBuilderExtUnix;
        let vbox = window.default_vbox().unwrap();
        builder.build_gtk(vbox).unwrap()
    };

    #[cfg(any(debug_assertions))]
    _webview.open_devtools();

    let view = Arc::new(_webview);

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::WindowEvent { event, .. } => match event {
                WindowEvent::CloseRequested => {
                    *control_flow = ControlFlow::Exit;
                }
                _ => {}
            },
            Event::UserEvent(event) => match event {
                UserEvent::ResolvePromise(id, value) => {
                    view.clone()
                        .evaluate_script(
                            format!("window.toWebView.resolvePromise(\"{}\", {})", id, value)
                                .as_str(),
                        )
                        .unwrap();
                }
                UserEvent::RaiseEvent(callback_id, value) => {
                    view.clone()
                        .evaluate_script(
                            format!(
                                "window.toWebView.invokeEvent(\"{}\", {})",
                                callback_id, value
                            )
                            .as_str(),
                        )
                        .unwrap();
                }
            },
            _ => (),
        }
    });
}
