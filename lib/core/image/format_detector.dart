import 'dart:typed_data';

import 'image_format.dart';

/// 格式探测结果。
class DetectedFormat {
  const DetectedFormat({
    required this.format,
    this.isAnimated = false,
    this.hasAlpha = false,
  });

  /// 按文件内容判定的格式。
  final ImageFormat format;

  /// 是否为动图（APNG / 动图 WebP / GIF）。
  final bool isAnimated;

  /// 是否含透明通道（探测阶段仅对 PNG / GIF 做快速判定，其余留给解码阶段）。
  final bool hasAlpha;
}

/// 图片格式探测：以文件内容（magic bytes）为准，扩展名仅作提示（PRD 一.5）。
///
/// 纯函数、无依赖，便于单元测试；不做像素解码，仅读文件头。
///
/// 覆盖 PRD 一.5 表：JPEG / PNG(APNG) / GIF / WebP(含动图) / BMP / ICO / SVG，
/// 以及小众格式 TIFF / TGA / PPM（PRD 一.边界3，仅 Windows 放开）。
class ImageFormatDetector {
  ImageFormatDetector._();

  /// 探测所需的最小字节数（PNG 的 acTL 扫描会按需向后读取）。
  static const int _pngHeaderLength = 8;

  /// 探测格式；无法识别时返回 null（调用方按 `E-IMG-002` 处理）。
  static DetectedFormat? detect(Uint8List bytes) {
    if (bytes.length < 2) return null;

    if (_matchPng(bytes)) return _detectPng(bytes);
    if (_matchJpeg(bytes)) {
      return const DetectedFormat(format: ImageFormat.jpeg);
    }
    if (_matchGif(bytes)) return _detectGif(bytes);
    if (_matchWebp(bytes)) return _detectWebp(bytes);
    if (_matchBmp(bytes)) return const DetectedFormat(format: ImageFormat.bmp);
    if (_matchIco(bytes)) return const DetectedFormat(format: ImageFormat.ico);
    if (_matchTiff(bytes)) {
      return const DetectedFormat(format: ImageFormat.tiff);
    }
    if (_matchPpm(bytes)) return const DetectedFormat(format: ImageFormat.ppm);
    if (_matchTga(bytes)) return const DetectedFormat(format: ImageFormat.tga);
    if (_matchSvg(bytes)) return const DetectedFormat(format: ImageFormat.svg);
    return null;
  }

  // --- 各格式判定 ---

  static bool _matchJpeg(Uint8List b) =>
      b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  static bool _matchPng(Uint8List b) {
    if (b.length < _pngHeaderLength) return false;
    const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    for (var i = 0; i < sig.length; i++) {
      if (b[i] != sig[i]) return false;
    }
    return true;
  }

  static bool _matchGif(Uint8List b) {
    if (b.length < 6) return false;
    // GIF8（7a/9a）
    return b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38;
  }

  static bool _matchWebp(Uint8List b) {
    if (b.length < 12) return false;
    // RIFF .... WEBP
    const riff = [0x52, 0x49, 0x46, 0x46];
    const webp = [0x57, 0x45, 0x42, 0x50];
    for (var i = 0; i < 4; i++) {
      if (b[i] != riff[i] || b[8 + i] != webp[i]) return false;
    }
    return true;
  }

  static bool _matchBmp(Uint8List b) => b[0] == 0x42 && b[1] == 0x4D;

  static bool _matchIco(Uint8List b) =>
      b.length >= 4 &&
      b[0] == 0x00 &&
      b[1] == 0x00 &&
      b[2] == 0x01 &&
      b[3] == 0x00;

  static bool _matchTiff(Uint8List b) {
    if (b.length < 4) return false;
    final le = b[0] == 0x49 && b[1] == 0x49 && b[2] == 0x2A && b[3] == 0x00;
    final be = b[0] == 0x4D && b[1] == 0x4D && b[2] == 0x00 && b[3] == 0x2A;
    return le || be;
  }

  /// PPM：ASCII 魔数 `P3` 或二进制 `P6`，后接空白（空格/换行/制表）。
  static bool _matchPpm(Uint8List b) {
    if (b.length < 3) return false;
    if (b[0] != 0x50) return false;
    if (b[1] != 0x33 && b[1] != 0x36) return false;
    return _isWhitespace(b[2]);
  }

