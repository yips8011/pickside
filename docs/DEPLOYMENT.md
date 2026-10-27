# 部署指南

两种推荐部署形态：

| 形态 | 优点 | 代价 |
|---|---|---|
| **Vercel + Neon(PostgreSQL) + Blob** | 免运维、免费额度起步、自动 HTTPS | Serverless 冷启动；无大陆节点，国内访问需自备加速 |
| **Docker / VPS（国内服务器推荐）** | 延迟低、稳定、成本可控 | 需要自己维护服务器与备份 |

---

## 一、Vercel（Serverless）

### 1. 准备数据库

1. Vercel 控制台 → **Storage** → **Create Database** → **Neon（Serverless Postgres）** → 创建（免费额度）
2. 创建后 **Connect to Project**，会自动注入 `DATABASE_URL`
3. 从 Neon 面板取出两条连接串：
   - **Pooled（连接池）** → 应用运行时用（写进 `DATABASE_URL`）
   - **Direct（直连）** → 仅用于执行迁移

### 2. 建表（用直连串）

```bash
cd backend
DATABASE_URL="postgresql://...<直连地址>...?sslmode=require" npx prisma migrate deploy
# Windows PowerShell:
# $env:DATABASE_URL="..."; npx prisma migrate deploy
```

> 连接池地址（`-pooler`）不支持迁移所需的会话级特性，迁移请务必用直连。

### 3. 导入代码并部署

1. 把本仓库推到 GitHub
2. Vercel → **Add New Project** → 导入仓库
3. Framework Preset 选择会自动识别（NestJS 或 Other 均可），**根目录填 `backend`**
4. Build Command 无需手动填写——`package.json` 里已提供 `vercel-build`（`prisma generate && nest build`）
5. 先不填环境变量，直接 Deploy 跑通一次

### 4. 配置环境变量并重新部署

| 变量 | 值 |
|---|---|
| `DATABASE_URL` | Neon **Pooled** 连接串 |
| `JWT_ACCESS_SECRET` | 强随机串 |
| `JWT_REFRESH_SECRET` | 强随机串 |
| `BLOB_READ_WRITE_TOKEN` | 连接 Vercel Blob 后自动注入（图片上传用） |

环境变量修改后必须 **Redeploy** 才生效。

### 5. 演示数据（可选）

```bash
DATABASE_URL="<直连串>" SEED_PASSWORD="<你的密码>" npm run prisma:seed
```

### 6. 绑定域名

Vercel → Project → **Settings → Domains** → 添加 `api.你的域名`，按提示在 DNS 添加 CNAME 指向 `cname.vercel-dns.com`。

### 7. 该形态的已知要点

| 事项 | 说明 |
|---|---|
| `prisma generate` 必须先于 `nest build` | 否则 `@prisma/client` 类型缺失，构建会报 `has no exported member 'UserRole'`。本仓库的 `vercel-build` / `postinstall` 已按此顺序配置。 |
| 不要用原生 `bcrypt` | Vercel 新版 npm 会拦截依赖的安装脚本，原生模块无法编译。本仓库统一使用纯 JS 的 **bcryptjs 2.4.3**（兼容 `$2a$`/`$2b$` 哈希）。 |
| `.vercelignore` 不要写 `uploads` | 会连 `src/uploads` 源码一起排除导致构建失败；如需排除运行时目录请写 `uploads/` 之外的精确路径。 |
| `expiresIn` 需可解析 | 若环境变量写成非法值，jsonwebtoken 会抛错；本仓库已做容错回退（`15m` / `7d`）。 |
| Serverless 无持久磁盘 | 文件日志、本地图片都会丢失，故日志走 `console.log`、图片走 Blob。 |

---

## 二、Docker / VPS（推荐国内部署）

### 1. 起数据库

```bash
cd backend
docker compose up -d          # PostgreSQL 16，端口 5432，库名 anonymous_polls
```

### 2. 部署后端

```bash
cd backend
cp .env.example .env          # 按需修改 DATABASE_URL / JWT 密钥
npm ci
npx prisma migrate deploy
npm run prisma:seed           # 可选
npm run build
node dist/src/main            # 或使用 pm2 / systemd 守护
```

生产建议：

```bash
npm i -g pm2
pm2 start dist/src/main --name zhandui-api
pm2 save && pm2 startup
```

### 3. Nginx 反向代理 + HTTPS

```nginx
server {
    listen 80;
    server_name api.example.com;

    client_max_body_size 10m;   # 图片上传

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
certbot --nginx -d api.example.com
```

### 4. 图片存储（VPS 形态）

本仓库 `uploads.controller.ts` 默认是 Vercel Blob 实现。VPS 部署请改用磁盘实现：

- `multer.diskStorage` 写入 `backend/uploads/images/`
- `GET /uploads/images/:file` 用 `res.sendFile` 返回
- 记得把 `backend/uploads` 纳入备份，并在 Nginx 里放行 `/uploads/`

### 5. 备份

```bash
# 每日备份示例
pg_dump "$DATABASE_URL" -Fc -f /backup/zhandui-$(date +%F).dump
```

---

## 三、移动端发布

```bash
cd mobile_app
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

- Release 默认 debug 签名，可直接安装/分发；上架市场需配置正式 keystore。
- iOS：`flutter build ipa`，需在 Xcode 配置开发者证书与 Bundle ID。
- 后端若有域名或协议变更（http→https），务必同步重新打包，因为地址是编译期注入的。

---

## 四、上线检查清单

- [ ] `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` 已替换为强随机值
- [ ] 演示账号密码已修改（或已跳过 seed）
- [ ] `DATABASE_URL` 指向生产库，迁移已执行
- [ ] 图片存储可用（Blob 令牌有效，或 VPS 磁盘目录可写并可访问）
- [ ] `CORS_ORIGIN` 按需配置（仅浏览器端需要）
- [ ] 备份策略已就绪（数据库 + uploads）
- [ ] App 内 `API_BASE_URL` 指向生产域名，`example.com` 占位已替换
