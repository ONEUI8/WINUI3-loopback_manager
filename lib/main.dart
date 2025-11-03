import 'dart:io';
import 'package:rinf/rinf.dart';
import 'src/bindings/bindings.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loopback_manager/providers/app_provider.dart';
import 'package:loopback_manager/ui/pages/home_page.dart';
import 'package:loopback_manager/widgets/title_bar.dart';
import 'package:loopback_manager/utils/logger.dart';
import 'package:loopback_manager/i18n/translations.g.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

/// 应用程序主入口函数
/// 
/// 初始化 Rust 后端、窗口管理器和多语言系统
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  Logger.info('回环管理器启动中...');
  
  // 初始化 Rust 后端通信
  await initializeRust(assignRustSignal);
  Logger.info('Rust 后端初始化完成');
  
  // 使用设备默认语言
  LocaleSettings.useDeviceLocale();
  
  // 桌面平台窗口配置
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    const windowOptions = WindowOptions(
      size: Size(900, 600),
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      Logger.info('窗口已显示并获得焦点');
    });
  }
  
  runApp(TranslationProvider(child: const LoopbackManagerApp()));
}

/// 回环管理器应用程序根组件
/// 
/// 配置应用主题、多语言和全局状态管理
class LoopbackManagerApp extends StatelessWidget {
  const LoopbackManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return FluentApp(
            debugShowCheckedModeBanner: false,
            title: 'Windows Loopback Manager',
            // 亮色主题配置
            theme: FluentThemeData(
              brightness: Brightness.light,
              accentColor: Colors.blue,
              cardColor: const Color(0xFFF3F3F3),
              scaffoldBackgroundColor: const Color(0xFFF3F3F3),
            ),
            // 暗色主题配置
            darkTheme: FluentThemeData(
              brightness: Brightness.dark,
              accentColor: Colors.blue,
              cardColor: const Color(0xFF202020),
              scaffoldBackgroundColor: const Color(0xFF202020),
            ),
            themeMode: appProvider.themeMode,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppScaffold(),
          );
        },
      ),
    );
  }
}

/// 应用程序脚手架组件
/// 
/// 组合自定义标题栏和主页面
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 仅在桌面平台显示自定义标题栏
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          const CustomTitleBar(),
        const Expanded(child: HomeScreen()),
      ],
    );
  }
}