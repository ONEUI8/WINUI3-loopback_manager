import 'package:flutter/foundation.dart';

/// 日志级别枚举
enum LogLevel { debug, info, warning, error }

/// 自定义日志记录器。
///
/// 仅当应用在调试模式下运行时，此函数才会将消息打印到控制台。
/// 它会自动解析调用堆栈，并将日志来源的文件路径包含在输出中。
class Logger {
  /// 记录调试日志
  /// [message] 要记录的调试消息
  static void debug(Object message) {
    _log(LogLevel.debug, message);
  }

  /// 记录信息日志
  /// [message] 要记录的信息消息
  static void info(Object message) {
    _log(LogLevel.info, message);
  }

  /// 记录警告日志
  /// [message] 要记录的警告消息
  static void warning(Object message) {
    _log(LogLevel.warning, message);
  }

  /// 记录错误日志
  /// [message] 要记录的错误消息
  static void error(Object message) {
    _log(LogLevel.error, message);
  }

  /// 内部日志记录方法
  static void _log(LogLevel level, Object message) {
    if (kDebugMode) {
      // 1. 获取当前调用堆栈
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');

      // 2. 找到调用日志函数的堆栈帧
      String location = "unknown";
      if (frames.length > 2) {
        // 跳过 _log() 和 info()/error() 方法，找到真正的调用者
        final callerFrame = frames[2];

        // 3. 使用正则表达式提取文件路径
        final match = RegExp(
          r'\((package:.+\.dart):\d+:\d+\)',
        ).firstMatch(callerFrame);
        if (match != null && match.groupCount >= 1) {
          final packagePath = match.group(1)!;

          // 4. 提取文件路径（从 package:xxx/ 之后）
          final firstSlashIndex = packagePath.indexOf('/');
          if (firstSlashIndex != -1) {
            final fullPath = packagePath.substring(firstSlashIndex + 1);
            // 将斜杠替换为点，格式化为 lib.xxx.xxx.dart
            location = fullPath.replaceAll('/', '.');
          }
        }
      }

      // 5. 根据日志级别添加前缀
      final prefix = _getLevelPrefix(level);
      print('$prefix $location >> $message');
    }
  }

  /// 获取日志级别前缀
  static String _getLevelPrefix(LogLevel level) {
    // ANSI 颜色代码
    const String green = '\x1B[32m';
    const String yellow = '\x1B[33m';
    const String red = '\x1B[31m';
    const String reset = '\x1B[0m';

    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m[DartDebug]\x1B[0m';
      case LogLevel.info:
        return '$green[DartInfo]$reset';
      case LogLevel.warning:
        return '$yellow[DartWarn]$reset';
      case LogLevel.error:
        return '$red[DartError]$reset';
    }
  }
}