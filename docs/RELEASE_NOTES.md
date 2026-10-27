# 发布说明

## v1.0.0 · 首次开源发布

站队是一个匿名投票社区：匿名发布投票、参与讨论、实时查看群体选择比例。

### 本次包含

**移动端**
- Flutter（Android / iOS），Material 3
- Riverpod 状态管理 + Dio 网络层 + go_router 路由
- 信息流（推荐 / 最新 / 热门 / 关注）、投票详情与结果、评论树、个人中心、通知、搜索、话题、草稿

**后端**
- NestJS 11 + Prisma 6 + PostgreSQL 16
- JWT 双令牌：Access 15 分钟、Refresh 7 天并轮换；每次请求回查账号状态，封禁/禁言即时生效
- RBAC：7 种内置角色 + 自定义角色权限点；后台操作全量写入审计日志
- 业务模块：投票、选项、投票记录、评论/回复、点赞点踩、收藏、关注/粉丝、拉黑、话题、搜索、通知、草稿、反馈
- 举报：10 分钟限 5 条、重复举报拦截、同一目标累计 3 条待处理自动转审核并扣减作者信誉
- 内容治理：敏感词命中进入待审核（`PENDING_REVIEW`）、评论折叠、编辑申请与审批流
- 匿名：默认遮蔽作者，仅 `SUPER_ADMIN` 可揭开（`revealedByAdmin`）
- 图片上传：≤5MB、MIME 白名单 + 文件头魔数校验、服务端生成文件名（防路径穿越）；Vercel Blob 与本地磁盘自动切换
- 基础设施：统一响应 `{ success, data, timestamp }`、全局校验管道、异常过滤器（含堆栈日志）、helmet、CORS、请求限流

**部署**
- Vercel Serverless：`api/index.js` 入口 + `vercel-build`（`prisma generate && nest build`）
- Docker / VPS：`docker compose` 起 PostgreSQL，`pm2`/`systemd` 守护进程，Nginx 反代示例

**文档**
- `README.md`：项目介绍、快速开始、配置表、API 概览、部署入口
- `docs/CONFIGURATION.md`：环境变量逐项说明、角色权限矩阵、迁移与 App 配置
- `docs/DEPLOYMENT.md`：Vercel（含 5 个已知坑位）/ Docker·VPS / 上线检查清单
- `docs/API.md`：78 个接口的完整参考
- `SECURITY.md`：部署前必做项、已实现的安全措施、已知限制

### 快速开始

```bash
# 后端
cd backend
docker compose up -d
npm install
cp .env.example .env         # 填写 DATABASE_URL 与 JWT 密钥
npx prisma migrate deploy
npm run prisma:seed          # 演示账号 admin / demo
npm run start:dev

# 移动端
cd ../mobile_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### 演示账号

| 账号 | 角色 | 密码 |
|---|---|---|
| `admin` | SUPER_ADMIN | `SEED_PASSWORD` 环境变量（默认 `seed-password`） |
| `demo` | USER | 同上 |

> 首次登录后请立即修改密码；正式环境请跳过往演示数据写入。

### 许可证

[MIT](../LICENSE) © 2026 **yips8011** & **DeepSeek**
