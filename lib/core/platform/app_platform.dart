import 'package:flutter/foundation.dart';

import 'app_platform_impl_stub.dart'
    if (dart.library.io) 'app_platform_impl_native.dart';

/// 应用运行的目标端。
///
/// 对应 PRD「七、多端差异化策略」：
/// Windows（首发基线）→ HarmonyOS Next（优先级高于 Android）→ Android → Web → 微信小程序。
enum AppTarget {
  windows('Windows'),
  harmony('HarmonyOS Next'),
  android('Android'),
  web('Web'),
  wechatMini('微信小程序');

  const AppTarget(this.displayName);

  final String displayName;
}

/// 当前运行端检测。
///
/// 注意：微信小程序为独立代码库，Flutter 不覆盖该端（PRD 选型背景），
/// [AppTarget.wechatMini] 仅供能力矩阵定义与未来共享逻辑使用。
class AppPlatform {
  AppPlatform._();

  static AppTarget? _cached;

  static AppTarget get current => _cached ??= _detect();

  static AppTarget _detect() {
    if (kIsWeb) return AppTarget.web;
    return detectNativeTarget();
  }
}
