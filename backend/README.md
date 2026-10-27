# 站队 · 后端 API

NestJS 11 + Prisma 6 + PostgreSQL 16 实现的匿名投票社区后端。支持传统长驻进程与 Vercel Serverless 双形态部署。

## 环境要求

- Node.js ≥ 20
- PostgreSQL ≥ 14（推荐 16）
- npm 9+

## 快速启动

```bash
# 1) 起数据库（或使用已有 PostgreSQL）
docker compose up -d

# 2) 安装依赖（postinstall 会自动 prisma generate + nest build）
npm install

# 3) 配置环境变量
cp .env.example .env
#   Windows: copy .env.example .env
#   至少填写 DATABASE_URL / JWT_ACCESS_SECRET / JWT_REFRESH_SECRET

# 4) 建表 + 演示数据
npx prisma migrate deploy
npm run prisma:seed        # 演示账号：admin / demo，密码取 SEED_PASSWORD（默认 seed-password）

# 5) 启动
npm run start:dev          # http://localhost:3000
```

验证：`curl http://localhost:3000/` → `{"success":true,"data":{"name":"anonymous-polls-api",...}}`

## 常用脚本

| 命令 | 说明 |
|---|---|
| `npm run start:dev` | 开发模式（watch） |
| `npm run build` / `npm run start:prod` | 构建 / 生产启动（`node dist/src/main`） |
| `npm run vercel-build` | Vercel 构建（`prisma generate && nest build`） |
| `npm run prisma:migrate` | 开发期生成迁移 |
| `npx prisma migrate deploy` | 生产期应用迁移 |
| `npm run prisma:seed` | 写入演示数据（幂等） |
| `npm run prisma:studio` | 数据库可视化 |
| `npm run lint` / `npm run test` | 代码检查 / 单元测试 |

## 目录结构

```
src/
├── admin/            管理后台（举报/用户/投票/评论/角色/广告/公告/版本/反馈/审计）
├── auth/             注册登录、JWT 策略、改密
├── comments/         评论、回复、点赞点踩
├── common/           全局拦截器、异常过滤器、守卫、装饰器、请求日志
├── content/          广告位、公告、版本检查、反馈
├── notifications/    站内通知
├── polls/            投票 CRUD、投票、互动、结果摘要、编辑审批
├── prisma/           PrismaService
├── reports/          举报
├── search/           搜索
├── topics/           话题
├── uploads/          图片上传（Blob / 磁盘）
├── users/            资料、设置、草稿、关注、拉黑
├── app.module.ts
├── app.controller.ts 健康检查（GET /）
├── main.ts           长驻进程入口
└── main-vercel.ts    Serverless 入口（缓存 app 实例）
api/index.js          Vercel 函数入口（加载 dist）
prisma/               schema + migrations + seed
```

## 关键实现说明

- **统一响应**：`ApiResponseInterceptor` 包装成功响应为 `{ success, data, timestamp }`；`HttpExceptionFilter` 统一错误结构，并打印未处理异常堆栈。
- **认证**：JWT 只携带 `sub`，每次请求回查数据库，封禁/禁言即时生效；Refresh Token 哈希入库并轮换。
- **密码**：`bcryptjs`（纯 JS，Serverless 兼容），cost 12，兼容 `$2a$`/`$2b$` 历史哈希。
- **限流**：全局限流 + 登录/注册/刷新专项限流。
- **敏感词**：命中后内容进入待审核并通知审核员（不直接拒绝）。
- **匿名**：默认对所有人遮蔽作者，仅 `SUPER_ADMIN` 可揭开。
- **日志**：`console.log` 结构化输出（Vercel 日志面板可直接检索）。

## 环境变量

见 [`.env.example`](.env.example) 与 [../docs/CONFIGURATION.md](../docs/CONFIGURATION.md)。

## 部署

见 [../docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md)（Vercel / Docker / VPS）。

## 许可证

[MIT](../LICENSE) © 2026 yips8011 & DeepSeek
