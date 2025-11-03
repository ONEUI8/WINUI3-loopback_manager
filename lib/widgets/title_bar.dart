import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:loopback_manager/providers/app_provider.dart';
import 'package:loopback_manager/i18n/translations.g.dart';

/// 自定义标题栏组件
/// 
/// 显示应用标题、主题切换、语言切换和窗口控制按钮
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      height: 40,
      color: theme.cardColor,
      child: WindowTitleBarBox(
        child: Row(
          children: [
            const SizedBox(width: 16),
            // 应用标题
            Text(
              t.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            // 可拖动区域
            Expanded(child: MoveWindow()),
            // 主题切换按钮
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                IconData iconData;
                switch (provider.themeMode) {
                  case ThemeMode.light:
                    iconData = FluentIcons.sunny;
                    break;
                  case ThemeMode.dark:
                    iconData = FluentIcons.clear_night;
                    break;
                  case ThemeMode.system:
                    iconData = FluentIcons.system;
                    break;
                }
                
                return IconButton(
                  icon: Icon(iconData, size: 16),
                  onPressed: () => provider.cycleThemeMode(),
                );
              },
            ),
            // 语言切换按钮
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final currentLocale = LocaleSettings.currentLocale;
                return IconButton(
                  icon: Icon(
                    currentLocale == AppLocale.en 
                        ? FluentIcons.locale_language 
                        : FluentIcons.globe,
                    size: 16,
                  ),
                  onPressed: () => provider.toggleLocale(),
                );
              },
            ),
            // 窗口控制按钮
            const WindowControlButtons(),
          ],
        ),
      ),
    );
  }
}

/// 窗口控制按钮组
/// 
/// 包含最小化、最大化/还原、关闭按钮
class WindowControlButtons extends StatelessWidget {
  const WindowControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final iconColor = theme.resources.textFillColorPrimary;
    
    return Row(
      children: [
        WindowButton(
          icon: FluentIcons.remove,
          onPressed: () => windowManager.minimize(),
          iconColor: iconColor,
        ),
        MaximizeRestoreButton(iconColor: iconColor),
        WindowButton(
          icon: FluentIcons.cancel,
          onPressed: () => windowManager.close(),
          iconColor: iconColor,
          isClose: true,
        ),
      ],
    );
  }
}

/// 窗口按钮组件
/// 
/// 统一的窗口控制按钮样式，支持悬停效果
class WindowButton extends StatefulWidget {
  /// 按钮图标
  final IconData icon;
  
  /// 点击回调
  final VoidCallback onPressed;
  
  /// 图标颜色
  final Color iconColor;
  
  /// 是否为关闭按钮（关闭按钮悬停时显示红色背景）
  final bool isClose;

  const WindowButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.iconColor,
    this.isClose = false,
  });

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  /// 是否悬停
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered
              ? (widget.isClose 
                  ? Colors.red 
                  : theme.resources.subtleFillColorSecondary)
              : Colors.transparent,
          child: Center(
            child: Icon(
              widget.icon,
              size: 14,
              color: _isHovered && widget.isClose ? Colors.white : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 最大化/还原按钮组件
/// 
/// 根据窗口状态自动切换图标
class MaximizeRestoreButton extends StatefulWidget {
  /// 图标颜色
  final Color iconColor;

  const MaximizeRestoreButton({
    super.key,
    required this.iconColor,
  });

  @override
  State<MaximizeRestoreButton> createState() => _MaximizeRestoreButtonState();
}

class _MaximizeRestoreButtonState extends State<MaximizeRestoreButton>
    with WindowListener {
  /// 窗口是否已最大化
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateMaximizeState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    _updateMaximizeState();
  }

  @override
  void onWindowUnmaximize() {
    _updateMaximizeState();
  }

  /// 更新最大化状态
  void _updateMaximizeState() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted && isMaximized != _isMaximized) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WindowButton(
      icon: _isMaximized ? FluentIcons.back_to_window : FluentIcons.full_screen,
      onPressed: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      iconColor: widget.iconColor,
    );
  }
}