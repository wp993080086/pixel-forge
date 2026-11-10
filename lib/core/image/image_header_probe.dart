import 'dart:typed_data';

import 'image_format.dart';

/// 仅从文件头解析出的图片尺寸信息（不解码像素）。
///
/// 支撑 PRD 九.3（2）的像素预检：解码前先取宽高，
/// `宽 × 高 × 4 + 编码缓冲` 与平台上限对比，不足则拦截。
class ImageDimensions {
  const ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  /// 总像素数。
  int get pixels => width * height;
}

/// 文件头尺寸解析器：只读前若干字节，不解码像素（PRD 九.3）。
///
/// 覆盖主流格式；无法从头部解析的格式（TGA / PPM / SVG）返回 null，
/// 由调用方回退到「解码后取尺寸」路径。
class ImageHeaderProbe {
  ImageHeaderProbe._();

  /// 从文件字节流解析宽高；无法解析返回 null。
  static ImageDimensions? probe(Uint8List bytes, ImageFormat format) {
    try {
      return switch (format) {
        ImageFormat.png || ImageFormat.apng => _probePng(bytes),
        ImageFormat.jpeg => _probeJpeg(bytes),
        ImageFormat.gif => _probeGif(bytes),
        ImageFormat.bmp => _probeBmp(bytes),
        ImageFormat.webp => _probeWebp(bytes),
        ImageFormat.ico => _probeIco(bytes),
        ImageFormat.tiff => _probeTiff(bytes),
        // TGA / PPM / SVG 头部信息不足以稳定取尺寸，交由解码路径处理。
        ImageFormat.tga || ImageFormat.ppm || ImageFormat.svg => null,
      };
    } catch (_) {
      // 头部结构异常：视为无法解析，交由解码阶段判定（E-IMG-002）。
      return null;
    }
  }

  // --- PNG / APNG：IHDR 固定位于签名后第一个 chunk ---
  static ImageDimensions? _probePng(Uint8List b) {
    // 签名 8 字节 + chunk 长度(4) + 'IHDR'(4) = 偏移 16 起为宽高
    if (b.length < 24) return null;
    final w = _readUint32BE(b, 16);
    final h = _readUint32BE(b, 20);
    return ImageDimensions(w, h);
  }

