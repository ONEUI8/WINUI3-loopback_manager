import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loopback_manager/models/app_container.dart';
import 'package:loopback_manager/services/loopback_service.dart';
import 'package:loopback_manager/utils/logger.dart';
import 'package:loopback_manager/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用状态管理提供者
/// 
/// 管理应用容器列表、主题模式、语言设置和过滤器状态
class AppProvider extends ChangeNotifier {
  final LoopbackService _loopbackService = LoopbackService();
  
  /// 所有容器列表
  List<AppContainer> _containers = [];
  
  /// 经过过滤的容器列表
  List<AppContainer> _filteredContainers = [];
  
  /// 是否正在加载
  bool _isLoading = false;
  
  /// 搜索查询字符串
  String _searchQuery = '';
  
  /// 是否仅显示已启用的容器
  bool _showOnlyEnabled = false;
  
  /// 主题模式
  ThemeMode _themeMode = ThemeMode.system;

  /// 搜索防抖定时器
  Timer? _debounceTimer;

  /// 获取过滤后的容器列表
  List<AppContainer> get containers => _filteredContainers;
  
  /// 获取加载状态
  bool get isLoading => _isLoading;
  
  /// 获取搜索查询
  String get searchQuery => _searchQuery;
  
  /// 获取仅显示已启用状态
  bool get showOnlyEnabled => _showOnlyEnabled;
  
  /// 获取主题模式
  ThemeMode get themeMode => _themeMode;

  /// 构造函数
  /// 
  /// 初始化 Loopback 服务并加载持久化设置
  AppProvider() {
    _loopbackService.initialize();
    _loadThemeMode();
    _loadLocale();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    Logger.info('已加载主题模式: $_themeMode');
    notifyListeners();
  }

  /// 加载保存的语言设置
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeStr = prefs.getString('locale') ?? 'zh_CN';
    LocaleSettings.setLocale(localeStr == 'en' ? AppLocale.en : AppLocale.zhCn);
    Logger.info('已加载语言: $localeStr');
    notifyListeners();
  }

  /// 设置主题模式
  /// 
  /// [mode] 要设置的主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    Logger.info('主题模式已切换至: $mode');
    notifyListeners();
  }

  /// 设置语言
  /// 
  /// [newLocale] 要设置的新语言
  Future<void> setLocale(AppLocale newLocale) async {
    LocaleSettings.setLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale == AppLocale.en ? 'en' : 'zh_CN');
    Logger.info('语言已切换至: ${newLocale.languageCode}');
    notifyListeners();
  }

  /// 循环切换主题模式
  /// 
  /// 按照 亮色 → 暗色 → 跟随系统 的顺序切换
  void cycleThemeMode() {
    ThemeMode nextMode;
    switch (_themeMode) {
      case ThemeMode.light:
        nextMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        nextMode = ThemeMode.system;
        break;
      case ThemeMode.system:
        nextMode = ThemeMode.light;
        break;
    }
    setThemeMode(nextMode);
  }

  /// 切换语言
  /// 
  /// 在中文和英文之间切换
  void toggleLocale() {
    final currentLocale = LocaleSettings.currentLocale;
    final newLocale = currentLocale == AppLocale.en ? AppLocale.zhCn : AppLocale.en;
    setLocale(newLocale);
  }

  /// 加载所有应用容器
  Future<void> loadContainers() async {
    Logger.info('正在加载容器列表...');
    _isLoading = true;
    notifyListeners();

    try {
      _containers = await _loopbackService.enumAppContainers();
      Logger.info('已加载 ${_containers.length} 个容器');
      _applyFilters();
    } catch (e) {
      Logger.error('加载容器列表时出错: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置搜索查询
  /// 
  /// [query] 搜索关键词
  /// 
  /// 使用 300ms 防抖延迟，避免频繁过滤
  void setSearchQuery(String query) {
    _searchQuery = query;
    Logger.debug('搜索查询已更改: $query');
    
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    // 设置新的防抖定时器
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      notifyListeners();
    });
  }

  /// 设置是否仅显示已启用的容器
  /// 
  /// [value] true 表示仅显示已启用，false 表示显示全部
  void setShowOnlyEnabled(bool value) {
    _showOnlyEnabled = value;
    Logger.debug('仅显示已启用: $value');
    _applyFilters();
    notifyListeners();
  }

  /// 切换指定容器的启用状态
  /// 
  /// [index] 容器在过滤列表中的索引
  void toggleContainerStatus(int index) {
    final container = _filteredContainers[index];
    final originalIndex = _containers.indexWhere(
      (c) => c.packageFamilyName == container.packageFamilyName,
    );
    
    if (originalIndex != -1) {
      _containers[originalIndex] = container.copyWith(
        isLoopbackEnabled: !container.isLoopbackEnabled,
      );
      Logger.debug('已切换 ${container.displayName}: ${!container.isLoopbackEnabled}');
      _applyFilters();
      notifyListeners();
    }
  }

  /// 全选所有容器
  void selectAll() {
    Logger.info('正在全选所有容器');
    _containers = _containers
        .map((c) => c.copyWith(isLoopbackEnabled: true))
        .toList();
    _applyFilters();
    notifyListeners();
  }

  /// 取消全选所有容器
  void deselectAll() {
    Logger.info('正在取消全选所有容器');
    _containers = _containers
        .map((c) => c.copyWith(isLoopbackEnabled: false))
        .toList();
    _applyFilters();
    notifyListeners();
  }

  /// 反选所有容器
  void invertSelection() {
    Logger.info('正在反选容器');
    _containers = _containers
        .map((c) => c.copyWith(isLoopbackEnabled: !c.isLoopbackEnabled))
        .toList();
    _applyFilters();
    notifyListeners();
  }

  /// 保存当前配置到系统
  /// 
  /// 返回 true 表示保存成功，false 表示失败
  Future<bool> saveConfiguration() async {
    Logger.info('正在保存配置...');
    try {
      final result = await _loopbackService.setLoopbackExemption(_containers);
      Logger.info('保存配置结果: $result');
      return result;
    } catch (e) {
      Logger.error('保存配置时出错: $e');
      return false;
    }
  }

  /// 应用搜索和过滤条件
  /// 
  /// 根据搜索查询和"仅显示已启用"过滤器更新显示列表
  void _applyFilters() {
    _filteredContainers = _containers.where((container) {
      final matchesSearch = _searchQuery.isEmpty ||
          container.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          container.packageFamilyName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = !_showOnlyEnabled || container.isLoopbackEnabled;

      return matchesSearch && matchesFilter;
    }).toList();
    Logger.debug('已筛选容器: ${_filteredContainers.length}/${_containers.length}');
  }
}