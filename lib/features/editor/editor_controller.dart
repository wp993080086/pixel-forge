import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/error/app_error.dart';
import '../../core/image/decode_policy.dart';
import '../../core/image/image_header_probe.dart';
import '../../core/log/app_logger.dart';
import '../../services/file/import_service.dart';
import '../editor/editor_state.dart';

/// 功能页状态机控制器（PRD 九.5）。
///
/// 所有功能页（裁切 / 缩放 / 导出）共用同一状态；
/// 页面间通过 `?tab=` 区分，状态由本控制器持有。
class EditorController extends Notifier<EditorState> {
  static const _tag = 'EditorController';

  @override
  EditorState build() => const EditorState();

  ImportService get _importService => ref.read(importServiceProvider);

  /// 选图 → 探测 → 解码 → 可编辑。
  Future<void> pickAndLoad() async {
    if (state.busy) return;
    state = state.copyWith(
      stage: EditorStage.detecting,
      phase: ProgressPhase.readingFile,
    );
    try {
      final result = await _importService.pickImage();
      if (result == null) {
        // 用户取消：回到空态
        state = state.copyWith(stage: EditorStage.empty);
        return;
      }
      // 内容与扩展名均无法识别 → E-IMG-002
      if (result.format == null) {
        _fail(AppErrorCode.corruptedFile);
        return;
      }
      // 像素预检（PRD 九.3（2））：解码前仅读文件头取宽高，超限直接拒绝。
      // Dart 的 OOM 是进程级 crash、catch 不住，故必须在此前置拦截。
      final dims = ImageHeaderProbe.probe(result.bytes, result.format!);
      if (dims != null) {
        final maxPixels = ref.read(capabilitiesProvider).maxPixels;
        if (DecodePolicy.exceedsLimit(dims, maxPixels)) {
          _fail(
            AppErrorCode.pixelLimitExceeded,
            context: {
              '像素': '${(dims.pixels / 1000000).toStringAsFixed(1)}MP',
              '上限': '${maxPixels ~/ 1000000}MP',
            },
          );
          return;
        }
      }
      // 解码 + 生成预览图（PRD 九.3）：在子 Isolate 执行，UI 不阻塞。
      state = state.copyWith(stage: EditorStage.decoding);
      final decoded = await ref
          .read(decodeServiceProvider)
          .decodePreview(result.bytes);
      if (decoded == null) {
        // 头部可识别但解码失败 → 文件损坏
        _fail(AppErrorCode.corruptedFile);
        return;
      }
      state = state.copyWith(
        stage: EditorStage.editable,
        imported: result,
        decoded: decoded,
        clearFailure: true,
      );
    } catch (e, st) {
      AppLogger.error('导入失败', name: _tag, error: e, stackTrace: st);
      _fail(AppErrorCode.corruptedFile, error: e, stackTrace: st);
    }
  }

  /// 重新选择（错误卡片出口）。
  void reset() => state = const EditorState();

  void _fail(
    AppErrorCode code, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, String>? context,
  }) {
    final failure = AppFailure(
      code,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
    AppLogger.warn('${code.code}: ${failure.message}', name: _tag);
    state = state.copyWith(
      stage: code.isExportError
          ? EditorStage.exportFailed
          : EditorStage.importFailed,
      failure: failure,
    );
  }
}

/// 功能页状态机（PRD 九.5），裁切/缩放/导出三页共用。
final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);
