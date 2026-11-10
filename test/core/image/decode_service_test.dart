import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pixel_forge/core/image/decode_service.dart';

/// 生成指定尺寸的真实 PNG 字节。
Uint8List _png(int w, int h) {
  final image = img.Image(width: w, height: h);
  return img.encodePng(image);
}

void main() {
  group('DecodeService', () {
    const service = DecodeService();

    test('解码小图：预览图等于原图尺寸', () async {
      final result = await service.decodePreview(_png(100, 80));
      expect(result, isNotNull);
      expect(result!.sourceSize.width, 100);
      expect(result.sourceSize.height, 80);
      expect(result.previewSize.width, 100);
      expect(result.previewSize.height, 80);
      expect(result.previewPng, isNotEmpty);
    });

    test('大图触发降采样：预览长边为 2048，原图尺寸保留', () async {
      // 5000 × 1000：边长 5000 > 4096，触发降采样
      final result = await service.decodePreview(_png(5000, 1000));
      expect(result, isNotNull);
      expect(result!.sourceSize.width, 5000);
      expect(result.sourceSize.height, 1000);
      expect(result.previewSize.width, 2048);
      expect(result.previewSize.height, 410); // 1000 * 2048/5000 = 409.6 → 410
    });

    test('非图片字节 → 返回 null', () async {
      final result = await service.decodePreview(
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(result, isNull);
    });
  });
}
