# 安全说明

## 部署前必须处理

1. **替换 JWT 密钥**：`JWT_ACCESS_SECRET`、`JWT_REFRESH_SECRET` 必须使用强随机值（≥32 字节）。
   ```bash
   node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
   ```
2. **修改演示账号密码**：不要在生产环境保留 `admin` / `demo` 的默认密码；不保留演示数据时跳过 `prisma:seed`。
3. **不要提交 `.env`**：仓库已通过 `.gitignore` 排除 `.env`、日志、数据库导出文件。
4. **数据库账号最小权限**：生产库账号只需目标库的读写 DDL/DML 权限。

## 已实现的安全措施

| 项目 | 措施 |
|---|---|
| 密码存储 | bcryptjs cost 12（`$2a$`/`$2b$`），不可逆 |
| 令牌 | Access 短时（默认 15m）+ Refresh 轮换（7d），Refresh 哈希入库、登出即失效 |
| 会话校验 | 每次请求回查用户状态，封禁/禁言立即生效 |
| 传输 | 生产环境务必启用 HTTPS，并在反向代理设置 `X-Forwarded-Proto` |
| 响应头 | helmet（`X-Content-Type-Options`、`X-Frame-Options`、`Referrer-Policy` 等） |
| 限流 | 全局 120/分钟；登录、注册、刷新 5/分钟；举报 10 分钟 5 条 |
| 输入校验 | 全局 `ValidationPipe`（`whitelist` 拒绝多余字段）+ DTO 约束 |
| 上传 | 5MB 上限、MIME 白名单、文件头魔数校验、文件名服务端生成（防路径穿越） |
| 越权 | 角色/权限守卫；匿名内容仅 `SUPER_ADMIN` 可揭开 |
| 审计 | 管理操作写入 `AuditLog`（操作者、动作、目标、详情） |

## 已知限制

- 匿名性为应用层实现：数据库仍保存作者 ID，仅接口层遮蔽。运营方对匿名内容的处理应遵循所在地法规。
- 限流为进程内存实现（单实例有效）；多实例部署请改用 Redis 等共享存储。
- 举报、审核为工具能力，不替代平台自身的内容合规流程。

## 报告问题

发现安全缺陷请通过仓库 Issue 或邮件联系维护者，避免公开披露可利用细节。
