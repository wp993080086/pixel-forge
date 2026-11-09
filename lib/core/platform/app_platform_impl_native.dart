import 'dart:io' show Platform;

import 'app_platform.dart';

/// 原生端（dart:io 可用）的目标端检测实现。
AppTarget detectNativeTarget() {
  if (Platform.isWindows) return AppTarget.windows;
  // TODO(harmony): 在 Flutter-OH 分支上验证 Platform.operatingSystem 的实际取值
  // （可能为 'ohos'，也可能被识别为 android）。验证前鸿蒙端会回落到 android，
  // 两者按 PRD 走同一能力基线，不影响功能正确性。
  if (Platform.operatingSystem == 'ohos') return AppTarget.harmony;
  if (Platform.isAndroid) return AppTarget.android;
  return AppTarget.android;
}
