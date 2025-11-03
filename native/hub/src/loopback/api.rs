#[cfg(windows)]
use std::ptr;
#[cfg(windows)]
use windows::core::PWSTR;
#[cfg(windows)]
use windows::Win32::Foundation::{LocalFree, HLOCAL};
#[cfg(windows)]
use windows::Win32::NetworkManagement::WindowsFirewall::{
    NetworkIsolationEnumAppContainers, NetworkIsolationFreeAppContainers,
    NetworkIsolationGetAppContainerConfig, NetworkIsolationSetAppContainerConfig,
    INET_FIREWALL_APP_CONTAINER,
};
#[cfg(windows)]
use windows::Win32::Security::{PSID, SID, SID_AND_ATTRIBUTES};

#[derive(Debug, Clone)]
pub struct AppContainer {
    pub app_container_name: String,
    pub display_name: String,
    pub package_family_name: String,
    pub sid: Vec<u8>,
    pub sid_string: String,
    pub is_loopback_enabled: bool,
}

#[cfg(windows)]
unsafe fn pwstr_to_string(pwstr: PWSTR) -> String {
    if pwstr.is_null() {
        return String::new();
    }

    pwstr.to_string().unwrap_or_default()
}

#[cfg(windows)]
unsafe fn sid_to_bytes(sid: *mut SID) -> Option<Vec<u8>> {
    if sid.is_null() {
        return None;
    }

    unsafe {
        let sid_ptr = sid as *const u8;
        let length = (*(sid_ptr.offset(1)) as usize) * 4 + 8;
        Some(std::slice::from_raw_parts(sid_ptr, length).to_vec())
    }
}

#[cfg(windows)]
unsafe fn sid_to_string(sid: *mut SID) -> String {
    if sid.is_null() {
        return String::new();
    }

    unsafe {
        let sid_bytes = match sid_to_bytes(sid) {
            Some(bytes) => bytes,
            None => return String::new(),
        };

        if sid_bytes.len() < 8 {
            return String::new();
        }

        let revision = sid_bytes[0];
        let sub_authority_count = sid_bytes[1] as usize;

        if sid_bytes.len() < 8 + (sub_authority_count * 4) {
            return String::new();
        }

        let identifier_authority = u64::from_be_bytes([
            0,
            0,
            sid_bytes[2],
            sid_bytes[3],
            sid_bytes[4],
            sid_bytes[5],
            sid_bytes[6],
            sid_bytes[7],
        ]);

        let mut sid_string = format!("S-{}-{}", revision, identifier_authority);

        for i in 0..sub_authority_count {
            let offset = 8 + (i * 4);
            let sub_authority = u32::from_le_bytes([
                sid_bytes[offset],
                sid_bytes[offset + 1],
                sid_bytes[offset + 2],
                sid_bytes[offset + 3],
            ]);
            sid_string.push_str(&format!("-{}", sub_authority));
        }

        sid_string
    }
}

#[cfg(windows)]
unsafe fn compare_sids(sid1: *mut SID, sid2: *mut SID) -> bool {
    if sid1.is_null() || sid2.is_null() {
        return false;
    }

    unsafe {
        match (sid_to_bytes(sid1), sid_to_bytes(sid2)) {
            (Some(bytes1), Some(bytes2)) => bytes1 == bytes2,
            _ => false,
        }
    }
}

