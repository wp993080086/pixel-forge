import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/core/error/app_error.dart';
import 'package:pixel_forge/core/image/image_format.dart';
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

ImportResult _validResult({ImageFormat? format = ImageFormat.png}) =>
    ImportResult(
      fileName: 'a.png',
      bytes: Uint8List.fromList([1, 2, 3]),
      format: format,
      isAnimated: false,
      extensionMismatch: false,
    );

/// 用替身导入服务构建容器并返回控制器。
(ProviderContainer, EditorController) _make(ImportResult? Function() result) {
  final container = ProviderContainer(
    overrides: [
      importServiceProvider.overrideWithValue(_FakeImportService(result)),
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

    test('成功导入 → 可编辑态，并携带导入结果', () async {
      final (container, controller) = _make(_validResult);
      addTearDown(container.dispose);
      await controller.pickAndLoad();
      expect(controller.state.stage, EditorStage.editable);
      expect(controller.state.imported?.fileName, 'a.png');
      expect(controller.state.canEdit, isTrue);
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
