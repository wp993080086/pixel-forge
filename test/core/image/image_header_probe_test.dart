import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/core/image/decode_policy.dart';
import 'package:pixel_forge/core/image/image_format.dart';
import 'package:pixel_forge/core/image/image_header_probe.dart';

/// 构造 PNG 头：签名 + IHDR 长度/类型 + 宽高。
Uint8List _png(int w, int h) {
  final b = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // 签名
    0, 0, 0, 13, // IHDR 长度
    ...'IHDR'.codeUnits,
    (w >> 24) & 0xFF, (w >> 16) & 0xFF, (w >> 8) & 0xFF, w & 0xFF,
    (h >> 24) & 0xFF, (h >> 16) & 0xFF, (h >> 8) & 0xFF, h & 0xFF,
    8, 6, 0, 0, 0, // 位深/颜色类型等占位
  ];
  return Uint8List.fromList(b);
}

void main() {
  group('ImageHeaderProbe', () {
    test('PNG 宽高', () {
      final d = ImageHeaderProbe.probe(_png(1920, 1080), ImageFormat.png);
      expect(d?.width, 1920);
      expect(d?.height, 1080);
      expect(d?.pixels, 1920 * 1080);
    });

    test('GIF 宽高（小端）', () {
      final b = Uint8List.fromList([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
        0x40, 0x01, // 宽 320
        0xF0, 0x00, // 高 240
      ]);
      final d = ImageHeaderProbe.probe(b, ImageFormat.gif);
      expect(d?.width, 320);
      expect(d?.height, 240);
    });

    test('BMP 宽高（高度为负取绝对值）', () {
      final b = Uint8List(30);
      b[0] = 0x42;
      b[1] = 0x4D;
      // 宽 100（偏移 18，小端）
      b[18] = 100;
      // 高 -50（偏移 22，小端补码）
      b[22] = 0xCE;
      b[23] = 0xFF;
      b[24] = 0xFF;
      b[25] = 0xFF;
      final d = ImageHeaderProbe.probe(b, ImageFormat.bmp);
      expect(d?.width, 100);
      expect(d?.height, 50);
    });

    test('JPEG 扫描 SOF0 取宽高', () {
      final b = <int>[
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, 0x00, 0x04, 0x00, 0x00, // APP0 段（长度 4）
        0xFF, 0xC0, 0x00, 0x11, 0x08, // SOF0，长度 17，精度 8
        0x01, 0x2C, // 高 300
        0x01, 0x90, // 宽 400
        0x03, // 分量数
      ];
      final d = ImageHeaderProbe.probe(Uint8List.fromList(b), ImageFormat.jpeg);
      expect(d?.width, 400);
      expect(d?.height, 300);
    });

    test('WebP VP8X 画布尺寸（值 +1）', () {
      final b = Uint8List(32);
      b[12] = 'V'.codeUnitAt(0);
      b[13] = 'P'.codeUnitAt(0);
      b[14] = '8'.codeUnitAt(0);
      b[15] = 'X'.codeUnitAt(0);
      // 宽 99（偏移 24，3 字节小端）→ 实际 100
      b[24] = 99;
      b[25] = 0;
      b[26] = 0;
      // 高 199（偏移 27）→ 实际 200
      b[27] = 199;
      b[28] = 0;
      b[29] = 0;
      final d = ImageHeaderProbe.probe(b, ImageFormat.webp);
      expect(d?.width, 100);
      expect(d?.height, 200);
    });

    test('ICO 宽高（0 表示 256）', () {
      final b = Uint8List(10);
      b[2] = 0x01; // type = icon
      b[6] = 0; // 宽 0 → 256
      b[7] = 64; // 高 64
      final d = ImageHeaderProbe.probe(b, ImageFormat.ico);
      expect(d?.width, 256);
      expect(d?.height, 64);
    });

    test('无法解析的格式返回 null（TGA / PPM / SVG）', () {
      expect(ImageHeaderProbe.probe(Uint8List(64), ImageFormat.tga), isNull);
      expect(ImageHeaderProbe.probe(Uint8List(64), ImageFormat.ppm), isNull);
      expect(ImageHeaderProbe.probe(Uint8List(64), ImageFormat.svg), isNull);
    });

    test('字节不足时返回 null（不抛异常）', () {
      expect(ImageHeaderProbe.probe(Uint8List(4), ImageFormat.png), isNull);
      expect(ImageHeaderProbe.probe(Uint8List(2), ImageFormat.jpeg), isNull);
    });
  });

  group('DecodePolicy', () {
    test('像素上限判定', () {
      const small = ImageDimensions(1000, 1000); // 1MP
      const big = ImageDimensions(6000, 6000); // 36MP
      expect(DecodePolicy.exceedsLimit(small, 32 * 1000 * 1000), isFalse);
      expect(DecodePolicy.exceedsLimit(big, 32 * 1000 * 1000), isTrue);
    });

    test('位图字节估算 = 像素 × 4', () {
      expect(
        DecodePolicy.estimateBitmapBytes(const ImageDimensions(100, 100)),
        40000,
      );
    });

    test('降采样触发条件：边长 > 4096 或像素 > 2000 万', () {
      expect(
        DecodePolicy.needsDownsample(const ImageDimensions(1000, 1000)),
        isFalse,
      );
      expect(
        DecodePolicy.needsDownsample(const ImageDimensions(5000, 100)),
        isTrue,
      );
      expect(
        DecodePolicy.needsDownsample(const ImageDimensions(5000, 5000)),
        isTrue,
      );
    });

    test('不触发降采样时预览图等于原图', () {
      const d = ImageDimensions(1000, 800);
      expect(DecodePolicy.previewSize(d).width, 1000);
      expect(DecodePolicy.previewSize(d).height, 800);
    });

    test('降采样后长边为 2048，且保持宽高比', () {
      const d = ImageDimensions(8000, 4000);
      final p = DecodePolicy.previewSize(d);
      expect(p.width, 2048);
      expect(p.height, 1024);
    });

    test('竖向图片降采样按高为长边', () {
      const d = ImageDimensions(3000, 6000);
      final p = DecodePolicy.previewSize(d);
      expect(p.height, 2048);
      expect(p.width, 1024);
    });
  });
}
