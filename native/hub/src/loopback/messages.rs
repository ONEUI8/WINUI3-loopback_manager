//! Windows 回环豁免管理消息协议

use super::api;
use rinf::{DartSignal, RustSignal};
use serde::{Deserialize, Serialize};

/// Dart → Rust：获取所有应用容器
#[derive(Deserialize, DartSignal)]
pub struct GetAppContainers;

/// Dart → Rust：设置回环豁免
#[derive(Deserialize, DartSignal)]
pub struct SetLoopback {
    pub package_family_name: String,
    pub enabled: bool,
}

/// Dart → Rust：保存配置
#[derive(Deserialize, DartSignal)]
pub struct SaveConfiguration {
    pub package_family_names: Vec<String>,
}

/// Rust → Dart：应用容器列表
#[derive(Serialize, Deserialize, RustSignal)]
pub struct AppContainersList {
    pub containers: Vec<String>,
}

/// Rust → Dart：单个应用容器信息
#[derive(Serialize, Deserialize, RustSignal)]
pub struct AppContainerInfo {
    pub app_container_name: String,
    pub display_name: String,
    pub package_family_name: String,
    pub sid: Vec<u8>,
    pub sid_string: String,
    pub is_loopback_enabled: bool,
}

/// Rust → Dart：设置回环豁免结果
#[derive(Serialize, Deserialize, RustSignal)]
pub struct SetLoopbackResult {
    pub success: bool,
    pub message: String,
}

/// Rust → Dart：保存配置结果
#[derive(Serialize, Deserialize, RustSignal)]
pub struct SaveConfigurationResult {
    pub success: bool,
    pub message: String,
}

impl GetAppContainers {
    pub fn handle(&self) {
        log::info!("处理获取应用容器请求");
        match api::enumerate_app_containers() {
            Ok(containers) => {
                log::info!("发送 {} 个容器信息到 Dart", containers.len());
                AppContainersList { containers: vec![] }.send_signal_to_dart();

                for c in containers {
                    AppContainerInfo {
                        app_container_name: c.app_container_name,
                        display_name: c.display_name,
                        package_family_name: c.package_family_name,
                        sid: c.sid,
                        sid_string: c.sid_string,
                        is_loopback_enabled: c.is_loopback_enabled,
                    }
                    .send_signal_to_dart();
                }
            }
            Err(e) => {
                log::error!("获取应用容器失败: {}", e);
                AppContainersList { containers: vec![] }.send_signal_to_dart();
            }
        }
    }
}

impl SetLoopback {
    pub fn handle(self) {
        log::info!(
            "处理设置回环豁免请求: {} - {}",
            self.package_family_name,
            self.enabled
        );
        match api::set_loopback_exemption(&self.package_family_name, self.enabled) {
            Ok(()) => {
                log::info!("回环豁免设置成功");
                SetLoopbackResult {
                    success: true,
                    message: "回环豁免设置成功".to_string(),
                }
                .send_signal_to_dart();
            }
            Err(e) => {
                log::error!("回环豁免设置失败: {}", e);
                SetLoopbackResult {
                    success: false,
                    message: e,
                }
                .send_signal_to_dart();
            }
        }
    }
}

impl SaveConfiguration {
    pub fn handle(self) {
        log::info!(
            "处理保存配置请求，启用 {} 个包",
            self.package_family_names.len()
        );
        let containers = match api::enumerate_app_containers() {
            Ok(c) => c,
            Err(e) => {
                log::error!("枚举容器失败: {}", e);
                SaveConfigurationResult {
                    success: false,
                    message: format!("无法枚举容器: {}", e),
                }
                .send_signal_to_dart();
                return;
            }
        };

        let mut errors = Vec::new();
        for container in containers {
            let should_enable = self
                .package_family_names
                .contains(&container.package_family_name);

            if container.is_loopback_enabled != should_enable {
                if let Err(e) =
                    api::set_loopback_exemption(&container.package_family_name, should_enable)
                {
                    log::error!("设置 {} 失败: {}", container.package_family_name, e);
                    errors.push(format!("{}: {}", container.package_family_name, e));
                }
            }
        }

        if errors.is_empty() {
            log::info!("配置保存成功");
            SaveConfigurationResult {
                success: true,
                message: "配置保存成功".to_string(),
            }
            .send_signal_to_dart();
        } else {
            log::warn!("配置保存部分失败: {} 个错误", errors.len());
            SaveConfigurationResult {
                success: false,
                message: format!("部分操作失败:\n{}", errors.join("\n")),
            }
            .send_signal_to_dart();
        }
    }
}
