import 'package:fluent_ui/fluent_ui.dart';
import 'package:loopback_manager/providers/app_provider.dart';
import 'package:loopback_manager/ui/components/app_container_list.dart';
import 'package:loopback_manager/i18n/translations.g.dart';
import 'package:provider/provider.dart';

/// 主页面组件
/// 
/// 显示应用容器列表，提供搜索、过滤和批量操作功能
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 搜索框控制器
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // 页面加载后立即获取容器列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadContainers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          _buildSearchBar(context),
          _buildActionBar(context),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                
                
                // 显示加载中
                if (provider.isLoading) {
                  return const Center(
                    child: ProgressRing(),
                  );
                }

                // 显示无数据提示
                if (provider.containers.isEmpty) {
                  return Center(
                    child: Text(t.no_apps_found),
                  );
                }

                // 显示容器列表
                return const AppContainerList();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索栏
  /// 
  /// 包含搜索框、"仅显示已启用"筛选和刷新按钮
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextBox(
                  controller: _searchController,
                  placeholder: t.search_applications,
                  onChanged: (value) {
                    context.read<AppProvider>().setSearchQuery(value);
                  },
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(FluentIcons.search),
                  ),
                  suffix: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(FluentIcons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<AppProvider>().setSearchQuery('');
                          },
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Checkbox(
                checked: provider.showOnlyEnabled,
                onChanged: (value) {
                  context.read<AppProvider>().setShowOnlyEnabled(value ?? false);
                },
                content: Text(t.show_only_enabled),
              );
            },
          ),
          const SizedBox(width: 16),
          Button(
            onPressed: () {
              context.read<AppProvider>().loadContainers();
            },
            child: const Icon(FluentIcons.refresh),
          ),
        ],
      ),
    );
  }

  /// 构建操作栏
  /// 
  /// 包含全选、反选、取消全选和保存配置按钮
  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Button(
            onPressed: () {
              context.read<AppProvider>().selectAll();
            },
            child: Text(t.select_all),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: () {
              context.read<AppProvider>().deselectAll();
            },
            child: Text(t.deselect_all),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: () {
              context.read<AppProvider>().invertSelection();
            },
            child: Text(t.invert_selection),
          ),
          const Spacer(),
          Button(
            onPressed: () => _saveConfiguration(context),
            child: Text(t.save_configuration),
          ),
        ],
      ),
    );
  }

  /// 保存配置
  /// 
  /// 显示确认对话框，保存后显示结果
  Future<void> _saveConfiguration(BuildContext context) async {
    final provider = context.read<AppProvider>();
    
    // 显示确认对话框
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(t.save_config_title),
        content: Text(t.save_config_message),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.save),
          ),
        ],
      ),
    );

    // 用户确认后执行保存
    if (result == true && context.mounted) {
      final success = await provider.saveConfiguration();
      
      // 显示保存结果
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: Text(success ? t.success_title : t.error_title),
            content: Text(
              success
                  ? t.config_saved_success
                  : t.config_save_failed,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.ok),
              ),
            ],
          ),
        );
      }
    }
  }
}