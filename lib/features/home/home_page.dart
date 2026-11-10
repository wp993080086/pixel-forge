import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/di/providers.dart';
import '../../core/error/app_error.dart';
import '../../core/image/image_format.dart';
import '../../core/platform/capabilities.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_state.dart';

/// 首页：图片导入入口 + MVP 功能入口。
///
/// 四个入口对应三个页面：裁剪、尺寸与比例、导出（格式转换与图片压缩共用
/// 同一导出面板，仅默认聚焦的 Tab 不同，见 PRD 四章首 / 十三章）。
///
/// 导入能力（读取文件头、像素预检、Isolate 解码生成预览图）统一由
/// [editorControllerProvider] 承担，功能页与首页共用同一份状态。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider);
    final state = ref.watch(editorControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('像素工坊')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ImportCard(
                caps: caps,
                state: state,
                onImport: () =>
                    ref.read(editorControllerProvider.notifier).pickAndLoad(),
              ),
              const SizedBox(height: 16),
              Text('功能', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _FeatureGrid(enabled: state.canEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.caps,
    required this.state,
    required this.onImport,
  });

  final PlatformCapabilities caps;
  final EditorState state;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final hints = <String>[
      if (caps.dragDropImport) '支持拖拽导入',
      if (caps.pasteImport) '支持粘贴导入',
    ];
    final imported = state.imported;
    final decoded = state.decoded;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '导入图片',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (hints.isNotEmpty)
                        Text(
                          hints.join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: state.busy ? null : onImport,
                  icon: const Icon(Icons.file_open),
                  label: const Text('选择文件'),
                ),
              ],
            ),
            if (state.busy) ...[
              const Divider(height: 24),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(state.phase.label),
            ],
            if (state.failure != null) ...[
              const Divider(height: 24),
              _ImportFailure(failure: state.failure!, onRetry: onImport),
            ],
            if (imported != null && decoded != null) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(imported.fileName),
                subtitle: Text(
                  '${imported.format?.displayName ?? '未知格式'} · ${imported.sizeDisplay}'
                  ' · ${decoded.sourceSize.width}×${decoded.sourceSize.height}'
                  '${imported.isAnimated ? ' · 动图' : ''}'
                  '${imported.format?.supportsAlpha == true ? ' · 含透明通道' : ''}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 导入失败提示：错误码 + 文案 + 出口按钮（PRD 九.4）。
class _ImportFailure extends StatelessWidget {
  const _ImportFailure({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: scheme.error),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${failure.code.code} ${failure.message}',
                style: TextStyle(color: scheme.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onRetry, child: const Text('重新选择')),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.enabled});

  /// 未导入图片时功能入口置灰（PRD 九.5：可编辑态才允许进入功能页）。
  final bool enabled;

  static const _items = <_FeatureItem>[
    _FeatureItem(Icons.crop, '裁剪', AppRoutes.crop),
    _FeatureItem(Icons.photo_size_select_large, '尺寸与比例', AppRoutes.resize),
    _FeatureItem(Icons.swap_horiz, '格式转换', AppRoutes.exportConvert),
    _FeatureItem(Icons.compress, '图片压缩', AppRoutes.exportCompress),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: [
        for (final item in _items)
          _FeatureCard(
            icon: item.icon,
            title: item.title,
            enabled: enabled,
            onTap: () => context.push(item.route),
          ),
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem(this.icon, this.title, this.route);

  final IconData icon;
  final String title;
  final String route;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
