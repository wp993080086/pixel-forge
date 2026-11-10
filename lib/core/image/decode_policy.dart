import 'image_header_probe.dart';

/// 解码前的尺寸策略（对应 PRD 九.3（2）（3））。
///
/// 纯函数，便于单元测试；不含 IO 与解码。
class DecodePolicy {
  DecodePolicy._();

  /// 预览降采样阈值：原图边长 > 4096 或总像素 > 2000 万时触发降采样。
  static const int previewEdgeThreshold = 4096;
  static const int previewPixelThreshold = 20 * 1000 * 1000;

  /// 降采样后长边目标（PRD 九.3（3））。
  static const int previewLongEdge = 2048;

  /// 像素预检结果。
  static bool exceedsLimit(ImageDimensions dims, int maxPixels) =>
      dims.pixels > maxPixels;

  /// 估算位图字节数：宽 × 高 × 4（RGBA）+ 编码缓冲。
  ///
  /// 用于 PRD 九.3（2）与平台可用内存对比，不足则 `E-IMG-005`。
  static int estimateBitmapBytes(ImageDimensions dims) => dims.pixels * 4;

  /// 是否需要降采样生成预览图（PRD 九.3（3））。
  static bool needsDownsample(ImageDimensions dims) =>
      dims.width > previewEdgeThreshold ||
      dims.height > previewEdgeThreshold ||
      dims.pixels > previewPixelThreshold;

  /// 计算预览图目标尺寸：不触发降采样时等于原图（省一次缩放）。
  static ImageDimensions previewSize(ImageDimensions dims) {
    if (!needsDownsample(dims)) return dims;
    final longEdge = dims.width > dims.height ? dims.width : dims.height;
    final scale = previewLongEdge / longEdge;
    return ImageDimensions(
      (dims.width * scale).round().clamp(1, dims.width),
      (dims.height * scale).round().clamp(1, dims.height),
    );
  }
}
