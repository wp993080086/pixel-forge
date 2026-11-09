import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 日志级别（对应 AGENTS.md 编码规范）。
enum LogLevel {
  debug,
  info,
  warn,
  error;

  /// 是否达到输出阈值：[kDebugMode] 下全量输出，release 仅 warn/error。
  bool get enabled => kDebugMode || index >= LogLevel.warn.index;
}

/// 应用日志薄封装。
///
/// 设计约束（PRD 铁律：纯本地离线）：
/// - 零第三方依赖，底层用 [developer.log]，可在 DevTools / IDE 控制台查看；
/// - **不做任何远程上报**，禁止接入 Sentry / Firebase 等联网日志；
/// - release 下仅保留 [LogLevel.warn] 及以上，避免生产噪音。
///
/// 用法：
/// ```dart
/// AppLogger.info('导入完成', name: 'import', data: {'format': 'png'});
/// AppLogger.error('解码失败', error: e, stackTrace: st, name: 'decode');
/// ```
class AppLogger {
  AppLogger._();

  /// 统一日志名（DevTools 里按此过滤）。
  static const String _defaultName = 'pixel_forge';

  static void debug(String message, {String? name, Object? data}) {
    _log(LogLevel.debug, message, name: name, data: data);
  }

  static void info(String message, {String? name, Object? data}) {
    _log(LogLevel.info, message, name: name, data: data);
  }

  static void warn(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    _log(
      LogLevel.warn,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    _log(
      LogLevel.error,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    if (!level.enabled) return;
    final buffer = StringBuffer('[${level.name.toUpperCase()}] $message');
    if (data != null) buffer.write(' | $data');
    developer.log(
      buffer.toString(),
      name: name ?? _defaultName,
      error: error,
      stackTrace: stackTrace,
      level: _developerLevel(level),
    );
  }

  /// 映射到 `dart:developer` 的 level 数值（便于 DevTools 按级别过滤）。
  static int _developerLevel(LogLevel level) => switch (level) {
    LogLevel.debug => 500,
    LogLevel.info => 800,
    LogLevel.warn => 900,
    LogLevel.error => 1000,
  };
}
