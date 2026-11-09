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
│   ├── log/              # AppLogger 日志薄封装
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

## 编码规范

### 1. Git 提交规则

采用 **Conventional Commits**，格式：`<type>(<scope>): <中文描述>`。

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复缺陷 |
| `refactor` | 重构（不改行为） |
| `perf` | 性能优化 |
| `test` | 测试 |
| `docs` | 文档 |
| `style` | 格式/换行（不改逻辑） |
| `chore` | 构建、依赖、配置 |

约定：
- 描述用中文，一句话说清「为什么」，控制在 50 字内；
- 单次提交只做一件事，禁止把多个无关改动混在一次提交；
- 不提交密钥 / 证书 / 大体积二进制（见 `.gitignore`）；
- 当前**不装 commit-msg hook 强制校验**，靠自觉遵守。

### 2. 代码风格

- 统一用 `dart format`（行宽 80），提交前必跑；
- 换行符统一 **LF**（`.gitattributes` 已锁定，Windows 也不例外）；
- 静态检查基于 `flutter_lints` + `analysis_options.yaml` 精选规则，`flutter analyze` 必须零 issue；
- 命名：文件/目录 `snake_case`；类 `UpperCamelCase`；变量/方法 `lowerCamelCase`；常量 `lowerCamelCase`（Dart 惯例，非全大写）；
- 导入：包内相对导入，包外 `package:` 导入，按「dart 标准库 → 三方包 → 本项目」分组，组间空行；
- 注释统一**中文**，公开 API 用 `///` 文档注释；术语（如 Isolate、chunk）保留原文。

### 3. 日志

- **禁止 `print`**（`avoid_print` 已开启），统一走 `AppLogger`（`lib/core/log/app_logger.dart`）；
- 分级：`debug` / `info` / `warn` / `error`；`debug`、`info` 仅在 `kDebugMode` 输出，`warn`、`error` 全环境保留；
- 打日志时带 `name`（模块名，便于 DevTools 过滤）与 `data`（结构化上下文，如格式、尺寸、耗时）；
- **铁律：纯本地离线，禁止任何远程日志上报**（不接入 Sentry / Firebase 等联网服务）；
- 不要打印大对象（整张图像素、完整文件内容），只打关键字段。

### 4. 错误处理

- 错误码体系遵循 PRD 九.2；面向用户的错误提示走本地化文案（ARB），日志里保留原始异常；
- 捕获异常时同时记录 `error` 与 `stackTrace`，禁止 `catch (e) {}` 静默吞异常；
- 平台差异（如插件缺失、格式不支持）在**能力矩阵层**判定并前置拦截，不在功能层散落 `try/catch` 兜底；
- 图像编解码等重操作失败时，向用户返回可读原因（如「该格式不支持透明通道」），而非堆栈。

