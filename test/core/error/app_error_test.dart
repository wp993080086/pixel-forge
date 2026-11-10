import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/core/error/app_error.dart';

void main() {
  group('AppErrorCode', () {
    test('错误码与 PRD 九.2 表一致', () {
      expect(AppErrorCode.unsupportedFormat.code, 'E-IMG-001');
      expect(AppErrorCode.corruptedFile.code, 'E-IMG-002');
      expect(AppErrorCode.unsupportedEncoding.code, 'E-IMG-003');
      expect(AppErrorCode.pixelLimitExceeded.code, 'E-IMG-004');
      expect(AppErrorCode.outOfMemory.code, 'E-IMG-005');
      expect(AppErrorCode.pathNotWritable.code, 'E-EXPORT-001');
      expect(AppErrorCode.diskFull.code, 'E-EXPORT-002');
      expect(AppErrorCode.fileInUse.code, 'E-EXPORT-003');
      expect(AppErrorCode.invalidPath.code, 'E-EXPORT-004');
      expect(AppErrorCode.permissionDenied.code, 'E-EXPORT-005');
      expect(AppErrorCode.encodeFailed.code, 'E-EXPORT-006');
    });

    test('可重试标记与 PRD 九.2 表一致', () {
      // 仅 E-EXPORT-001/002/003/005/006 可重试
      expect(AppErrorCode.pathNotWritable.retryable, isTrue);
      expect(AppErrorCode.diskFull.retryable, isTrue);
      expect(AppErrorCode.fileInUse.retryable, isTrue);
      expect(AppErrorCode.permissionDenied.retryable, isTrue);
      expect(AppErrorCode.encodeFailed.retryable, isTrue);
      // 导入类与 E-EXPORT-004 不可重试
      expect(AppErrorCode.unsupportedFormat.retryable, isFalse);
      expect(AppErrorCode.corruptedFile.retryable, isFalse);
      expect(AppErrorCode.pixelLimitExceeded.retryable, isFalse);
      expect(AppErrorCode.invalidPath.retryable, isFalse);
    });

    test('导出类错误识别', () {
      expect(AppErrorCode.encodeFailed.isExportError, isTrue);
      expect(AppErrorCode.diskFull.isExportError, isTrue);
      expect(AppErrorCode.corruptedFile.isExportError, isFalse);
    });
  });

  group('AppFailure', () {
    test('上下文插值：无占位符时上下文不影响文案', () {
      const failure = AppFailure(
        AppErrorCode.pixelLimitExceeded,
        context: {'像素': '120MP', '上限': '100MP'},
      );
      // 默认文案无 {{}} 占位符，插值后保持原文，且不残留占位符语法
      expect(failure.message, AppErrorCode.pixelLimitExceeded.userMessage);
      expect(failure.message.contains('{{'), isFalse);
    });

    test('无上下文时返回默认文案', () {
      const failure = AppFailure(AppErrorCode.corruptedFile);
      expect(failure.message, '文件已损坏或不是有效图片');
    });
  });
}
