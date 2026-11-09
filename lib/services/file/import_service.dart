import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../core/image/image_format.dart';
import '../../core/platform/capabilities.dart';

/// 导入结果。
class ImportResult {
  const ImportResult({
    required this.fileName,
    required this.bytes,
    required this.format,
  });

  final String fileName;
  final Uint8List bytes;

  /// 按扩展名推断的格式；未知扩展名时为 null。
  final ImageFormat? format;

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
    return ImportResult(
      fileName: file.name,
      bytes: bytes,
      format: ImageFormat.fromExtension(ext),
    );
  }
}
