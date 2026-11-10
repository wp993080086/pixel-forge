import '../../services/file/import_service.dart';
import '../../core/error/app_error.dart';

/// 功能页共用状态机的阶段（对应 PRD 九.5）。
enum EditorStage {
  /// 空态：未选图。
  empty,

  /// 探测中：读取文件头、判定格式。
  detecting,

  /// 解码中：解码 + 生成预览图（进度：读文件/解码/生成预览）。
  decoding,

  /// 可编辑：预览图 + 参数面板 + 实时体积预估。
  editable,

  /// 导出中：重新解码/处理/编码/写入。
  exporting,

  /// 完成态。
  done,

  /// 导入失败态（E-IMG-0xx）。
  importFailed,

  /// 导出失败态（E-EXPORT-0xx）。
  exportFailed,
}

/// 进度阶段文案（PRD 九.3 要求进度条覆盖三段）。
enum ProgressPhase {
  readingFile('载入原图'),
  decoding('载入原图'),
  processing('处理中'),
  writing('写入文件');

  const ProgressPhase(this.label);

  final String label;
}

/// 功能页状态机的不可变状态。
class EditorState {
  const EditorState({
    this.stage = EditorStage.empty,
    this.imported,
    this.failure,
    this.phase = ProgressPhase.readingFile,
    this.progress = 0,
  });

  final EditorStage stage;

  /// 导入结果（探测成功后有值）。
  final ImportResult? imported;

  /// 失败信息（importFailed / exportFailed 时有值）。
  final AppFailure? failure;

  final ProgressPhase phase;

  /// 进度 0.0–1.0。
  final double progress;

  /// 是否处于「中」态——此态禁用输入、不允许返回上一页（PRD 九.5）。
  bool get busy =>
      stage == EditorStage.detecting ||
      stage == EditorStage.decoding ||
      stage == EditorStage.exporting;

  /// 是否可编辑。
  bool get canEdit => stage == EditorStage.editable;

  EditorState copyWith({
    EditorStage? stage,
    ImportResult? imported,
    AppFailure? failure,
    ProgressPhase? phase,
    double? progress,
    bool clearFailure = false,
  }) {
    return EditorState(
      stage: stage ?? this.stage,
      imported: imported ?? this.imported,
      failure: clearFailure ? null : (failure ?? this.failure),
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
    );
  }
}
