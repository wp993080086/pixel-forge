import 'package:flutter/material.dart';

/// 功能占位页通用骨架：标题 + 需求要点清单（搭建期展示 PRD 锚点，后续逐功能替换实现）。
///
/// [bottom] 用于挂 TabBar；[body] 为空时渲染默认的要点清单，否则由调用方接管
/// 页面主体（如导出页的 TabBarView）。
class FeaturePageScaffold extends StatelessWidget {
  const FeaturePageScaffold({
    super.key,
    required this.title,
    this.requirementPoints = const [],
    this.bottom,
    this.body,
  });

  final String title;
  final List<String> requirementPoints;
  final PreferredSizeWidget? bottom;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), bottom: bottom),
      body: body ?? RequirementList(points: requirementPoints),
    );
  }
}

/// 需求要点清单（占位期用）。
class RequirementList extends StatelessWidget {
  const RequirementList({
    super.key,
    required this.points,
    this.header = '功能开发中，以下为对应需求要点：',
  });

  final List<String> points;
  final String header;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: points.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.construction,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(header)),
                ],
              ),
            ),
          );
        }
        final point = points[index - 1];
        return ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(point),
          dense: true,
        );
      },
    );
  }
}
