import 'package:flutter/material.dart';

import '../common/feature_page_scaffold.dart';

/// 尺寸与比例变换页（占位，对应 PRD「三、尺寸与比例变换」）。
class ResizePage extends StatelessWidget {
  const ResizePage({super.key});

  static const _requirements = [
    '自定义修改图片像素尺寸',
    '拉伸填充：不保持原图比例，强制拉伸填满目标尺寸',
    '保持比例裁剪（cover）：居中裁切',
    '保持比例留白填充（contain）：空白区域填充透明底色或自定义纯色',
    '重采样算法可选：默认高质量 Lanczos，进阶可加双线性、最近邻等',
  ];

  @override
  Widget build(BuildContext context) {
    return const FeaturePageScaffold(
      title: '尺寸与比例',
      requirementPoints: _requirements,
    );
  }
}
