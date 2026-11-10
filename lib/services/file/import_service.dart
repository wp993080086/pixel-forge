import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../core/image/image_format.dart';
import '../../core/image/format_detector.dart';
import '../../core/platform/capabilities.dart';

/// 导入结果。
class ImportResult {
  const ImportResult({
    required this.fileName,
    required this.bytes,
    required this.format,
    required this.isAnimated,
    required this.extensionMismatch,
  });

  final String fileName;
  final Uint8List bytes;

  /// 格式：优先按文件内容（magic bytes）判定，无法识别时回退扩展名（PRD 一.5）。
  final ImageFormat? format;

  /// 是否为动图（APNG / 动图 WebP / GIF）。
  final bool isAnimated;

  /// 扩展名与内容不一致（内容可识别且与扩展名推断结果不同）。
  final bool extensionMismatch;

  int get sizeInBytes => bytes.length;

  String get sizeDisplay {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

/// 图片导入服务：封装各端文件选择差异（PRD 六.1）。
class ImportService {
  ImportService(this._capabilities);

  final PlatformCapabilities _capabilities;

  /// 打开系统文件选择器并读取图片字节。
  ///
  /// 用户取消时返回 null。
  /// TODO: Android/鸿蒙走系统文件选择器、Web 增加粘贴导入、
  /// Windows 增加拖拽导入、小程序改相册选择——当前统一走 file_selector。
  Future<ImportResult?> pickImage() async {
    final group = XTypeGroup(
      label: '图片文件',
      extensions: _capabilities.importExtensions,
    );
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final byExt = ImageFormat.fromExtension(ext);
    final detected = ImageFormatDetector.detect(bytes);
    // 以内容为准；内容无法识别时回退扩展名（PRD 一.5）。
    final format = detected?.format ?? byExt;
    return ImportResult(
      fileName: file.name,
      bytes: bytes,
      format: format,
      isAnimated: detected?.isAnimated ?? false,
      extensionMismatch: detected != null && byExt != null && byExt != format,
    );
  }
}
