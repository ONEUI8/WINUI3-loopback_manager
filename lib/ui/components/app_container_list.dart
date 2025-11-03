import 'package:fluent_ui/fluent_ui.dart';
import 'package:loopback_manager/providers/app_provider.dart';
import 'package:loopback_manager/i18n/translations.g.dart';
import 'package:provider/provider.dart';

/// 应用容器列表组件
/// 
/// 以卡片形式展示所有应用容器，支持单个容器的启用/禁用切换
class AppContainerList extends StatelessWidget {
  const AppContainerList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final containers = provider.containers;

        return ListView.builder(
          itemCount: containers.length,
          itemExtent: 130.0,
          itemBuilder: (context, index) {
            final container = containers[index];
            final hasPackageName = container.packageFamilyName.isNotEmpty;
            final theme = FluentTheme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return RepaintBoundary(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  // 根据主题设置背景色
                  color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      // 根据主题设置阴影颜色
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 回环豁免启用/禁用复选框
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Checkbox(
                          checked: container.isLoopbackEnabled,
                          onChanged: (value) {
                            provider.toggleContainerStatus(index);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 容器信息区域
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 应用名称和启用状态标签
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    container.displayName,
                                    style: theme.typography.bodyStrong,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // 已启用标签
                                if (container.isLoopbackEnabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.accentColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      t.enabled,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // 包系列名称或无包名提示
                            if (hasPackageName)
                              Text(
                                container.packageFamilyName,
                                style: theme.typography.caption?.copyWith(
                                      color: Colors.grey[100],
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                            else
                              Text(
                                t.no_package_name,
                                style: theme.typography.caption?.copyWith(
                                      color: Colors.orange,
                                    ),
                              ),
                            // 应用容器名称
                            if (container.appContainerName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${t.ac_name_prefix}${container.appContainerName}',
                                style: theme.typography.caption?.copyWith(
                                      color: Colors.grey[120],
                                      fontSize: 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                            // 应用容器 SID
                            if (container.appContainerSid.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${t.ac_sid_prefix}${container.appContainerSid}',
                                style: theme.typography.caption?.copyWith(
                                      color: Colors.grey[120],
                                      fontSize: 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}