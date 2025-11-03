//! 日志系统初始化
//!
//! 目的：配置统一的日志格式，与 Flutter 日志风格保持一致

use env_logger;
use log;
use once_cell::sync::Lazy;
use std::io::Write;

/// 全局日志配置单例
static LOGGER: Lazy<()> = Lazy::new(|| {
    let default_level = if cfg!(debug_assertions) {
        "debug"
    } else {
        "info"
    };
    let env = env_logger::Env::default().default_filter_or(default_level);

    env_logger::Builder::from_env(env)
        .format(|buf, record| {
            let file = record.file().unwrap_or("unknown");
            let path_with_dots = file.replace(['/', '\\'], ".");

            const GREEN: &str = "\x1B[32m";
            const YELLOW: &str = "\x1B[33m";
            const RED: &str = "\x1B[31m";
            const CYAN: &str = "\x1B[36m";
            const RESET: &str = "\x1B[0m";

            let (level_str, color) = match record.level() {
                log::Level::Error => ("RustError", RED),
                log::Level::Warn => ("RustWarn", YELLOW),
                log::Level::Info => ("RustInfo", GREEN),
                log::Level::Debug => ("RustDebug", CYAN),
                log::Level::Trace => ("RustTrace", CYAN),
            };

            writeln!(
                buf,
                "{}[{}]{} {} >> {}",
                color,
                level_str,
                RESET,
                path_with_dots,
                record.args()
            )
        })
        .init();
});

/// 初始化日志系统
///
/// 目的：配置环境日志记录器，支持多次调用而不会 panic
pub fn setup_logger() {
    Lazy::force(&LOGGER);
}