  // --- JPEG：扫描 SOFn 段 ---
  static ImageDimensions? _probeJpeg(Uint8List b) {
    var pos = 2; // 跳过 SOI (FFD8)
    while (pos + 9 < b.length) {
      if (b[pos] != 0xFF) {
        pos++;
        continue;
      }
      final marker = b[pos + 1];
      // SOF0–SOF15（排除 DHT=C4、JPG=C8、DAC=CC 等非 SOF 标记）
      final isSof =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isSof) {
        final h = (b[pos + 5] << 8) | b[pos + 6];
        final w = (b[pos + 7] << 8) | b[pos + 8];
        return ImageDimensions(w, h);
      }
      // 跳过该段：长度字段在 marker 后 2 字节（含自身）
      final segLen = (b[pos + 2] << 8) | b[pos + 3];
      if (segLen < 2) return null;
      pos += 2 + segLen;
    }
    return null;
  }

  // --- GIF：逻辑屏幕描述符（偏移 6，小端） ---
  static ImageDimensions? _probeGif(Uint8List b) {
    if (b.length < 10) return null;
    final w = b[6] | (b[7] << 8);
    final h = b[8] | (b[9] << 8);
    return ImageDimensions(w, h);
  }

  // --- BMP：BITMAPINFOHEADER（偏移 18，小端；高度可能为负表示自上而下） ---
  static ImageDimensions? _probeBmp(Uint8List b) {
    if (b.length < 26) return null;
    final w = _readInt32LE(b, 18);
    final h = _readInt32LE(b, 22).abs();
    return ImageDimensions(w, h);
  }

  // --- WebP：VP8 / VP8L / VP8X 三种子格式 ---
  static ImageDimensions? _probeWebp(Uint8List b) {
    if (b.length < 30) return null;
    final fourcc = String.fromCharCodes(b, 12, 16);
    switch (fourcc) {
      case 'VP8X':
        // 扩展格式：画布宽高在 chunk 内偏移 4 起，各 3 字节小端（值 = 实际 - 1）
        final w = _readUint24LE(b, 24) + 1;
        final h = _readUint24LE(b, 27) + 1;
        return ImageDimensions(w, h);
      case 'VP8 ':
        // 有损：帧头中 0x9D012A 之后为宽高（各 2 字节小端，低 14 位有效）
        if (b.length < 30) return null;
        final w = (_readUint16LE(b, 26)) & 0x3FFF;
        final h = (_readUint16LE(b, 28)) & 0x3FFF;
        return ImageDimensions(w, h);
      case 'VP8L':
        // 无损：签名 0x2F 后 4 字节位打包（宽-1 占 14 位，高-1 占 14 位）
        if (b.length < 25 || b[20] != 0x2F) return null;
        final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
        final w = (bits & 0x3FFF) + 1;
        final h = ((bits >> 14) & 0x3FFF) + 1;
        return ImageDimensions(w, h);
    }
    return null;
  }

  // --- ICO：目录项中宽高各 1 字节（0 表示 256） ---
  static ImageDimensions? _probeIco(Uint8List b) {
    if (b.length < 8) return null;
    final w = b[6] == 0 ? 256 : b[6];
    final h = b[7] == 0 ? 256 : b[7];
    return ImageDimensions(w, h);
  }

  // --- TIFF：IFD0 中查找 ImageWidth(256) / ImageLength(257) ---
  static ImageDimensions? _probeTiff(Uint8List b) {
    if (b.length < 8) return null;
    final littleEndian = b[0] == 0x49;
    int u16(int p) =>
        littleEndian ? (b[p] | (b[p + 1] << 8)) : ((b[p] << 8) | b[p + 1]);
    int u32(int p) => littleEndian
        ? (b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24))
        : ((b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3]);

    final ifdOffset = u32(4);
    if (ifdOffset + 2 > b.length) return null;
    final count = u16(ifdOffset);
    int? width;
    int? height;
    for (var i = 0; i < count; i++) {
      final entry = ifdOffset + 2 + i * 12;
      if (entry + 12 > b.length) break;
      final tag = u16(entry);
      // 仅处理 SHORT(3) / LONG(4) 两种常见类型，值内联于 entry+8
      final type = u16(entry + 2);
      if (tag == 256 && (type == 3 || type == 4)) {
        width = type == 3 ? u16(entry + 8) : u32(entry + 8);
      } else if (tag == 257 && (type == 3 || type == 4)) {
        height = type == 3 ? u16(entry + 8) : u32(entry + 8);
      }
      if (width != null && height != null) break;
    }
    if (width == null || height == null) return null;
    return ImageDimensions(width, height);
  }

  // --- 字节工具 ---

  static int _readUint16LE(Uint8List b, int p) => b[p] | (b[p + 1] << 8);

  /// 读 32 位小端**有符号**整数（BMP 高度为负表示自上而下存储）。
  static int _readInt32LE(Uint8List b, int p) {
    final v = b[p] | (b[p + 1] << 8) | (b[p + 2] << 16) | (b[p + 3] << 24);
    // 手动符号扩展：第 31 位为 1 时减 2^32
    return (v & 0x80000000) != 0 ? v - 0x100000000 : v;
  }

  static int _readUint24LE(Uint8List b, int p) =>
      b[p] | (b[p + 1] << 8) | (b[p + 2] << 16);

  static int _readUint32BE(Uint8List b, int p) =>
      (b[p] << 24) | (b[p + 1] << 16) | (b[p + 2] << 8) | b[p + 3];
}
