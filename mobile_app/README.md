# 站队 · 移动端（Flutter）

匿名投票社区 App，Android / iOS 双端。

## 环境要求

- Flutter ≥ 3.22（Dart ≥ 3.4）
- Android SDK（构建 APK）/ Xcode（构建 iOS）

## 运行

```bash
flutter pub get

# Android 模拟器（10.0.2.2 指向宿主机）
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# 真机（与电脑同局域网）
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000

# 线上
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## 打包

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
# 产物：build/app/outputs/flutter-apk/app-release.apk

flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```

> 后端地址是**编译期注入**的，切换环境需要重新打包。
> Release 默认使用 debug 签名（可直接安装）；上架应用市场前请在 `android/app/build.gradle.kts` 配置正式签名。

## 首次使用前请替换占位信息

`lib/main.dart` 中搜索 `example.com`：

| 位置 | 占位 | 用途 |
|---|---|---|
| 分享二维码 | `https://example.com/download?from=share&code=` | 分享落地页 |
| 关于页 · 官网 | `https://www.example.com` | 官网链接 |
| 关于页 · 邮箱 | `support@example.com` | 反馈邮箱 |

应用标识（可选修改）：

- `android/app/build.gradle.kts`：`namespace` / `applicationId`（默认 `com.yips.zhandui`）
- `ios/Runner.xcodeproj`：Bundle Identifier
- `pubspec.yaml`：`version`

## 代码结构

```
lib/
├── main.dart        应用入口、主题、主要页面与业务逻辑（含 API 客户端 apiBaseUrl）
├── models.dart      数据模型与序列化
├── services.dart    Dio HTTP 客户端与接口封装
├── state.dart       全局状态（Riverpod providers）
├── navigation.dart  路由（go_router）
├── screens.dart     独立页面
└── widgets.dart     通用组件
assets/fonts/        字体资源（SmileySans）
```

## 常见问题

| 现象 | 处理 |
|---|---|
| 构建报 “project path contains non-ASCII characters” | 项目路径含中文，移动到纯英文路径再构建 |
| Dart AOT 报找不到 `app.dill` | 同上，路径必须为 ASCII |
| `pub get` 慢或失败 | 设置国内镜像：`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` |
| 请求超时 | 确认 `API_BASE_URL` 可达；Android 真机不能用 `10.0.2.2`；生产环境必须是 https |

## 许可证

[MIT](../LICENSE) © 2026 yips8011 & DeepSeek
