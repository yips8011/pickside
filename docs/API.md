# API 参考

- 基础路径：`https://<你的域名>`（本地 `http://localhost:3000`）
- 鉴权头：`Authorization: Bearer <accessToken>`（标注 🔒 的接口需要）
- 请求/响应均为 `application/json`；上传接口为 `multipart/form-data`

## 统一响应

```json
// 成功
{ "success": true, "data": { }, "timestamp": "2026-01-01T00:00:00.000Z" }

// 失败
{ "success": false, "error": { "statusCode": 400, "message": "账号或密码错误" }, "timestamp": "..." }
```

## 通用约定

- 分页参数：`page`（从 1 开始）、`pageSize`（默认 20，上限 50）
- 列表响应：`{ items, total, page, pageSize }`（部分接口直接返回数组）
- 投票对象附带 `viewerState`：`{ myOptionId, isLiked, isFavorited, isDisliked }`
- 校验失败返回 400，`message` 为中文提示

---

## 认证 `/auth`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| POST | `/auth/register` | | 注册：`{ username, password, nickname }`，账号 5–24 位字母/数字/下划线（不能纯数字），昵称 2–8 字。限 3 次/分钟 |
| POST | `/auth/login` | | 登录：`{ username, password }`，`username` 可为账号或 uid。限 5 次/分钟 |
| POST | `/auth/refresh` | | 刷新：`{ refreshToken }`，返回新双令牌 |
| POST | `/auth/logout` | 🔒 | 注销（清空 refreshHash） |
| PATCH | `/auth/password` | 🔒 | 改密：`{ oldPassword, newPassword }` |

登录成功返回：

```json
{
  "user": { "id": 1, "uid": 100001, "username": "demo", "nickname": "演示用户", "role": "USER" },
  "accessToken": "…",
  "refreshToken": "…"
}
```

---

## 投票 `/polls`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/polls?tab=&page=&pageSize=` | 🔒 | 信息流。`tab`：`recommended`(默认) / `latest` / `hot` / `following`；自动过滤被拉黑作者与屏蔽词 |
| POST | `/polls` | 🔒 | 创建投票：`{ title, description?, options[2-8], isAnonymous?, allowAnonymousVote?, allowAnonymousComment?, allowComment?, allowLike?, allowShare?, endAt?, topicName?, topicNames?, templateKey?, imageUrls? }`；命中敏感词进入 `PENDING_REVIEW` |
| GET | `/polls/:id` | 🔒 | 详情（自动 +1 浏览量，含 `viewerState`） |
| GET | `/polls/:id/summary` | 🔒 | 结果摘要：领先项、占比、差距、是否结束 |
| GET | `/polls/:id/participants` | 🔒 | 参与者列表（匿名按规则遮蔽，`SUPER_ADMIN` 可揭开） |
| POST | `/polls/:id/vote` | 🔒 | 投票：`{ optionId, isAnonymous? }`；已结束/非法选项会被拒绝；同一用户仅一次 |
| POST/DELETE | `/polls/:id/like` | 🔒 | 点赞 / 取消 |
| POST/DELETE | `/polls/:id/dislike` | 🔒 | 点踩 / 取消 |
| POST/DELETE | `/polls/:id/favorite` | 🔒 | 收藏 / 取消 |
| POST | `/polls/:id/edit-request` | 🔒 | 作者申请恢复编辑（通知审核员） |
| PATCH | `/polls/:id/edit-approval` | 🔒 | 审核员通过编辑申请 |
| PATCH | `/polls/:id/content` | 🔒 | 作者修改标题/描述（需已通过审批，选项不可改） |

---

## 评论 `/comments` 与 `/polls/:id/comments`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/polls/:id/comments?page=&pageSize=` | 🔒 | 评论列表：含作者、`stance`（评论者投票立场）、`myReaction`、`canDelete` |
| POST | `/polls/:id/comments` | 🔒 | 发表评论：`{ content(1-500), isAnonymous? }`；投票关闭评论时拒绝 |
| POST | `/comments/:id/replies` | 🔒 | 回复评论（楼中楼） |
| POST | `/comments/:id/like` | 🔒 | 赞评论 |
| POST | `/comments/:id/dislike` | 🔒 | 踩评论 |
| DELETE | `/comments/:id` | 🔒 | 删除（软删除；作者或 REVIEWER/ADMIN/SUPER_ADMIN） |

---

## 用户 `/users`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/users/me` | 🔒 | 我的资料（缺失头像时自动分配默认头像） |
| PATCH | `/users/me` | 🔒 | 更新资料：`{ nickname?, username?, bio?, avatarUrl? }` |
| GET | `/users/me/stats` | 🔒 | 我的统计：投票数、获赞、关注/粉丝、点赞数、投票参与数、收藏数 |
| GET | `/users/me/voted-polls` | 🔒 | 我参与过的投票 |
| GET | `/users/me/favorites` | 🔒 | 我的收藏 |
| GET | `/users/me/liked-polls` | 🔒 | 我点赞的投票 |
| GET | `/users/me/following` | 🔒 | 我的关注 |
| GET | `/users/me/followers` | 🔒 | 我的粉丝 |
| GET | `/users/me/blocks` | 🔒 | 我的拉黑列表 |
| GET/PATCH | `/users/me/settings` | 🔒 | 通知开关、深色模式、屏蔽词 |
| GET/POST | `/users/me/drafts` | 🔒 | 投票草稿列表 / 新建 |
| PATCH/DELETE | `/users/me/drafts/:id` | 🔒 | 更新 / 删除草稿 |
| GET | `/users/:uid` | 🔒 | 他人资料（`uid` 为 6 位用户号） |
| GET | `/users/:uid/polls` | 🔒 | 他人公开投票 |
| POST/DELETE | `/users/:uid/follow` | 🔒 | 关注 / 取关（写通知、维护计数） |
| POST/DELETE | `/users/:uid/block` | 🔒 | 拉黑 / 取消 |

