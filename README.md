# 站队 · 匿名投票社区

> 站队：匿名投票社区 App —— Flutter 移动端 + NestJS/Prisma/PostgreSQL 后端。匿名发投票、实时看比例、评论讨论，内置举报审核、RBAC 权限、站内通知与图片上传，支持 Vercel Serverless 与 Docker/VPS 双形态部署。

> 一个围绕观点、选择与匿名表达的投票社区：匿名发投票、参与讨论、看群体站在哪一边。
> 前后端完整实现，开箱即可自行部署。

- **移动端**：Flutter（Android / iOS），Material 3，Riverpod + Dio + go_router
- **后端**：NestJS 11 + Prisma 6 + PostgreSQL 16，JWT 双令牌，RBAC 权限
- **部署**：Vercel Serverless（含 serverless 入口）、Docker、传统 VPS 均可

> **English** — Zhandui is an anonymous polling community app: a Flutter client plus a NestJS/Prisma/PostgreSQL backend with anonymous votes, live result ratios, comments, reporting & moderation, RBAC, in-app notifications and image uploads. Deployable on Vercel Serverless or Docker/VPS.

```
├── backend/       NestJS 后端 API
├── mobile_app/    Flutter 移动端
├── docs/          配置 / 部署 / 接口文档
└── LICENSE        MIT
```

---

## 功能特性

**投票**
- 信息流四个频道：推荐 / 最新 / 热门 / 关注
- 创建投票（2–8 个选项、过期时间、匿名开关、话题、最多 3 张配图）
- 投票、查看实时比例、结果摘要（领先项、差距、占比）
- 点赞 / 点踩 / 收藏；浏览计数
- 敏感词命中自动进入待审核（`PENDING_REVIEW`）

**评论**
- 楼中楼回复、点赞/点踩、折叠敏感评论
- 展示评论者在该投票中的立场（stance）

**社交**
- 关注 / 粉丝、拉黑（内容过滤）、话题关注
- 用户资料、徽章、自定义角色、统计面板

**内容治理**
- 举报（多类型、限频、重复举报拦截、累计 3 条自动进审核）
- 管理后台：举报处理、用户禁言/封禁/删除、投票与评论审核、自定义角色、广告位、公告、版本更新配置、用户反馈
- 全量审计日志

**系统能力**
- 统一响应格式 `{ success, data, timestamp }`
- 全局参数校验、异常过滤器、请求限流（Throttler）
- 图片上传（本地磁盘 / Vercel Blob 双实现）
- 站内通知（评论、点赞、关注、举报结果、审核结果）

---

## 技术栈

| 层 | 选型 |
|---|---|
| 后端框架 | NestJS 11（Express 适配器） |
| ORM | Prisma 6 |
| 数据库 | PostgreSQL 16 |
| 认证 | JWT Access/Refresh 双令牌 + Passport |
| 密码哈希 | bcryptjs（纯 JS，Serverless 友好） |
| 参数校验 | class-validator / class-transformer |
| 安全 | helmet、CORS、Throttler 限流 |
| 图片存储 | 本地磁盘（默认）/ Vercel Blob |
| 移动端 | Flutter（Riverpod、Dio、go_router、freezed） |

---

## 快速开始

### 1. 准备数据库

```bash
# 方式一：Docker（推荐，一条命令起 PostgreSQL 16）
cd backend
docker compose up -d

# 方式二：使用已有 PostgreSQL，自行创建数据库
#   CREATE DATABASE anonymous_polls;
```

### 2. 启动后端

```bash
cd backend

# 安装依赖（根目录的 postinstall 会自动执行 prisma generate + nest build）
npm install

# 复制环境变量模板，按实际情况修改
cp .env.example .env      # Windows: copy .env.example .env

# 建表（执行 prisma/migrations 下的全部迁移）
npx prisma migrate deploy

# 写入演示数据（管理员 admin / 演示用户 demo）
npm run prisma:seed

# 启动开发服务器（默认 http://localhost:3000）
npm run start:dev
```

验证：

```bash
curl http://localhost:3000/
# {"success":true,"data":{"name":"anonymous-polls-api","status":"ok","version":"1.0.0"}}
```

> 演示账号密码来自 `SEED_PASSWORD` 环境变量，未设置时为 `seed-password`。
> **首次登录后请立即修改密码。**

### 3. 运行移动端

