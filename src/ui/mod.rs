use std::string::FromUtf8Error;
use eyre::*;
use qmetaobject::prelude::*;
use qmetaobject::QUrl;
use reqwest;
use serde::{Deserialize, Serialize};
use tokio_stream::StreamExt;

qrc!(pub init_resources,
    "src/ui" as "ui" {
        "main.qml",
        "CollectionList.qml",
        "SourceGroupList.qml",
        "transform/PreviewTransform.qml",
        "transform/EditGroupTags.qml",
        "transform/CoverChooser.qml",
    },
    "dist" as "dist" {
        "backend.js",
        "diff.js",
    }
);

#[derive(QObject, Default)]
pub struct StreamHandler {
    base: qt_base_class!(trait QObject),
    url: qt_property!(QString; NOTIFY url_changed),
    url_changed: qt_signal!(url: QString),
    request_body: qt_property!(QString; NOTIFY request_body_changed),
    request_body_changed: qt_signal!(request_body: QString),
    text_chunk_received: qt_signal!(chunk: QString),
    refreshing: qt_property!(bool; NOTIFY refreshing_changed),
    refreshing_changed: qt_signal!(refreshing: bool),
    start_stream: qt_method!(fn start_stream(&self) {
        info!("start_stream called");
        if self.url.is_empty() {
            warn!("url not set");
        }
        if self.request_body.is_empty() {
            warn!("request_body not set");
        }
        let qptr = QPointer::from(&*self);
        let handle_text_chunk = qmetaobject::queued_callback(move |chunk: QString| {
            qptr.as_pinned().map(|this| {
                this.borrow().text_chunk_received(chunk);
            });
        });
        info!("handle_text_chunk initialised");
        let qptr = QPointer::from(&*self);
        let handle_refreshing_change = qmetaobject::queued_callback(move |refreshing: bool| {
            qptr.as_pinned().map(|this| {
                this.borrow_mut().refreshing = refreshing;
                this.borrow().refreshing_changed(refreshing);
            });
        });
        info!("handle_refreshing_change initialised");
        let url = self.url.clone().into();
        info!("url: {}", &url);
        let request_body = self.request_body.clone().into();
        info!("request_body: {}", &request_body);
        std::thread::spawn(move || {
            info!("request thread spawned");
            post_request(url, request_body, handle_text_chunk, handle_refreshing_change)
        });
    }),
}

#[derive(Serialize)]
struct Request {
    query: String,
}

#[derive(Deserialize)]
struct Response {
    data: Option<serde_json::Value>,
    errors: Option<serde_json::Value>,
}

fn post_request(url: String,
                request_body: String,
                handle_text_chunk: impl Fn(QString) + Send + Sync + Clone + 'static,
                handle_refreshing_change: impl Fn(bool) + Send + Sync + Clone + 'static,
) -> () {
    info!("post_request called");
    let runtime = tokio::runtime::Builder::new_current_thread().enable_all().build().unwrap();
    info!("tokio runtime created");
    runtime.block_on(async move {
        info!("spawned future");
        let request = Request { query: request_body };
        let mut response = match reqwest::Client::builder().build().unwrap()
            .post(url)
            .body(serde_json::to_vec(&request).unwrap())
            .send().await {
            Ok(r) => r,
            Err(e) => {
                error!("failed to send request: {}", e);
                return;
            }
        };
        let mut buf = Vec::new();
        loop {
            match response.chunk().await {
                Err(e) => {
                    error!("Error occurred while streaming results: {}", e);
                    break;
                }
                Ok(None) => {
                    info!("Stream finished");
                    break;
                }
                Ok(Some(chunk)) => {
                    buf.append(&mut chunk.to_vec());
                    if !chunk.ends_with(b"\n\n") {
                        continue;
                    }
                    match String::from_utf8(buf) {
                        Ok(s) => {
                            buf = Vec::new();
                            handle_text_chunk(QString::from(s));
                        }
                        Err(e) => {
                            error!("Response chunk is invalid utf8: {}", e);
                            break;
                        }
                    }
                }
            }
        }
        info!("stream ended");
        handle_refreshing_change(false);
    });
}
