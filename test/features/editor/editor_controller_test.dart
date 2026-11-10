import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/core/di/providers.dart';
import 'package:pixel_forge/core/error/app_error.dart';
import 'package:pixel_forge/core/image/decode_service.dart';
import 'package:pixel_forge/core/image/image_format.dart';
import 'package:pixel_forge/core/image/image_header_probe.dart';
import 'package:pixel_forge/core/platform/app_platform.dart';
import 'package:pixel_forge/core/platform/capabilities.dart';
import 'package:pixel_forge/features/editor/editor_controller.dart';
import 'package:pixel_forge/features/editor/editor_state.dart';
import 'package:pixel_forge/services/file/import_service.dart';

/// 可编排返回值的导入服务替身。
class _FakeImportService extends ImportService {
  _FakeImportService(this._result)
    : super(PlatformCapabilities.of(AppTarget.windows));

  final ImportResult? Function() _result;

  @override
  Future<ImportResult?> pickImage() async => _result();
}

/// 解码服务替身：返回固定结果或 null，避免测试依赖真实解码。
class _FakeDecodeService extends DecodeService {
  _FakeDecodeService(this._result);

  final DecodeResult? Function() _result;

  @override
  Future<DecodeResult?> decodePreview(Uint8List bytes) async => _result();
}

DecodeResult _stubDecode() => DecodeResult(
  previewPng: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
  sourceSize: const ImageDimensions(100, 100),
  previewSize: const ImageDimensions(100, 100),
);

ImportResult _validResult({ImageFormat? format = ImageFormat.png}) =>
    ImportResult(
      fileName: 'a.png',
      bytes: Uint8List.fromList([1, 2, 3]),
      format: format,
      isAnimated: false,
      extensionMismatch: false,
    );

/// 构造带 PNG 头、指定宽高的导入结果（用于像素预检）。
ImportResult _pngResult(int w, int h) {
  final bytes = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0,
    0,
    0,
    13,
    ...'IHDR'.codeUnits,
    (w >> 24) & 0xFF,
    (w >> 16) & 0xFF,
    (w >> 8) & 0xFF,
    w & 0xFF,
    (h >> 24) & 0xFF,
    (h >> 16) & 0xFF,
    (h >> 8) & 0xFF,
    h & 0xFF,
    8,
    6,
    0,
    0,
    0,
  ];
  return ImportResult(
    fileName: 'big.png',
    bytes: Uint8List.fromList(bytes),
    format: ImageFormat.png,
    isAnimated: false,
    extensionMismatch: false,
  );
}

/// 用替身导入/解码服务构建容器并返回控制器。
(ProviderContainer, EditorController) _make(
  ImportResult? Function() result, {
  DecodeResult? Function()? decode,
}) {
  final container = ProviderContainer(
    overrides: [
      importServiceProvider.overrideWithValue(_FakeImportService(result)),
      decodeServiceProvider.overrideWithValue(
        _FakeDecodeService(decode ?? _stubDecode),
      ),
    ],
  );
  final controller = container.read(editorControllerProvider.notifier);
  return (container, controller);
}

void main() {
  group('EditorState 状态机', () {
    test('初始为空态', () {
      final (container, controller) = _make(() => null);
      addTearDown(container.dispose);
      expect(controller.state.stage, EditorStage.empty);
      expect(controller.state.busy, isFalse);
    });

    test('成功导入 → 可编辑态，并携带导入结果与预览图', () async {
      final (container, controller) = _make(_validResult);
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.editable);
      expect(controller.state.imported?.fileName, 'a.png');
      expect(controller.state.decoded, isNotNull);
      expect(controller.state.canEdit, isTrue);
    });

    test('解码失败 → 导入失败态 E-IMG-002', () async {
      final (container, controller) = _make(_validResult, decode: () => null);
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.importFailed);
      expect(controller.state.failure?.code, AppErrorCode.corruptedFile);
    });

    test('用户取消（返回 null）→ 回到空态', () async {
      final (container, controller) = _make(() => null);
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.empty);
    });

    test('格式无法识别 → 导入失败态 E-IMG-002', () async {
      final (container, controller) = _make(() => _validResult(format: null));
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.importFailed);
      expect(controller.state.failure?.code, AppErrorCode.corruptedFile);
      expect(controller.state.failure?.message, '文件已损坏或不是有效图片');
    });

    test('reset 清空状态', () async {
      final (container, controller) = _make(_validResult);
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      controller.reset();
      expect(controller.state.stage, EditorStage.empty);
      expect(controller.state.imported, isNull);
      expect(controller.state.failure, isNull);
    });

    test('像素超限 → 导入失败态 E-IMG-004（Windows 上限 100MP）', () async {
      // 20000 × 20000 = 400MP，超过 Windows 100MP 上限
      final (container, controller) = _make(() => _pngResult(20000, 20000));
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.importFailed);
      expect(controller.state.failure?.code, AppErrorCode.pixelLimitExceeded);
      expect(controller.state.failure?.context?['上限'], '100MP');
    });

    test('像素未超限 → 正常进入可编辑态', () async {
      // 4000 × 4000 = 16MP，未超限
      final (container, controller) = _make(() => _pngResult(4000, 4000));
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.editable);
    });

    test('「中」态 busy 为真，禁用输入', () {
      const detecting = EditorState(stage: EditorStage.detecting);
      const decoding = EditorState(stage: EditorStage.decoding);
      const exporting = EditorState(stage: EditorStage.exporting);
      expect(detecting.busy, isTrue);
      expect(decoding.busy, isTrue);
      expect(exporting.busy, isTrue);
      expect(const EditorState(stage: EditorStage.editable).busy, isFalse);
    });
  });
}