```bash
cd mobile_app

flutter pub get

# 连接本机后端（Android 模拟器用 10.0.2.2 访问宿主机）
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# 真机 / 生产环境指向线上 API
flutter run --dart-define=API_BASE_URL=https://api.example.com

# 打包 APK
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

> `API_BASE_URL` 未指定时默认 `http://10.0.2.2:3000`。
> 构建前请把 `mobile_app/lib/main.dart` 中的 `example.com` 占位（官网/邮箱/分享链接）替换为你自己的域名。

---

## 配置说明

后端所有配置通过环境变量注入（本地放 `backend/.env`，线上用平台的环境变量面板）。

| 变量 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `DATABASE_URL` | ✅ | — | PostgreSQL 连接串，例如 `postgresql://user:pass@host:5432/anonymous_polls?schema=public`；Serverless 环境请用连接池地址 |
| `JWT_ACCESS_SECRET` | ✅ | `dev-access` | Access Token 签名密钥，生产环境务必改为强随机长串 |
| `JWT_REFRESH_SECRET` | ✅ | `dev-refresh` | Refresh Token 签名密钥 |
| `JWT_ACCESS_EXPIRES_IN` | | `15m` | Access Token 有效期（如 `15m`、`900` 秒） |
| `JWT_REFRESH_EXPIRES_IN` | | `7d` | Refresh Token 有效期 |
| `PORT` | | `3000` | 本地监听端口（Vercel 环境自动忽略） |
| `CORS_ORIGIN` | | 本地调试地址 | 允许的来源，逗号分隔 |
| `BLOB_READ_WRITE_TOKEN` | | — | Vercel Blob 令牌，仅在使用 Blob 上传时需要 |
| `SEED_PASSWORD` | | `seed-password` | 演示数据初始密码 |

生成强随机密钥：

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

更多细节见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md)。

---

## API 概览

统一响应格式：

```json
// 成功
{ "success": true, "data": { }, "timestamp": "2026-01-01T00:00:00.000Z" }
// 失败
{ "success": false, "error": { "statusCode": 400, "message": "..." }, "timestamp": "..." }
```

鉴权：`Authorization: Bearer <accessToken>`

| 模块 | 主要接口 |
|---|---|
| 认证 | `POST /auth/register` `POST /auth/login` `POST /auth/refresh` `POST /auth/logout` `PATCH /auth/password` |
| 投票 | `GET/POST /polls` `GET /polls/:id` `GET /polls/:id/summary` `POST /polls/:id/vote` `POST/DELETE /polls/:id/{like,dislike,favorite}` |
| 评论 | `GET/POST /polls/:id/comments` `POST /comments/:id/replies` `POST /comments/:id/{like,dislike}` `DELETE /comments/:id` |
| 用户 | `GET/PATCH /users/me` `GET /users/me/{stats,voted-polls,favorites,liked-polls,following,followers,blocks,settings,drafts}` `GET /users/:uid` |
| 社交 | `POST/DELETE /users/:uid/follow` `POST/DELETE /users/:uid/block` |
| 话题 | `GET /topics` `GET /topics/:id/polls` `POST/DELETE /topics/:id/follow` |
| 搜索 | `GET /search?q=` |
| 通知 | `GET /notifications` `PATCH /notifications/read-all` `PATCH /notifications/:id/read` |
| 举报 | `POST /reports` |
| 内容 | `GET /content/{ads,announcements,update}` `POST /content/feedback` |
| 上传 | `POST /uploads/image` `GET /uploads/images/:file` |
| 后台 | `/admin/*`（举报、用户、投票、评论、角色、广告、公告、版本、反馈、审计日志） |

完整清单见 [docs/API.md](docs/API.md)。

---

## 部署

| 方式 | 适用场景 | 文档 |
|---|---|---|
| **Vercel**（Serverless + Vercel Postgres/Neon + Blob） | 免运维、免费额度起步 | [docs/DEPLOYMENT.md#vercel](docs/DEPLOYMENT.md) |
| **Docker / VPS** | 国内用户、可控成本、长期稳定 | [docs/DEPLOYMENT.md#docker--vps](docs/DEPLOYMENT.md) |

---

## 安全须知

- `.env`、数据库导出、日志等已在 `.gitignore` 中排除，**切勿提交任何真实密钥**。
- 生产环境必须替换 `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET`，并修改演示账号密码。
- 匿名内容的可见性由服务端按角色控制（仅 `SUPER_ADMIN` 可揭开匿名）。
- 举报/审核为应用层能力，正式运营请结合平台内容合规要求配套人工审核流程。

---

## 许可证

[MIT](LICENSE) © 2026 **yips8011** & **DeepSeek**
