import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_forge/app/app.dart';

Future<void> _bootHome(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: PixelForgeApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('首页渲染：标题与功能入口可见', (tester) async {
    await _bootHome(tester);

    expect(find.text('像素工坊'), findsOneWidget);
    expect(find.text('裁剪'), findsOneWidget);
    expect(find.text('尺寸与比例'), findsOneWidget);
    expect(find.text('格式转换'), findsOneWidget);
    expect(find.text('图片压缩'), findsOneWidget);
  });

  testWidgets('格式转换入口进入导出面板并聚焦转换分区', (tester) async {
    await _bootHome(tester);

    await tester.tap(find.text('格式转换'));
    await tester.pumpAndSettle();

    // 合并后两入口共用同一页面（PRD 四章首 / 十三章）。
    expect(find.text('导出'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.textContaining('转换矩阵见 PRD 四.1'), findsOneWidget);
  });

  testWidgets('图片压缩入口进入同一导出面板并聚焦压缩分区', (tester) async {
    await _bootHome(tester);

    await tester.tap(find.text('图片压缩'));
    await tester.pumpAndSettle();

    expect(find.text('导出'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.textContaining('一次编码完成'), findsOneWidget);
    // 转换分区独有的要点不应出现在当前 Tab。
    expect(find.textContaining('转换矩阵见 PRD 四.1'), findsNothing);
  });
}
