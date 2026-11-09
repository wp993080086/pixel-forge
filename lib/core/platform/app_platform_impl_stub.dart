import 'app_platform.dart';

/// Web 端的目标端检测实现（dart:io 不可用时编译此文件）。
AppTarget detectNativeTarget() => AppTarget.web;
