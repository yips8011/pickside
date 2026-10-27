# 配置说明

本文档说明后端（`backend/`）与移动端（`mobile_app/`）的全部可配置项。

---

## 1. 后端环境变量

配置来源：本地开发写在 `backend/.env`；部署到平台时写在平台的环境变量面板（Vercel / Docker / systemd 等）。
模板见 [`backend/.env.example`](../backend/.env.example)。

### 1.1 数据库

| 变量 | 必填 | 示例 | 说明 |
|---|---|---|---|
| `DATABASE_URL` | ✅ | `postgresql://user:pass@localhost:5432/anonymous_polls?schema=public` | Prisma 连接串。Serverless 平台（Vercel）请使用**连接池地址**（如 Neon 的 `-pooler` 域名），传统服务器用直连即可。 |

> 若使用连接池（PgBouncer / Neon pooler），`prisma migrate` 需要**直连**地址：
> 临时用 `DATABASE_URL="<直连串>" npx prisma migrate deploy` 执行迁移，应用运行时使用池化地址。

### 1.2 认证与令牌

| 变量 | 必填 | 默认 | 说明 |
|---|---|---|---|
| `JWT_ACCESS_SECRET` | ✅ | `dev-access` | Access Token 密钥。生产环境必须替换。 |
| `JWT_REFRESH_SECRET` | ✅ | `dev-refresh` | Refresh Token 密钥。生产环境必须替换。 |
| `JWT_ACCESS_EXPIRES_IN` | | `15m` | 支持 `900`（秒）或 timespan：`ms/s/m/h/d/w/y` 组合，如 `15m`、`7d`。非法值会自动回退默认。 |
| `JWT_REFRESH_EXPIRES_IN` | | `7d` | 同上。 |

生成强随机密钥：

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

设计说明：
- Access Token 只携带 `sub`（用户 ID），每次请求由服务端回查数据库，禁用/禁言即时生效。
- Refresh Token 的哈希（bcrypt）存库，登录/刷新时轮换，登出即失效。

### 1.3 网络与安全

| 变量 | 默认 | 说明 |
|---|---|---|
| `PORT` | `3000` | 本地监听端口；Serverless 平台自动忽略。 |
| `CORS_ORIGIN` | `http://localhost:3000,http://10.0.2.2:3000` | 允许跨域的来源，逗号分隔。原生 App 不带 Origin，不依赖此配置。 |

内置安全措施：
- `helmet` 安全响应头
- `compression` 响应压缩
- 全局限流：默认 120 次 / 60 秒（`ThrottlerGuard`）；登录/注册/刷新单独收紧到 5 次 / 60 秒，注册 3 次 / 60 秒
- 全局 `ValidationPipe`（`whitelist: true`，拒绝多余字段）

### 1.4 图片存储

上传模块有两套实现，按部署方式选择：

| 部署形态 | 使用的实现 | 需要配置 |
|---|---|---|
| 传统服务器 / Docker（`src/uploads/uploads.controller.ts` 默认版本，磁盘存储） | 写入 `backend/uploads/images/` | 无需额外变量 |
| Vercel Serverless | 本仓库默认已改为 **Vercel Blob** | `BLOB_READ_WRITE_TOKEN`（Vercel 控制台连接 Blob 后自动注入） |

限制：单文件 ≤ 5 MB，仅 `jpg/png/gif/webp`（按文件头魔数校验）。
对外访问路径固定为 `/uploads/images/:file`，移动端据此拼接 URL，切换存储实现不影响客户端。

> 需要换回磁盘存储：把 `uploads.controller.ts` 中的 Blob 相关代码替换为 `multer.diskStorage` + `res.sendFile` 即可（Git 历史中保留了原实现）。

### 1.5 演示数据

| 变量 | 默认 | 说明 |
|---|---|---|
| `SEED_PASSWORD` | `seed-password` | `npm run prisma:seed` 创建的管理员/演示用户密码 |

---

## 2. 角色与权限

### 2.1 内置角色（`UserRole`）