  /// TGA：无固定魔数，仅 v2 规范在文件尾 18 字节处含 `TRUEVISION-XFILE`。
  /// 命中即判定；未命中不误判（TGA 属小众格式，仅 Windows 放开）。
  static bool _matchTga(Uint8List b) {
    const footer = 'TRUEVISION-XFILE';
    final start = b.length - 18;
    if (start < 0) return false;
    for (var i = 0; i < footer.length; i++) {
      if (b[start + i] != footer.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// SVG：去 BOM 与空白后以 `<svg` 开头，或 XML 序言后首个元素为 `<svg`。
  static bool _matchSvg(Uint8List b) {
    var i = 0;
    // 跳过 UTF-8 BOM
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      i = 3;
    }
    // 取前若干字节转字符串做文本判定（SVG 头很小）
    final head = String.fromCharCodes(
      b,
      i,
      b.length < i + 512 ? b.length : i + 512,
    );
    final trimmed = head.trimLeft();
    if (trimmed.startsWith('<svg')) return true;
    // XML 序言后首个元素为 <svg（如 `<?xml ...?>\n<svg`）
    if (trimmed.startsWith('<?xml')) {
      final close = trimmed.indexOf('?>');
      if (close == -1) return false;
      return trimmed.substring(close + 2).trimLeft().startsWith('<svg');
    }
    return false;
  }

  // --- 细分探测 ---

  /// PNG 是否为 APNG：扫描 `acTL` chunk。
  static DetectedFormat _detectPng(Uint8List b) {
    final isApng = _containsAcTL(b);
    return DetectedFormat(
      format: isApng ? ImageFormat.apng : ImageFormat.png,
      isAnimated: isApng,
      // PNG 支持 alpha；具体是否真含透明像素留待解码阶段，此处仅标注能力。
      hasAlpha: true,
    );
  }

  /// 扫描 PNG chunk 流，查找 `acTL`（APNG 动画控制块）。
  ///
  /// PNG 结构：8 字节签名后为若干 chunk，每个 chunk =
  /// [4 字节长度][4 字节类型][数据][4 字节 CRC]。
  static bool _containsAcTL(Uint8List b) {
    var pos = _pngHeaderLength;
    while (pos + 8 <= b.length) {
      final length = _readUint32(b, pos);
      // 类型字段紧随长度之后
      final typeStart = pos + 4;
      if (_equalsAscii(b, typeStart, 'acTL')) return true;
      // 移动到下一个 chunk：长度 + 类型(4) + 数据(length) + CRC(4)
      pos = typeStart + 4 + length + 4;
      if (length < 0) return false; // 异常长度，放弃扫描
    }
    return false;
  }

  static DetectedFormat _detectGif(Uint8List b) {
    // 粗略判定动图：出现多个图像描述符（0x2C）或 NETSCAPE2.0 扩展。
    // 精确帧数留待解码阶段；此处仅给出「可能是动图」信号。
    var frames = 0;
    for (var i = 6; i < b.length && frames < 2; i++) {
      if (b[i] == 0x2C) frames++;
    }
    return DetectedFormat(
      format: ImageFormat.gif,
      isAnimated: frames > 1,
      hasAlpha: true,
    );
  }

  /// WebP 是否动图：存在 `VP8X` chunk 且 flags 字节（VP8X 数据首字节）带 ANIM 位（0x02）。
  static DetectedFormat _detectWebp(Uint8List b) {
    var pos = 12; // 跳过 RIFF....WEBP
    var animated = false;
    while (pos + 8 <= b.length) {
      if (_equalsAscii(b, pos, 'VP8X')) {
        final flags = b[pos + 8];
        animated = (flags & 0x02) != 0; // ANIM 位
        break;
      }
      final size = _readUint32LE(b, pos + 4);
      pos = pos + 8 + size + (size.isOdd ? 1 : 0); // chunk 数据按偶数对齐
    }
    return DetectedFormat(
      format: ImageFormat.webp,
      isAnimated: animated,
      hasAlpha: true,
    );
  }

  // --- 字节工具 ---

  static bool _isWhitespace(int c) =>
      c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

  static int _readUint32(Uint8List b, int pos) =>
      (b[pos] << 24) | (b[pos + 1] << 16) | (b[pos + 2] << 8) | b[pos + 3];

  static int _readUint32LE(Uint8List b, int pos) =>
      b[pos] | (b[pos + 1] << 8) | (b[pos + 2] << 16) | (b[pos + 3] << 24);

  static bool _equalsAscii(Uint8List b, int pos, String s) {
    if (pos + s.length > b.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (b[pos + i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }
}
