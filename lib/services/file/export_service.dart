import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../core/image/image_format.dart';
import 'file_io.dart';

/// 导出请求。
class ExportRequest {
  const ExportRequest({
    required this.suggestedName,
    required this.bytes,
    required this.format,
  });

  final String suggestedName;
  final Uint8List bytes;
  final ImageFormat format;
}

/// 导出结果。
class ExportResult {
  const ExportResult({required this.savedPath});

  /// 保存后的本地路径；Web 端（下载通道）为 null。
  final String? savedPath;
}

/// 图片导出服务：封装各端保存差异（PRD 六.2）。
class ExportService {
  const ExportService();

  /// 唤起系统保存面板并写入文件；用户取消时返回 null。
  Future<ExportResult?> save(ExportRequest request) async {
    final group = XTypeGroup(
      label: request.format.displayName,
      extensions: request.format.extensions,
    );
    final location = await getSaveLocation(
      suggestedName: request.suggestedName,
      acceptedTypeGroups: [group],
    );
    if (location == null) return null;

    await writeBytesToFile(location.path, request.bytes);
    return ExportResult(savedPath: location.path);
  }
}
