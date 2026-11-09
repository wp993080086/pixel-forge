# 像素工坊 (Pixel Forge)

纯本地离线图片编辑工具。原图不上传服务器，所有解码、编辑、压缩、转换全部本地运行。

需求文档：`docs/产品需求清单-本地图片编辑工具.md`

## 端与优先级

Windows（首发基线）→ HarmonyOS Next（优先级高于 Android）→ Android → Web → 微信小程序（独立代码库，后续单列）

## 版本策略

- 开发基线：官方 Flutter 3.44.9（本机已装）
- 代码 API 面控制在 **3.41 兼容范围**内
- 鸿蒙构建使用 Flutter-OH 适配版 SDK（CPF-Flutter / OpenHarmony SIG 维护），
  届时在 3.44.9+ohos（canary，同 3.44 基线）与 3.41.10-ohos（稳定线）之间验证取舍；
  接入前需验证 `Platform.operatingSystem` 在 OH 上的取值（见 `lib/core/platform/app_platform_impl_native.dart`）
- 架构铁律：图像编解码、重采样、压缩全部走纯 Dart 库（`image` 包），
  平台插件只保留文件选择/保存等薄层（PRD 七.2）

## 目录结构

```
lib/
├── app/                  # 应用入口：MaterialApp、路由、主题
├── core/
│   ├── di/               # Riverpod providers
│   ├── image/            # 图片格式元数据（alpha/动图/矢量/容器）
│   └── platform/         # 端检测 + 各端能力矩阵（PRD 七章）
├── features/             # 功能模块：home / crop / resize / export
│                         # （格式转换与压缩合并为 export 单页，靠 ?tab= 区分分区）
└── services/file/        # 导入导出服务（file_selector 薄层 + 平台条件导入）
```

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

注意：本机代理环境会导致 `flutter test` 无法连接 flutter_tester，
运行测试前临时清空代理变量：`http_proxy= https_proxy= HTTP_PROXY= HTTPS_PROXY= flutter test`
