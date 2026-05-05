use std::{sync::Arc, thread};

use image::GenericImageView;
use log::{error, info};
use serde::{Deserialize, Serialize};
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
mod transceiver;
mod webrtc;

#[derive(Debug)]
enum RuntimeMessage {
    HandleWebIpcCommand(String),
}

#[derive(Debug)]
enum UserEvent {
    ResolvePromise(String, String),
    RaiseEvent(String, String),
    PostMessage(String),
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum IpcMessage {
    Widget { data: String },
    WebRTC { data: String },
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

    let mut title: Option<String> = None;
    let mut url: Option<String> = None;

    for arg in std::env::args() {
        if arg.starts_with("--title=") {
            title = Some(arg["--title=".len()..].to_string());
        }

        if arg.starts_with("--url=") {
            url = Some(arg["--url=".len()..].to_string());
        }
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
            widget_runner::transceiver::read_stdin(event_proxy.clone()).await;

            loop {
                let val = rx.recv().await;

                info!("Handling IPC Request: {:?}", val);

                match val {
                    Some(val) => match val {
                        RuntimeMessage::HandleWebIpcCommand(val) => {
                            let msg = serde_json::from_str::<IpcMessage>(&val).unwrap();

                            match msg {
                                IpcMessage::Widget { data } => {
                                    let result = widget_runner::transceiver::handle(
                                        data,
                                        event_proxy.clone(),
                                    )
                                    .await;

                                    if let Some(result) = result {
                                        event_proxy
                                            .send_event(UserEvent::ResolvePromise(
                                                result.promise_id,
                                                serde_json::to_string(&result.value).unwrap(),
                                            ))
                                            .unwrap();
                                    }
                                }
                                IpcMessage::WebRTC { data } => {
                                    let result =
                                        widget_runner::webrtc::handle(data, event_proxy.clone())
                                            .await;

                                    if let Some(result) = result {
                                        event_proxy
                                            .send_event(UserEvent::ResolvePromise(
                                                result.promise_id,
                                                serde_json::to_string(&result.value).unwrap(),
                                            ))
                                            .unwrap();
                                    }
                                }
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
        .with_title(match title {
            Some(title) => title,
            None => "commet | Widget".to_string(),
        })
        .with_window_icon(icon)
        .with_inner_size(Size::Physical(PhysicalSize::new(1280, 720)))
        .build(&event_loop)
        .unwrap();

    let tx = Arc::new(tx);

    let mut builder = WebViewBuilder::new()
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

    match url {
        Some(url) => builder = builder.with_url(url),
        None => (),
    }

    let widget_runner_script = include_str!("../../../commet/assets/data/widgets_ipc.js");
    let ipc_function_script = include_str!("../javascript/call_ipc.js");

    let mut final_script = widget_runner_script.to_string();
    final_script = final_script.replace("//${SEND_IPC_CODE}", ipc_function_script);

    info!("Initializing with script: {}", final_script);

    builder = builder.with_initialization_script(final_script);

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

    //  #[cfg(any(debug_assertions))]
    //  _webview.open_devtools();

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
                UserEvent::PostMessage(content) => {
                    info!("Handling post message user event");

                    let result =
                        serde_json::to_string(&serde_json::Value::String(content)).unwrap();

                    let js = format!("window.onMessagePolyfill({})", result);

                    info!("Executing: {}", js);

                    view.clone().evaluate_script(js.as_str()).unwrap();
                }
            },
            _ => (),
        }
    });
}