`GUEST` · `USER` · `REVIEWER` · `REPORT_HANDLER` · `AD_MANAGER` · `ADMIN` · `SUPER_ADMIN`

### 2.2 自定义角色权限（`AdminPermission`）

`REPORT_MANAGE` · `USER_BAN` · `USER_DELETE` · `POLL_MODERATE` · `COMMENT_MODERATE` · `AD_MANAGE` · `ANNOUNCEMENT_MANAGE` · `ROLE_MANAGE`

后台路由的角色要求：

| 路由 | 允许角色 |
|---|---|
| `/admin/reports` `/admin/users` `/admin/polls` `/admin/comments` `/admin/roles`(GET) `/admin/ads`(GET) `/admin/announcements`(GET) | REVIEWER / REPORT_HANDLER / AD_MANAGER / ADMIN / SUPER_ADMIN |
| `/admin/audit-logs` `/admin/roles`(POST/PATCH/DELETE) | SUPER_ADMIN（角色新建/修改为 ADMIN + SUPER_ADMIN） |
| `/admin/ads`(POST/PATCH) `/admin/announcements`(POST) `/admin/update-config` | AD_MANAGER / ADMIN / SUPER_ADMIN |
| `/admin/feedback` | ADMIN / SUPER_ADMIN |

拥有自定义角色的用户可以凭权限点通过校验（`RolesGuard` 将角色映射到其所需权限，再与用户的权限集合求交）。

### 2.3 匿名内容可见性

- 匿名投票/评论对普通用户隐藏作者，管理员亦不可见；
- 仅 `SUPER_ADMIN` 可揭开匿名（`revealedByAdmin`），且该行为会体现在返回字段中。

---

## 3. 数据库与迁移

```bash
cd backend
npx prisma migrate deploy     # 生产：按顺序应用 prisma/migrations
npx prisma migrate dev        # 开发：修改 schema.prisma 后生成新迁移
npx prisma studio             # 可视化查看数据
npm run prisma:seed           # 写入演示数据（幂等，重复执行不会重复插入）
```

- 表名与 Prisma 模型同名（`User`、`Poll`、`Comment`…），迁移文件已随仓库提供。
- 重置本地数据库：`npx prisma migrate reset`（会清空数据并重跑迁移与 seed）。

---

## 4. 移动端配置

### 4.1 后端地址

编译期通过 `--dart-define` 注入：

```bash
flutter run   --dart-define=API_BASE_URL=http://10.0.2.2:3000        # Android 模拟器
flutter run   --dart-define=API_BASE_URL=http://192.168.1.10:3000   # 真机同局域网
flutter run   --dart-define=API_BASE_URL=https://api.example.com    # 线上
```

未注入时默认 `http://10.0.2.2:3000`（`lib/main.dart` 顶部 `apiBaseUrl`）。

> 地址不要以 `/` 结尾：图片 URL 由 `API_BASE_URL + /uploads/images/...` 拼接。

### 4.2 需要替换的自有信息

`lib/main.dart` 中搜索 `example.com`，把以下占位替换为你自己的信息：

| 位置 | 占位值 | 用途 |
|---|---|---|
| 分享二维码 | `https://example.com/download?from=share&code=` | 投票分享落地页 |
| 关于页 · 官方网站 | `https://www.example.com` | 官网链接 |
| 关于页 · 联系邮箱 | `support@example.com` | 反馈邮箱 |

### 4.3 应用标识

- Android：`mobile_app/android/app/build.gradle.kts` 中 `namespace` / `applicationId`（当前 `com.yips.zhandui`）
- iOS：`mobile_app/ios/Runner.xcodeproj` 的 Bundle Identifier
- 版本号：`mobile_app/pubspec.yaml` 的 `version: 1.0.0+4023`

### 4.4 构建注意

- **项目路径不要包含中文**：Android Gradle 与 Dart AOT 在非 ASCII 路径下会失败，请放在纯英文路径（如 `D:\zhandui`）。
- 中国大陆网络建议设置镜像后再构建：

```bash
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

- Release 包默认使用 debug 签名（开箱可安装）；上架应用市场前需在 `build.gradle.kts` 配置正式签名。
