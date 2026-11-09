import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/crop/crop_page.dart';
import '../features/export/export_page.dart';
import '../features/home/home_page.dart';
import '../features/resize/resize_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const crop = '/crop';
  static const resize = '/resize';

  /// 导出面板：格式转换与压缩合并为同一页面（PRD 四 / 五章、十三章）。
  static const exportPanel = '/export';

  /// 首页「格式转换」入口：进入导出面板并聚焦格式分区。
  static const exportConvert = '$exportPanel?tab=convert';

  /// 首页「图片压缩」入口：进入导出面板并聚焦压缩分区。
  static const exportCompress = '$exportPanel?tab=compress';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.crop,
        builder: (context, state) => const CropPage(),
      ),
      GoRoute(
        path: AppRoutes.resize,
        builder: (context, state) => const ResizePage(),
      ),
      GoRoute(
        path: AppRoutes.exportPanel,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return ExportPage(
            initialTab: tab == 'compress'
                ? ExportTab.compress
                : ExportTab.convert,
          );
        },
      ),
    ],
  );
});