#[cfg(windows)]
pub fn enumerate_app_containers() -> Result<Vec<AppContainer>, String> {
    unsafe {
        log::info!("开始枚举应用容器");
        let mut count: u32 = 0;
        let mut containers: *mut INET_FIREWALL_APP_CONTAINER = ptr::null_mut();

        let result = NetworkIsolationEnumAppContainers(1, &mut count, &mut containers);

        if result != 0 {
            log::error!("枚举应用容器失败: {}", result);
            return Err(format!("Failed to enumerate app containers: {}", result));
        }

        if count == 0 || containers.is_null() {
            log::warn!("未找到任何应用容器");
            return Ok(Vec::new());
        }

        let mut loopback_count: u32 = 0;
        let mut loopback_sids: *mut SID_AND_ATTRIBUTES = ptr::null_mut();
        let _ = NetworkIsolationGetAppContainerConfig(&mut loopback_count, &mut loopback_sids);

        let loopback_slice = if loopback_count > 0 && !loopback_sids.is_null() {
            std::slice::from_raw_parts(loopback_sids, loopback_count as usize)
        } else {
            &[]
        };

        let mut result_containers = Vec::new();
        let container_slice = std::slice::from_raw_parts(containers, count as usize);

        for container in container_slice {
            let app_container_name = pwstr_to_string(container.appContainerName);
            let display_name = pwstr_to_string(container.displayName);
            let package_full_name = pwstr_to_string(container.packageFullName);

            let sid_bytes = sid_to_bytes(container.appContainerSid).unwrap_or_default();
            let sid_string = sid_to_string(container.appContainerSid);

            let is_loopback_enabled = loopback_slice
                .iter()
                .any(|item| compare_sids(item.Sid.0 as *mut SID, container.appContainerSid));

            result_containers.push(AppContainer {
                app_container_name,
                display_name,
                package_family_name: package_full_name,
                sid: sid_bytes,
                sid_string,
                is_loopback_enabled,
            });
        }

        if !loopback_sids.is_null() {
            let _ = LocalFree(HLOCAL(loopback_sids as *mut _));
        }
        NetworkIsolationFreeAppContainers(containers);

        log::info!("成功枚举 {} 个应用容器", result_containers.len());
        Ok(result_containers)
    }
}

#[cfg(windows)]
pub fn set_loopback_exemption(package_family_name: &str, enabled: bool) -> Result<(), String> {
    unsafe {
        log::info!("设置回环豁免: {} - {}", package_family_name, enabled);
        let mut count: u32 = 0;
        let mut containers: *mut INET_FIREWALL_APP_CONTAINER = ptr::null_mut();

        let result = NetworkIsolationEnumAppContainers(1, &mut count, &mut containers);

        if result != 0 {
            log::error!("枚举应用容器失败: {}", result);
            return Err(format!("Failed to enumerate app containers: {}", result));
        }

        if count == 0 || containers.is_null() {
            NetworkIsolationFreeAppContainers(containers);
            log::warn!("未找到任何应用容器");
            return Err("No app containers found".to_string());
        }

        let container_slice = std::slice::from_raw_parts(containers, count as usize);
        let target_sid = container_slice
            .iter()
            .find(|c| pwstr_to_string(c.packageFullName) == package_family_name)
            .map(|c| c.appContainerSid);

        if target_sid.is_none() {
            NetworkIsolationFreeAppContainers(containers);
            log::error!("未找到包: {}", package_family_name);
            return Err(format!("Package not found: {}", package_family_name));
        }

        let mut loopback_count: u32 = 0;
        let mut loopback_sids: *mut SID_AND_ATTRIBUTES = ptr::null_mut();
        let _ = NetworkIsolationGetAppContainerConfig(&mut loopback_count, &mut loopback_sids);

        let loopback_slice = if loopback_count > 0 && !loopback_sids.is_null() {
            std::slice::from_raw_parts(loopback_sids, loopback_count as usize)
        } else {
            &[]
        };

        let target_sid_unwrapped = target_sid.ok_or("Target SID is None")?;

        let mut new_sids: Vec<SID_AND_ATTRIBUTES> = loopback_slice
            .iter()
            .filter(|item| !compare_sids(item.Sid.0 as *mut SID, target_sid_unwrapped))
            .copied()
            .collect();

        if enabled {
            new_sids.push(SID_AND_ATTRIBUTES {
                Sid: PSID(target_sid_unwrapped as *mut _),
                Attributes: 0,
            });
        }

        let result = if new_sids.is_empty() {
            NetworkIsolationSetAppContainerConfig(&[])
        } else {
            NetworkIsolationSetAppContainerConfig(&new_sids)
        };

        if !loopback_sids.is_null() {
            let _ = LocalFree(HLOCAL(loopback_sids as *mut _));
        }
        NetworkIsolationFreeAppContainers(containers);

        if result == 0 {
            log::info!("回环豁免设置成功");
            Ok(())
        } else {
            log::error!("回环豁免设置失败: {}", result);
            Err(format!("Failed to set loopback exemption: {}", result))
        }
    }
}

#[cfg(not(windows))]
pub fn enumerate_app_containers() -> Result<Vec<AppContainer>, String> {
    Err("This function is only available on Windows".to_string())
}

#[cfg(not(windows))]
pub fn set_loopback_exemption(_package_family_name: &str, _enabled: bool) -> Result<(), String> {
    Err("This function is only available on Windows".to_string())
}
