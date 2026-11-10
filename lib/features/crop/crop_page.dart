import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_error.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_state.dart';

/// 裁剪功能页（对应 PRD「二、裁剪功能」）。
///
/// 当前阶段只落地「预览 + 原图信息 + 失败出口」，
/// 选区交互（正方形/圆形、像素对齐、拖拽钳制）后续迭代。
class CropPage extends ConsumerWidget {
  const CropPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider);
    void onPick() => ref.read(editorControllerProvider.notifier).pickAndLoad();
    return Scaffold(
      appBar: AppBar(title: const Text('裁剪')),
      body: switch (state.stage) {
        EditorStage.empty => _EmptyView(onPick: onPick),
        EditorStage.detecting ||
        EditorStage.decoding => _BusyView(state: state),
        EditorStage.editable => _PreviewView(state: state),
        _ => _FailureView(state: state, onPick: onPick),
      },
    );
  }
}

/// 空态：引导选图。
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 56,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          const Text('尚未选择图片'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.file_open),
            label: const Text('选择图片'),
          ),
        ],
      ),
    );
  }
}

/// 「中」态：探测/解码进度（PRD 九.3 三段进度）。
class _BusyView extends StatelessWidget {
  const _BusyView({required this.state});

  final EditorState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 240, child: LinearProgressIndicator()),
          const SizedBox(height: 16),
          Text(state.phase.label),
        ],
      ),
    );
  }
}

/// 可编辑态：预览图 + 原图尺寸信息。
class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.state});

  final EditorState state;

  @override
  Widget build(BuildContext context) {
    final decoded = state.decoded!;
    final imported = state.imported!;
    // 预览图坐标 → 原图坐标的换算比例（PRD 二.4 像素对齐基于原图坐标系）。
    final scale = decoded.sourceSize.width / decoded.previewSize.width;
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 8,
            child: Center(
              child: Image.memory(decoded.previewPng, fit: BoxFit.contain),
            ),
          ),
        ),
        Material(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imported.fileName,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '原图 ${decoded.sourceSize.width} × ${decoded.sourceSize.height}'
                  ' · 预览 ${decoded.previewSize.width} × ${decoded.previewSize.height}'
                  '（1 : ${scale.toStringAsFixed(2)}）',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text('选区交互开发中', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 失败态：错误码 + 文案 + 重新选择（PRD 九.4）。
class _FailureView extends StatelessWidget {
  const _FailureView({required this.state, required this.onPick});

  final EditorState state;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failure = state.failure;
    final isExportError = failure?.code.isExportError ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              failure?.code.code ?? AppErrorCode.corruptedFile.code,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              failure?.message ?? AppErrorCode.corruptedFile.userMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPick,
              child: Text(isExportError ? '返回' : '重新选择'),
            ),
          ],
        ),
      ),
    );
  }
}
