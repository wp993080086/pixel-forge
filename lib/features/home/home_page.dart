import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/di/providers.dart';
import '../../core/image/image_format.dart';
import '../../core/platform/capabilities.dart';
import '../../services/file/import_service.dart';

/// 首页：图片导入入口 + MVP 功能入口。
///
/// 四个入口对应三个页面：裁剪、尺寸与比例、导出（格式转换与图片压缩共用
/// 同一导出面板，仅默认聚焦的 Tab 不同，见 PRD 四章首 / 十三章）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ImportResult? _imported;

  Future<void> _import() async {
    final result = await ref.read(importServiceProvider).pickImage();
    if (result == null) return;
    setState(() => _imported = result);
  }

  @override
  Widget build(BuildContext context) {
    final caps = ref.watch(capabilitiesProvider);
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
                imported: _imported,
                onImport: _import,
              ),
              const SizedBox(height: 16),
              Text('功能',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _FeatureGrid(),
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
    required this.imported,
    required this.onImport,
  });

  final PlatformCapabilities caps;
  final ImportResult? imported;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final hints = <String>[
      if (caps.dragDropImport) '支持拖拽导入',
      if (caps.pasteImport) '支持粘贴导入',
    ];
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
                      Text('导入图片',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (hints.isNotEmpty)
                        Text(hints.join(' · '),
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.file_open),
                  label: const Text('选择文件'),
                ),
              ],
            ),
            if (imported != null) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(imported!.fileName),
                subtitle: Text(
                  '${imported!.format?.displayName ?? '未知格式'} · ${imported!.sizeDisplay}'
                  '${imported!.format?.supportsAlpha == true ? ' · 含透明通道' : ''}',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
