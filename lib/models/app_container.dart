/// 应用容器模型类
/// 
/// 表示一个 Windows 应用容器及其回环豁免状态
class AppContainer {
  /// 应用容器名称
  final String appContainerName;
  
  /// 显示名称
  final String displayName;
  
  /// 包系列名称（Package Family Name）
  final String packageFamilyName;
  
  /// 应用描述
  final String description;
  
  /// 应用容器 SID（安全标识符）字符串
  final String appContainerSid;
  
  /// 是否已启用回环豁免
  final bool isLoopbackEnabled;

  /// 构造函数
  /// 
  /// [appContainerName] 应用容器名称
  /// [displayName] 显示名称
  /// [packageFamilyName] 包系列名称
  /// [description] 应用描述，默认为空
  /// [appContainerSid] 应用容器 SID，默认为空
  /// [isLoopbackEnabled] 是否已启用回环豁免
  AppContainer({
    required this.appContainerName,
    required this.displayName,
    required this.packageFamilyName,
    this.description = '',
    this.appContainerSid = '',
    required this.isLoopbackEnabled,
  });

  /// 复制并修改部分属性
  /// 
  /// 返回一个新的 [AppContainer] 实例，可选择性地更新指定的属性
  AppContainer copyWith({
    String? appContainerName,
    String? displayName,
    String? packageFamilyName,
    String? description,
    String? appContainerSid,
    bool? isLoopbackEnabled,
  }) {
    return AppContainer(
      appContainerName: appContainerName ?? this.appContainerName,
      displayName: displayName ?? this.displayName,
      packageFamilyName: packageFamilyName ?? this.packageFamilyName,
      description: description ?? this.description,
      appContainerSid: appContainerSid ?? this.appContainerSid,
      isLoopbackEnabled: isLoopbackEnabled ?? this.isLoopbackEnabled,
    );
  }
}