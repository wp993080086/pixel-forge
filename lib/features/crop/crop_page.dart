import 'package:flutter/material.dart';

import '../common/feature_page_scaffold.dart';

/// 裁剪功能页（占位，对应 PRD「二、裁剪功能」）。
class CropPage extends StatelessWidget {
  const CropPage({super.key});

  static const _requirements = [
    '选区形状：正方形选区、圆形选区',
    '手动指定选区目标像素尺寸（指原图像素尺寸，选区框按当前视图缩放渲染）',
    '钳制规则：输入上限为原图尺寸；拖拽超出图片边界时自动吸附钳制',
    '像素对齐：选区吸附整数像素，实时显示原图坐标 (x, y) 与尺寸（宽×高）',
    '选区与视图联动：选区定义在原图坐标系，视图缩放/平移仅影响显示，选区框跟随渲染',
    '导出 PNG 完整保留原图透明通道',
    '圆形选区：输出方形画布，圆外填充透明，界面提示"不存在圆形图片文件"',
  ];

  @override
  Widget build(BuildContext context) {
    return const FeaturePageScaffold(
      title: '裁剪',
      requirementPoints: _requirements,
    );
  }
}