---

## 话题 `/topics`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/topics?q=` | 🔒 | 话题列表（热度排序，含 `followed`），首次访问自动初始化默认话题 |
| GET | `/topics/:id/polls?page=&pageSize=` | 🔒 | 话题下的投票 |
| POST/DELETE | `/topics/:id/follow` | 🔒 | 关注 / 取关话题 |

---

## 搜索 `/search`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/search?q=` | 🔒 | 同时搜索投票（标题/描述/分享码 `ZD-xxxx`）与用户（昵称/账号/uid），返回 `{ polls, users }` |

---

## 通知 `/notifications`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/notifications` | 🔒 | 最近 50 条；评论类通知附带 `targetPollId` |
| PATCH | `/notifications/read-all` | 🔒 | 全部已读 |
| PATCH | `/notifications/:id/read` | 🔒 | 单条已读 |

通知类型包含：`FOLLOW`、`POLL_VOTED`、`POLL_LIKED`、`POLL_FAVORITED`、`POLL_COMMENTED`、`COMMENT_REPLIED`、`COMMENT_LIKED`、`REPORT_*`、`USER_MUTED/UNMUTED`、`POLL_REVIEW_REQUIRED`、`COMMENT_REVIEW_REQUIRED` 等。

---

## 举报 `/reports`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| POST | `/reports` | 🔒 | `{ targetType: POLL\|COMMENT\|USER, targetId, reason: SPAM\|ILLEGAL\|HARASSMENT\|PORNOGRAPHIC\|OTHER, detail? }`；10 分钟限 5 条，重复待处理举报拦截；同一目标累计 3 条待处理则投票自动转审核并扣减作者信誉 |

---

## 内容 `/content`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| GET | `/content/ads` | | 启用中的广告位（首次访问自动初始化默认广告） |
| GET | `/content/announcements` | | 公告列表（自动初始化默认公告） |
| GET | `/content/update?platform=&build=` | | 版本检查：返回 `hasUpdate`、`forceUpdate`、下载地址 |
| POST | `/content/feedback` | 🔒 | 提交反馈：`{ category, content, contact?, includeLogs, logs?, appVersion?, buildNumber?, platform? }` |

---

## 上传 `/uploads`

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| POST | `/uploads/image` | 🔒 | `multipart/form-data`，字段名 `file`；≤5MB，`image/*` 且校验文件头；返回上传记录（`url` 形如 `/uploads/images/<文件名>`） |
| GET | `/uploads/images/:file` | | 读取图片（Blob 或磁盘实现） |

---

## 管理后台 `/admin`

所有接口均需 🔒 且满足对应角色（详见 [CONFIGURATION.md#22-自定义角色权限](./CONFIGURATION.md)）。

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/admin/reports` | 举报列表（含举报人 uid/昵称） |
| PATCH | `/admin/reports/:id` | 处理举报：`{ status: RESOLVED\|REJECTED, result? }`，给举报人发结果通知并记审计 |
| GET | `/admin/audit-logs?page=&pageSize=` | 审计日志（SUPER_ADMIN） |
| GET | `/admin/users?search=` | 用户列表（近 50） |
| PATCH | `/admin/users/:id/status` | 禁言/解禁/删除：`{ status: ACTIVE\|BANNED\|DELETED, muteDays?, reason? }` |
| DELETE | `/admin/users/:id` | 软删除用户 |
| PATCH | `/admin/users/:id/role` | 分配角色：`{ role?, customRoleId?, badge? }`（SUPER_ADMIN） |
| GET | `/admin/polls` | 投票列表（近 50） |
| PATCH | `/admin/polls/:id/moderation` | 投票治理：`{ status?, result? }`（`COMMENT_LOCKED`/`PUBLISHED`/`DELETED`/`LIKE_DISABLED`/`SHARE_DISABLED`） |
| GET | `/admin/comments` | 评论列表（近 50） |
| PATCH | `/admin/comments/:id/moderation` | 评论治理：`{ status: FOLDED\|其他=删除 }` |
| GET | `/admin/roles` | 自定义角色列表（含用户数） |
| POST/PATCH/DELETE | `/admin/roles[/:id]` | 角色增改删（删除时解绑用户并回退为 USER） |
| GET/POST/PATCH | `/admin/ads[/:id]` | 广告位管理（按 key upsert） |
| GET/POST | `/admin/announcements` | 公告管理（按 key upsert） |
| GET/POST | `/admin/update-config` | 版本更新配置 |
| GET | `/admin/feedback` | 用户反馈（近 100） |

---

## 健康检查

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/` | 返回服务名、状态与版本 |
