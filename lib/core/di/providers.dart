import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/app_platform.dart';
import '../platform/capabilities.dart';
import '../../services/file/export_service.dart';

/// 当前端能力矩阵（全局只读）。
final capabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) => PlatformCapabilities.of(AppPlatform.current),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => const ExportService(),
);

// 说明：importServiceProvider 定义在 `services/file/import_service.dart`，
// editorControllerProvider 定义在 `features/editor/editor_controller.dart`，
// 以避免 providers.dart ↔ controller 的循环依赖。
