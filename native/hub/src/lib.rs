//! Rust 原生模块入口

mod loopback;
mod utils;

use rinf::{dart_shutdown, write_interface};

write_interface!();

#[tokio::main(flavor = "current_thread")]
async fn main() {
    utils::init_logger::setup_logger();

    loopback::init_message_listeners();

    dart_shutdown().await;
}
