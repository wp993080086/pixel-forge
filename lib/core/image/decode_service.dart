import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'decode_policy.dart';
import 'image_header_probe.dart';

/// 解码结果：预览图 PNG 字节 + 原图尺寸。
class DecodeResult {
  const DecodeResult({
    required this.previewPng,
    required this.sourceSize,
    required this.previewSize,
  });

  /// 预览图（PNG 编码，已降采样），供 UI 直接 `Image.memory` 展示。
  final Uint8List previewPng;

  /// 原图真实尺寸（编辑参数以此为准，而非预览图）。
  final ImageDimensions sourceSize;

  /// 预览图尺寸。
  final ImageDimensions previewSize;
}

/// 图片解码服务：在独立 Isolate 中解码并按策略生成预览图（PRD 八.9 / 九.3）。
///
/// - 解码、缩放、编码全部在子 Isolate 执行，避免阻塞 UI；
/// - 大字节流用 `TransferableTypedData` 零拷贝跨 Isolate 传递；
/// - 预览图降采样规则由 [DecodePolicy] 决定。
class DecodeService {
  const DecodeService();

  /// 解码 [bytes] 并生成预览图。
  ///
  /// 解码失败返回 null（由调用方转为 `E-IMG-002`）。
  /// 像素预检应在此之前完成（见 `EditorController`）。
  Future<DecodeResult?> decodePreview(Uint8List bytes) async {
    // 零拷贝传入子 Isolate
    final transferable = TransferableTypedData.fromList([bytes]);
    return Isolate.run(() => _decodeAndResize(transferable));
  }
}

/// 子 Isolate 入口：解码 → 校正方向 → 按策略降采样 → 编码 PNG。
///
/// 注意：此函数在独立 Isolate 中运行，禁止引用任何 UI / 插件对象。
DecodeResult? _decodeAndResize(TransferableTypedData transferable) {
  final bytes = transferable.materialize().asUint8List();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // 校正 EXIF 方向（PRD 八.6：方向信息在解码时烘焙，不写入导出）
  final oriented = img.bakeOrientation(decoded);
  final sourceSize = ImageDimensions(oriented.width, oriented.height);

  final target = DecodePolicy.previewSize(sourceSize);
  final needsResize = target.width != sourceSize.width;

  final preview = needsResize
      ? img.copyResize(
          oriented,
          width: target.width,
          height: target.height,
          interpolation: img.Interpolation.cubic,
        )
      : oriented;

  final png = img.encodePng(preview);
  return DecodeResult(
    previewPng: png,
    sourceSize: sourceSize,
    previewSize: ImageDimensions(preview.width, preview.height),
  );
}
