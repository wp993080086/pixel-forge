import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/app_platform.dart';
import '../platform/capabilities.dart';
import '../../services/file/export_service.dart';
import '../../services/file/import_service.dart';

/// 当前端能力矩阵（全局只读）。
final capabilitiesProvider = Provider<PlatformCapabilities>(
  (ref) => PlatformCapabilities.of(AppPlatform.current),
);

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(ref.watch(capabilitiesProvider)),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => const ExportService(),
);
