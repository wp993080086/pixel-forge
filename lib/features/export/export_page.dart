import 'package:flutter/material.dart';

import '../common/feature_page_scaffold.dart';

/// 导出面板的默认 Tab（对应 PRD 四 / 五章）。
///
/// 「格式转换」与「图片压缩」在实现上是同一次编码，因此合并为同一页面，
/// 首页两个入口仅通过 [ExportTab] 决定默认聚焦的分区（PRD 四章首 / 五.6）。
enum ExportTab { convert, compress }

/// 导出面板：格式转换 + 压缩质量，一次编码完成（占位，对应 PRD「四、格式转换」「五、图片压缩」）。
class ExportPage extends StatelessWidget {
  const ExportPage({super.key, this.initialTab = ExportTab.convert});

  final ExportTab initialTab;

  static const _convertPoints = [
    '转换矩阵见 PRD 四.1（源格式 × 目标格式二维表）',
    'PNG → PNG / ICO：保留透明通道',
    'JPG 转出：本身无透明信息，仅封装转换',
    'PNG 转 JPG：透明区域自动填充底色，强提示"JPG 不支持透明通道，透明区域将丢失"',
    'WebP 仅支持导入，不可作为导出目标（PRD 四.5 / ADR-001）',
    'BMP 不写入透明通道，含透明时默认填白底并提示（PRD 四.6）',
    '导出前显示预估体积与压缩率（PRD 四.7）',
  ];

  static const _compressPoints = [
    '与格式转换共用本面板，一次编码完成，禁止两段式（PRD 五.6）',
    'JPG 压缩：质量 1–100，支持渐进式与色度抽样（4:2:0 / 4:4:4）',
    'PNG 压缩：有损调色板压缩 / 无损压缩二选一',
    'PNG 检测到半透明像素时自动禁用调色板并说明原因（PRD 五.2）',
    'WebP 压缩：暂缓，WebP 不可导出（PRD 五.3）',
    '边界：BMP 默认无压缩；ICO、SVG 不做压缩功能',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: ExportTab.values.length,
      initialIndex: initialTab.index,
      child: const FeaturePageScaffold(
        title: '导出',
        bottom: TabBar(
          tabs: [
            Tab(text: '格式转换'),
            Tab(text: '压缩'),
          ],
        ),
        body: TabBarView(
          children: [
            RequirementList(
              points: _convertPoints,
              header: '格式与压缩参数同屏生效，导出时只编码一次。以下为需求要点：',
            ),
            RequirementList(
              points: _compressPoints,
              header: '格式与压缩参数同屏生效，导出时只编码一次。以下为需求要点：',
            ),
          ],
        ),
      ),
    );
  }
}
