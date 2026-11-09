/// 文件字节写入的平台隔离层。
///
/// Web 端没有文件系统，导出走下载通道（TODO，见 PRD 附录 #10）；
/// 该文件按条件导出实现，避免在 Web 编译时引入 dart:io。
library;

export 'file_io_unsupported.dart' if (dart.library.io) 'file_io_native.dart';
