import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_error.dart';
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
      // TODO: 解码与预览生成（PRD 九.3 延迟渲染）——待解码链路落地后填充，
      // 此处先进入可编辑态以便打通状态流转。
      state = state.copyWith(
        stage: EditorStage.editable,
        imported: result,
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
