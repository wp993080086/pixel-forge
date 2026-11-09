import '../image/image_format.dart';
import 'app_platform.dart';

/// 各端能力矩阵（对应 PRD「七、多端差异化策略」）。
///
/// 界面层据此对不支持的功能做隐藏/置灰，禁止在功能层内散落平台判断。
class PlatformCapabilities {
  const PlatformCapabilities({
    required this.target,
    required this.importFormats,
    required this.exportFormats,
    required this.dragDropImport,
    required this.pasteImport,
    required this.albumPickImport,
    required this.systemSavePanel,
    required this.animatedReencode,
  });

  final AppTarget target;

  /// 【导入支持】格式集合。
  final Set<ImageFormat> importFormats;

  /// 【导出支持】格式集合。
  final Set<ImageFormat> exportFormats;

  /// 拖拽导入（仅 Windows）。
  final bool dragDropImport;

  /// 粘贴图片导入（仅 Web）。
  final bool pasteImport;

  /// 相册选择导入（微信小程序）。
  final bool albumPickImport;

  /// 唤起系统保存面板导出（Web 无此能力，走下载通道）。
  final bool systemSavePanel;

  /// 动图重编码（GIF/APNG 重新导出，高阶可选功能）。
  final bool animatedReencode;

  bool canImport(ImageFormat f) => importFormats.contains(f);

  bool canExport(ImageFormat f) => exportFormats.contains(f);

  /// 所有可导入格式的扩展名并集（供文件选择器过滤）。
  List<String> get importExtensions => [
    for (final f in importFormats) ...f.extensions,
  ];

  /// PRD 七章：按端给出能力矩阵。
  static PlatformCapabilities of(AppTarget target) => switch (target) {
    AppTarget.windows => PlatformCapabilities(
      target: target,
      importFormats: _fullImport,
      exportFormats: {..._mainstreamExport, ImageFormat.ico},
      dragDropImport: true,
      pasteImport: false,
      albumPickImport: false,
      systemSavePanel: true,
      animatedReencode: true,
    ),
    AppTarget.harmony || AppTarget.android => PlatformCapabilities(
      target: target,
      importFormats: _mainstreamImport,
      exportFormats: {..._mainstreamExport, ImageFormat.ico},
      dragDropImport: false,
      pasteImport: false,
      albumPickImport: false,
      systemSavePanel: true,
      animatedReencode: true,
    ),
    AppTarget.web => PlatformCapabilities(
      target: target,
      importFormats: _mainstreamImport,
      exportFormats: _mainstreamExport,
      dragDropImport: false,
      pasteImport: true,
      albumPickImport: false,
      systemSavePanel: false,
      animatedReencode: false,
    ),
    AppTarget.wechatMini => PlatformCapabilities(
      target: target,
      importFormats: _mainstreamImport,
      exportFormats: _mainstreamExport,
      dragDropImport: false,
      pasteImport: false,
      albumPickImport: true,
      systemSavePanel: false,
      animatedReencode: false,
    ),
  };

  /// 主流格式全集（非小众，PRD 一.边界3）。
  static const _mainstreamImport = {
    ImageFormat.jpeg,
    ImageFormat.png,
    ImageFormat.bmp,
    ImageFormat.webp,
    ImageFormat.gif,
    ImageFormat.apng,
    ImageFormat.svg,
    ImageFormat.ico,
  };

  /// 全量导入（含小众格式），仅 Windows 放开。
  static const _fullImport = {
    ..._mainstreamImport,
    ImageFormat.tiff,
    ImageFormat.tga,
    ImageFormat.ppm,
  };

  /// 主流导出格式。
  ///
  /// 不含 WebP：`image` 包只提供 webp 解码器、无编码器，导出能力全端移除
  /// （PRD 一 / 四.5 / 十，决策见 PRD 十二 ADR-001）。
  static const _mainstreamExport = {
    ImageFormat.jpeg,
    ImageFormat.png,
    ImageFormat.bmp,
  };
}
