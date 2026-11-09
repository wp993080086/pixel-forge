import 'dart:io';
import 'dart:typed_data';

/// 原生端实现：直接写文件系统。
Future<void> writeBytesToFile(String path, Uint8List bytes) async {
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
}
