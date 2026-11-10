/// 错误码（对应 PRD 九.2 错误码表）。
///
/// 文案须可本地化（PRD 十六.4），此处 [userMessage] 为默认中文，
/// 接入 ARB 后由 UI 层按 code 取本地化文案。
enum AppErrorCode {
  // --- 导入 / 解码 ---
  unsupportedFormat('E-IMG-001', '暂不支持该图片格式'),
  corruptedFile('E-IMG-002', '文件已损坏或不是有效图片'),
  unsupportedEncoding('E-IMG-003', '暂不支持该图片编码（如 CMYK）'),
  pixelLimitExceeded('E-IMG-004', '图片过大，超出当前设备上限'),
  outOfMemory('E-IMG-005', '图片过大，设备内存不足，请换用更小的图片'),

  // --- 导出 / 保存 ---
  pathNotWritable('E-EXPORT-001', '无法写入该位置，请换一个文件夹'),
  diskFull('E-EXPORT-002', '磁盘空间不足，无法保存'),
  fileInUse('E-EXPORT-003', '文件正被其他程序使用，请关闭后重试'),
  invalidPath('E-EXPORT-004', '文件路径过长或包含非法字符'),
  permissionDenied('E-EXPORT-005', '未获得存储权限，无法保存'),
  encodeFailed('E-EXPORT-006', '导出失败，请尝试降低尺寸或更换格式');

  const AppErrorCode(this.code, this.userMessage);

  /// 错误码，如 `E-IMG-001`。
  final String code;

  /// 默认中文文案（PRD 九.2 表）。
  final String userMessage;

  /// 是否可重试（对应 PRD 九.2 表「可重试」列）。
  bool get retryable => switch (this) {
    pathNotWritable ||
    diskFull ||
    fileInUse ||
    permissionDenied ||
    encodeFailed => true,
    _ => false,
  };

  /// 是否为导出阶段错误（决定错误卡片出口按钮）。
  bool get isExportError => code.startsWith('E-EXPORT');
}

/// 一次失败的结构化描述：错误码 + 可选上下文 + 原始异常。
///
/// 原始异常仅进日志，不直接展示给用户（PRD 九.4）。
class AppFailure {
  const AppFailure(this.code, {this.context, this.error, this.stackTrace});

  final AppErrorCode code;

  /// 结构化上下文，如 `{'像素': '120MP', '上限': '100MP'}`，供文案插值。
  final Map<String, String>? context;

  final Object? error;
  final StackTrace? stackTrace;

  /// 带上下文插值的用户文案。
  String get message {
    var text = code.userMessage;
    context?.forEach((k, v) {
      text = text.replaceAll('{{$k}}', v);
    });
    return text;
  }
}
