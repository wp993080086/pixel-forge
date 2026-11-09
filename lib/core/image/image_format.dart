/// 支持的图片格式（对应 PRD「一、支持图片格式」）。
enum ImageFormat {
  jpeg,
  png,
  bmp,
  webp,
  tiff,
  tga,
  ppm,
  gif,
  apng,
  svg,
  ico;

  static ImageFormat? fromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    for (final f in ImageFormat.values) {
      if (f.extensions.contains(e)) return f;
    }
    return null;
  }
}

extension ImageFormatInfo on ImageFormat {
  String get displayName => switch (this) {
        ImageFormat.jpeg => 'JPEG',
        ImageFormat.png => 'PNG',
        ImageFormat.bmp => 'BMP',
        ImageFormat.webp => 'WebP',
        ImageFormat.tiff => 'TIFF',
        ImageFormat.tga => 'TGA',
        ImageFormat.ppm => 'PPM',
        ImageFormat.gif => 'GIF',
        ImageFormat.apng => 'APNG',
        ImageFormat.svg => 'SVG',
        ImageFormat.ico => 'ICO',
      };

  /// 扩展名集合。
  ///
  /// APNG 刻意返回空：它与 PNG 同为 `.png`，无法靠扩展名区分。若在此返回
  /// `['png']`，[ImageFormat.fromExtension] 会按枚举顺序先命中 png，
  /// 导致 apng 分支永远不可达、动图被当静态图静默丢帧（PRD 一.5）。
  /// APNG 必须通过文件头 `acTL` chunk 探测。
  List<String> get extensions => switch (this) {
        ImageFormat.jpeg => ['jpg', 'jpeg'],
        ImageFormat.png => ['png'],
        ImageFormat.bmp => ['bmp'],
        ImageFormat.webp => ['webp'],
        ImageFormat.tiff => ['tif', 'tiff'],
        ImageFormat.tga => ['tga'],
        ImageFormat.ppm => ['ppm'],
        ImageFormat.gif => ['gif'],
        ImageFormat.apng => const [],
        ImageFormat.svg => ['svg'],
        ImageFormat.ico => ['ico'],
      };

  /// 目标格式是否支持 Alpha 通道（对应 PRD「八.2 透明通道一致性」）。
  bool get supportsAlpha => switch (this) {
        ImageFormat.jpeg => false,
        ImageFormat.bmp => false,
        ImageFormat.tga => false,
        ImageFormat.ppm => false,
        _ => true,
      };

  bool get isAnimated => this == ImageFormat.gif || this == ImageFormat.apng;

  bool get isVector => this == ImageFormat.svg;

  bool get isContainer => this == ImageFormat.ico;

  /// 小众格式：部分端天然缺少解码能力（PRD 一.边界3）。
  bool get isNiche =>
      this == ImageFormat.tiff ||
      this == ImageFormat.tga ||
      this == ImageFormat.ppm;
}
