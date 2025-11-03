# Windows Loopback Manager

一个 Flutter + Rust 构成的 Windows 环回豁免管理器。

## 项目简介

这是一个使用 Flutter + Rust 开发的 Windows 应用程序，用于管理 Windows UWP 应用的网络环回豁免设置。通过图形界面可以方便地启用或禁用 UWP 应用的本地网络访问权限。

## 技术栈

- **前端框架**: Flutter
- **后端逻辑**: Rust
- **通信桥接**: Rinf
- **国际化**: Slang
- **UI 库**: Fluent UI

## 环境要求

- Flutter SDK (stable channel)
- Rust (stable toolchain)
- Visual Studio 2022 (包含 C++ 桌面开发工作负载)
- Windows 10/11

## 编译准备

### 1. 安装依赖工具

确保已安装以下工具：

- **Flutter**: https://flutter.dev/docs/get-started/install/windows
- **Rust**: https://www.rust-lang.org/tools/install

### 2. 安装 Rinf CLI

```bash
cargo install rinf_cli
```

## 构建步骤

### 1. 克隆项目

```bash
git clone <repository-url>
cd loopback_manager
```

### 2. 生成国际化文件

```bash
dart run slang
```

### 3. 生成 Rust 桥接代码

```bash
rinf gen
```

### 4. 安装 Flutter 依赖

```bash
flutter pub get
```

### 5. 构建项目

#### Debug 版本
```bash
flutter build windows --debug
```

#### Release 版本
```bash
flutter build windows --release
```

构建完成后，可执行文件位于：
- Debug: `build/windows/x64/runner/Debug/loopback_manager.exe`
- Release: `build/windows/x64/runner/Release/loopback_manager.exe`

## 开发工作流

### 代码检查

#### Flutter 代码分析
```bash
flutter analyze
```

#### Dart 代码格式化
```bash
dart format .
```

#### Rust 代码检查
```bash
cd native/hub
cargo clippy --all-targets
cargo fmt
```

### 更新依赖

#### Flutter 依赖
```bash
flutter pub upgrade
```

#### Rust 依赖
```bash
cargo update
```

## 项目结构

```
loopback_manager/
├── lib/                          # Flutter 前端代码
│   ├── main.dart                 # 应用入口
│   ├── i18n/                     # 国际化文件
│   ├── models/                   # 数据模型
│   ├── providers/                # 状态管理
│   ├── services/                 # 业务逻辑服务
│   ├── ui/                       # UI 组件
│   │   ├── components/           # 通用组件
│   │   └── pages/                # 页面
│   ├── widgets/                  # 自定义小部件
│   └── src/bindings/             # Rust 桥接代码（自动生成）
├── native/                       # Rust 后端代码
│   └── hub/
│       ├── src/
│       │   ├── lib.rs            # Rust 入口
│       │   ├── loopback/         # 环回管理逻辑
│       │   └── utils/            # 工具函数
│       └── Cargo.toml            # Rust 依赖配置
├── windows/                      # Windows 平台特定代码
├── .github/                      # GitHub Actions 工作流
│   └── workflows/
│       ├── auto-update-deps.yml  # 自动更新依赖
│       ├── build-release.yml     # 发布构建
│       ├── flutter-checks.yml    # Flutter 代码检查
│       └── rust-checks.yml       # Rust 代码检查
├── pubspec.yaml                  # Flutter 依赖配置
├── Cargo.toml                    # Rust 工作空间配置
└── slang.yaml                    # 国际化配置
```

## 功能特性

- ✅ 列出所有 UWP 应用容器
- ✅ 查看当前环回豁免状态
- ✅ 启用/禁用指定应用的环回访问
- ✅ 批量操作支持
- ✅ 多语言支持（中文/英文）
- ✅ 现代化 Fluent 设计界面

## CI/CD

项目使用 GitHub Actions 进行持续集成：

- **自动更新依赖**: 每周自动检查并更新依赖
- **代码检查**: PR 提交时自动运行 Flutter 和 Rust 代码检查
- **发布构建**: 手动触发构建正式版本

## 注意事项

⚠️ **自动生成文件**: 以下文件由工具自动生成，请勿手动修改：
- `lib/src/bindings/` - Rinf 生成的桥接代码
- `lib/i18n/translations*.g.dart` - Slang 生成的国际化代码

## 许可证

本项目遵循原项目的开源协议。

## 参考资源

- [Windows-Loopback-Exemption-Manager](https://github.com/tiagonmas/Windows-Loopback-Exemption-Manager) - 原始项目
- [Rinf Documentation](https://rinf.cunarist.com/) - Flutter-Rust 通信框架
- [Slang](https://pub.dev/packages/slang) - 类型安全的国际化解决方案
- [Fluent UI](https://pub.dev/packages/fluent_ui) - Windows 风格 UI 库