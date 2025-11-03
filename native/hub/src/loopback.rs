//! Windows 回环豁免管理模块
//!
//! 目的：为 Flutter 应用提供 Windows 回环豁免的完整管理能力

use rinf::DartSignal;
use tokio::spawn;

pub mod api;
pub mod messages;

pub use messages::{GetAppContainers, SaveConfiguration, SetLoopback};

/// 启动所有回环管理相关消息监听器
///
/// 目的：建立 Dart 与 Rust 之间的双向通信通道，响应回环管理请求
pub fn init_message_listeners() {
    spawn(async {
        let receiver = GetAppContainers::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            spawn(async move {
                message.handle();
            });
        }
    });

    spawn(async {
        let receiver = SetLoopback::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            spawn(async move {
                message.handle();
            });
        }
    });

    spawn(async {
        let receiver = SaveConfiguration::get_dart_signal_receiver();
        while let Some(dart_signal) = receiver.recv().await {
            let message = dart_signal.message;
            spawn(async move {
                message.handle();
            });
        }
    });
}
