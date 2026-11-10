import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/core/image/format_detector.dart';
import 'package:pixel_forge/core/image/image_format.dart';

/// 构造带 PNG 签名的字节流。
Uint8List _pngBytes({List<int> chunks = const []}) {
  final b = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  b.addAll(chunks);
  return Uint8List.fromList(b);
}

/// 构造一个 PNG chunk：[长度][类型][数据][CRC]。
List<int> _chunk(String type, {List<int> data = const []}) {
  final len = data.length;
  return [
    (len >> 24) & 0xFF, (len >> 16) & 0xFF, (len >> 8) & 0xFF, len & 0xFF,
    ...type.codeUnits,
    ...data,
    0, 0, 0, 0, // CRC 占位
  ];
}

void main() {
  group('ImageFormatDetector - 基础魔数', () {
    test('JPEG', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
      );
      expect(d?.format, ImageFormat.jpeg);
    });

    test('PNG（无 acTL）', () {
      final d = ImageFormatDetector.detect(
        _pngBytes(chunks: _chunk('IHDR', data: List.filled(13, 0))),
      );
      expect(d?.format, ImageFormat.png);
      expect(d?.isAnimated, isFalse);
    });

    test('APNG：含 acTL 识别为动图', () {
      final d = ImageFormatDetector.detect(
        _pngBytes(
          chunks: [
            ..._chunk('acTL', data: List.filled(8, 0)),
            ..._chunk('IHDR', data: List.filled(13, 0)),
          ],
        ),
      );
      expect(d?.format, ImageFormat.apng);
      expect(d?.isAnimated, isTrue);
    });

    test('GIF 静态', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00]),
      );
      expect(d?.format, ImageFormat.gif);
      expect(d?.isAnimated, isFalse);
    });

    test('GIF 动图：多个图像描述符', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([
          0x47, 0x49, 0x46, 0x38, 0x39, 0x61, // GIF89a
          0x2C, 0x00, 0x2C, // 两个 0x2C
        ]),
      );
      expect(d?.format, ImageFormat.gif);
      expect(d?.isAnimated, isTrue);
    });

    test('WebP 静态（RIFF....WEBP）', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([
          0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, // RIFF + size
          0x57, 0x45, 0x42, 0x50, // WEBP
        ]),
      );
      expect(d?.format, ImageFormat.webp);
      expect(d?.isAnimated, isFalse);
    });

    test('WebP 动图：VP8X 带 ANIM 位', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([
          0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00,
          0x57, 0x45, 0x42, 0x50,
          // VP8X chunk：类型 + 4 字节长度 + 数据首字节 flags=0x02(ANIM)
          ...'VP8X'.codeUnits, 10, 0, 0, 0, 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]),
      );
      expect(d?.format, ImageFormat.webp);
      expect(d?.isAnimated, isTrue);
    });

    test('BMP', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0x42, 0x4D, 0x00, 0x00]),
      );
      expect(d?.format, ImageFormat.bmp);
    });

    test('ICO', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0x00, 0x00, 0x01, 0x00, 0x01, 0x00]),
      );
      expect(d?.format, ImageFormat.ico);
    });

    test('TIFF 小端 / 大端', () {
      expect(
        ImageFormatDetector.detect(
          Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]),
        )?.format,
        ImageFormat.tiff,
      );
      expect(
        ImageFormatDetector.detect(
          Uint8List.fromList([0x4D, 0x4D, 0x00, 0x2A]),
        )?.format,
        ImageFormat.tiff,
      );
    });

    test('PPM（P6 + 空白）', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0x50, 0x36, 0x0A, 0x31, 0x20]),
      );
      expect(d?.format, ImageFormat.ppm);
    });

    test('SVG：直接以 <svg 开头', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList('<svg xmlns="..."></svg>'.codeUnits),
      );
      expect(d?.format, ImageFormat.svg);
    });

    test('SVG：XML 序言后首个元素为 <svg', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList('<?xml version="1.0"?>\n<svg>'.codeUnits),
      );
      expect(d?.format, ImageFormat.svg);
    });

    test('SVG：带 UTF-8 BOM', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ...'<svg>'.codeUnits]),
      );
      expect(d?.format, ImageFormat.svg);
    });

    test('TGA：文件尾含 TRUEVISION-XFILE', () {
      final footer = 'TRUEVISION-XFILE'.codeUnits;
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0, 0, 0, ...footer, 0x2E, 0x00]),
      );
      expect(d?.format, ImageFormat.tga);
    });
  });

  group('ImageFormatDetector - 边界', () {
    test('空字节 / 过短返回 null', () {
      expect(ImageFormatDetector.detect(Uint8List(0)), isNull);
      expect(ImageFormatDetector.detect(Uint8List.fromList([0x00])), isNull);
    });

    test('无法识别的内容返回 null（走 E-IMG-002）', () {
      final d = ImageFormatDetector.detect(
        Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05]),
      );
      expect(d, isNull);
    });

    test('伪造扩展名不参与判定：PNG 内容始终识别为 PNG', () {
      // 模拟把 PNG 改名为 .jpg 后传入的字节流
      final d = ImageFormatDetector.detect(
        _pngBytes(chunks: _chunk('IHDR', data: List.filled(13, 0))),
      );
      expect(d?.format, ImageFormat.png);
    });
  });
}
