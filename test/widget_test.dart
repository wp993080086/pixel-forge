import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/app/app.dart';
import 'package:pixel_forge/core/di/providers.dart';
import 'package:pixel_forge/core/image/decode_service.dart';
import 'package:pixel_forge/core/image/image_format.dart';
import 'package:pixel_forge/core/image/image_header_probe.dart';
import 'package:pixel_forge/core/platform/app_platform.dart';
import 'package:pixel_forge/core/platform/capabilities.dart';
import 'package:pixel_forge/services/file/import_service.dart';

/// 导入/解码替身：返回一张 4×4 的假图，避免测试依赖真实文件选择器与解码。
class _FakeImportService extends ImportService {
  _FakeImportService() : super(PlatformCapabilities.of(AppTarget.windows));

  @override
  Future<ImportResult?> pickImage() async => ImportResult(
    fileName: 'a.png',
    bytes: Uint8List.fromList([1, 2, 3]),
    format: ImageFormat.png,
    isAnimated: false,
    extensionMismatch: false,
  );
}

class _FakeDecodeService extends DecodeService {
  const _FakeDecodeService();

  @override
  Future<DecodeResult?> decodePreview(Uint8List bytes) async => DecodeResult(
    previewPng: _onePixelPng,
    sourceSize: const ImageDimensions(4, 4),
    previewSize: const ImageDimensions(4, 4),
  );
}

/// 一张真实的 1×1 透明 PNG，供 `Image.memory` 正常解码（假字节会触发 codec 异常）。
final Uint8List _onePixelPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

Future<void> _bootHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importServiceProvider.overrideWithValue(_FakeImportService()),
        decodeServiceProvider.overrideWithValue(const _FakeDecodeService()),
      ],
      child: const PixelForgeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// 首页选图进入可编辑态，功能入口才可用（PRD 九.5）。
Future<void> _importImage(WidgetTester tester) async {
  await tester.tap(find.text('选择文件'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('首页渲染：标题与功能入口可见', (tester) async {
    await _bootHome(tester);

    expect(find.text('像素工坊'), findsOneWidget);
    expect(find.text('裁剪'), findsOneWidget);
    expect(find.text('尺寸与比例'), findsOneWidget);
    expect(find.text('格式转换'), findsOneWidget);
    expect(find.text('图片压缩'), findsOneWidget);
  });

  testWidgets('未导入图片时功能入口不可点击', (tester) async {
    await _bootHome(tester);

    // 未导入 → 入口置灰，点击不跳转。
    await tester.tap(find.text('格式转换'));
    await tester.pumpAndSettle();
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('格式转换入口进入导出面板并聚焦转换分区', (tester) async {
    await _bootHome(tester);
    await _importImage(tester);

    await tester.tap(find.text('格式转换'));
    await tester.pumpAndSettle();

    // 合并后两入口共用同一页面（PRD 四章首 / 十三章）。
    expect(find.text('导出'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.textContaining('转换矩阵见 PRD 四.1'), findsOneWidget);
  });

  testWidgets('图片压缩入口进入同一导出面板并聚焦压缩分区', (tester) async {
    await _bootHome(tester);
    await _importImage(tester);

    await tester.tap(find.text('图片压缩'));
    await tester.pumpAndSettle();

    expect(find.text('导出'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.textContaining('一次编码完成'), findsOneWidget);
    // 转换分区独有的要点不应出现在当前 Tab。
    expect(find.textContaining('转换矩阵见 PRD 四.1'), findsNothing);
  });

  testWidgets('裁剪页：可编辑态展示预览图与原图尺寸', (tester) async {
    await _bootHome(tester);
    await _importImage(tester);

    await tester.tap(find.text('裁剪'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('原图 4 × 4'), findsOneWidget);
  });
}
