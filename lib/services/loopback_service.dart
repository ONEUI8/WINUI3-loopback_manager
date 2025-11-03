import 'dart:async';
import 'package:loopback_manager/models/app_container.dart';
import 'package:loopback_manager/src/bindings/signals/signals.dart';
import 'package:loopback_manager/utils/logger.dart';

/// 回环豁免服务类
/// 
/// 负责与 Rust 后端通信，管理 Windows 应用容器的回环豁免状态
/// 使用单例模式确保全局只有一个服务实例
class LoopbackService {
  static final LoopbackService _instance = LoopbackService._internal();
  
  /// 获取单例实例
  factory LoopbackService() => _instance;
  
  /// 私有构造函数
  LoopbackService._internal();

  /// 容器信息流控制器
  final _containersController = StreamController<List<AppContainer>>.broadcast();
  
  /// 设置回环豁免结果流控制器
  final _setResultController = StreamController<SetLoopbackResult>.broadcast();
  
  /// 保存配置结果流控制器
  final _saveResultController = StreamController<SaveConfigurationResult>.broadcast();

  /// 容器信息流
  Stream<List<AppContainer>> get containersStream => _containersController.stream;
  
  /// 设置回环豁免结果流
  Stream<SetLoopbackResult> get setResultStream => _setResultController.stream;
  
  /// 保存配置结果流
  Stream<SaveConfigurationResult> get saveResultStream => _saveResultController.stream;

  /// 初始化服务
  /// 
  /// 设置 Rust 信号监听器，接收来自后端的消息
  void initialize() {
    Logger.info('Initializing LoopbackService');
    
    // 监听应用容器信息信号
    AppContainerInfo.rustSignalStream.listen((signal) {
      final container = AppContainer(
        appContainerName: signal.message.appContainerName,
        displayName: signal.message.displayName,
        packageFamilyName: signal.message.packageFamilyName,
        description: '',
        appContainerSid: signal.message.sidString,
        isLoopbackEnabled: signal.message.isLoopbackEnabled,
      );
      _containersController.add([container]);
    });

    // 监听设置回环豁免结果信号
    SetLoopbackResult.rustSignalStream.listen((signal) {
      Logger.info('Received SetLoopbackResult: ${signal.message.success}');
      _setResultController.add(signal.message);
    });

    // 监听保存配置结果信号
    SaveConfigurationResult.rustSignalStream.listen((signal) {
      Logger.info('Received SaveConfigurationResult: ${signal.message.success}');
      _saveResultController.add(signal.message);
    });
  }

  /// 枚举所有应用容器
  /// 
  /// 向 Rust 后端发送请求，获取系统中所有应用容器的列表
  /// 使用超时机制（1秒）来判断接收完成
  /// 
  /// 返回应用容器列表
  Future<List<AppContainer>> enumAppContainers() async {
    Logger.info('Enumerating app containers');
    const GetAppContainers().sendSignalToRust();
    
    final List<AppContainer> allContainers = [];
    final completer = Completer<List<AppContainer>>();
    
    StreamSubscription? subscription;
    Timer? timeoutTimer;
    
    try {
      // 订阅容器信息流
      subscription = AppContainerInfo.rustSignalStream.listen((signal) {
        allContainers.add(AppContainer(
          appContainerName: signal.message.appContainerName,
          displayName: signal.message.displayName,
          packageFamilyName: signal.message.packageFamilyName,
          description: '',
          appContainerSid: signal.message.sidString,
          isLoopbackEnabled: signal.message.isLoopbackEnabled,
        ));
      });
      
      // 设置 1 秒超时，认为接收完成
      timeoutTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!completer.isCompleted) {
          Logger.info('Container enumeration completed: ${allContainers.length} containers');
          completer.complete(allContainers);
        }
      });
      
      return await completer.future;
    } finally {
      await subscription?.cancel();
      timeoutTimer?.cancel();
    }
  }

  /// 设置回环豁免配置
  /// 
  /// 将选中的应用容器列表发送到 Rust 后端，保存回环豁免配置
  /// 
  /// [containers] 所有容器列表（包含启用状态）
  /// 返回 true 表示保存成功，false 表示失败
  Future<bool> setLoopbackExemption(List<AppContainer> containers) async {
    // 筛选出已启用回环豁免的包
    final enabledPackages = containers
        .where((c) => c.isLoopbackEnabled)
        .map((c) => c.packageFamilyName)
        .toList();

    Logger.info('Saving configuration for ${enabledPackages.length} enabled packages');
    
    // 发送保存配置信号到 Rust
    SaveConfiguration(packageFamilyNames: enabledPackages).sendSignalToRust();
    
    // 等待保存结果
    final result = await saveResultStream.first;
    Logger.info('Save result: ${result.success} - ${result.message}');
    return result.success;
  }

  /// 释放资源
  /// 
  /// 关闭所有流控制器
  void dispose() {
    Logger.info('Disposing LoopbackService');
    _containersController.close();
    _setResultController.close();
    _saveResultController.close();
  }
}