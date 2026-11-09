import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// 像素工坊应用根组件。
class PixelForgeApp extends ConsumerWidget {
  const PixelForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '像素工坊',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('zh', 'CN')],
      locale: const Locale('zh', 'CN'),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
