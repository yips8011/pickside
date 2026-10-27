import {
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  AssignRoleDto,
  ModerationDto,
  UpdateReportDto,
  UpdateUserStatusDto,
  UpsertAdDto,
  UpsertAnnouncementDto,
  UpsertCustomRoleDto,
  UpsertUpdateConfigDto,
} from './dto';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  private audit(
    actorId: number,
    action: string,
    target: string,
    detail?: string,
  ) {
    return this.prisma.auditLog.create({
      data: { actorId, action, target, detail },
    });
  }

  async auditLogs(page = 1, pageSize = 50) {
    const take = Math.min(Math.max(pageSize, 1), 100);
    const skip = (Math.max(page, 1) - 1) * take;
    const where = {};
    const [items, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          actor: {
            select: {
              id: true,
              uid: true,
              username: true,
              nickname: true,
              role: true,
              badge: true,
              customRole: true,
            },
          },
        },
      }),
      this.prisma.auditLog.count({ where }),
    ]);
    return { items, total, page, pageSize: take };
  }

  reports() {
    return this.prisma.report.findMany({
      orderBy: { createdAt: 'desc' },
      include: { reporter: { select: { uid: true, nickname: true } } },
    });
  }

  async updateReport(id: number, handlerId: number, dto: UpdateReportDto) {
    const report = await this.prisma.report.update({
      where: { id },
      data: { ...dto, handlerId },
    });
    await this.audit(
      handlerId,
      'REPORT_HANDLE',
      `${report.targetType}#${report.targetId}`,
      JSON.stringify(dto),
    );
    await this.prisma.notification.create({
      data: {
        userId: report.reporterId,
        type: 'REPORT_RESULT',
        title: '举报处理完成',
        body:
          dto.result ??
          (dto.status === 'RESOLVED'
            ? '平台已处理你提交的举报'
            : '举报已驳回，内容保持正常显示'),
        targetType: report.targetType,
        targetId: report.targetId,
      },
    });
    return report;
  }

  users(search?: string) {
    return this.prisma.user.findMany({
      where: search
        ? {
            OR: [
              { username: { contains: search, mode: 'insensitive' } },
              { nickname: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {},
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async updateUserStatus(
    actorId: number,
    id: number,
    dto: UpdateUserStatusDto,
  ) {
    const target = await this.prisma.user.findUnique({ where: { id } });
    if (!target) throw new BadRequestException('User not found');
    if (target.role === 'SUPER_ADMIN' || target.id === actorId) {
      throw new ForbiddenException('Cannot change this user status');
    }
    const actor = await this.prisma.user.findUnique({
      where: { id: actorId },
      select: { nickname: true, username: true },
    });
    const adminName = actor?.nickname || actor?.username || '管理员';
    const data =
      dto.status === 'BANNED'
        ? {
            status: 'ACTIVE' as const,
            isMuted: true,
            mutedUntil: dto.muteDays
              ? new Date(Date.now() + dto.muteDays * 24 * 60 * 60 * 1000)
              : null,
            mutedReason: dto.reason?.trim() || null,
          }
        : dto.status === 'ACTIVE'
          ? {
              status: 'ACTIVE' as const,
              isMuted: false,
              mutedUntil: null,
              mutedReason: null,
            }
          : { status: 'DELETED' as const, deletedAt: new Date() };
    const updated = await this.prisma.user.update({
      where: { id },
      data,
    });
    if (dto.status === 'BANNED') {
      const durationLabel = dto.muteDays
        ? dto.muteDays >= 365
          ? '1年'
          : dto.muteDays >= 30
            ? '1个月'
            : `${dto.muteDays}天`
        : '永久';
      await this.prisma.notification.create({
        data: {
          userId: id,
          type: 'USER_MUTED',
          title: '账号已被禁言',
          body: `您被${adminName}禁言${durationLabel}，禁言期间不能发布投票或评论。`,
          targetType: 'USER',
          targetId: id,
        },
      });
    } else if (dto.status === 'ACTIVE' && target.isMuted) {
      await this.prisma.notification.create({
        data: {
          userId: id,
          type: 'USER_UNMUTED',
          title: '账号已解除禁言',
          body: `管理员${adminName}已解除你的禁言限制。`,
          targetType: 'USER',
          targetId: id,
        },
      });
    }
    await this.audit(
      actorId,
      'USER_STATUS',
      `USER#${id}`,
      JSON.stringify({ status: dto.status, muteDays: dto.muteDays ?? null }),
    );
    return updated;
  }

  async deleteUser(actorId: number, id: number) {
    const target = await this.prisma.user.findUnique({ where: { id } });
    if (!target) throw new BadRequestException('User not found');
    if (target.role === 'SUPER_ADMIN' || target.id === actorId) {
      throw new ForbiddenException('Cannot delete this user');
    }
    const updated = await this.prisma.user.update({
      where: { id },
      data: { status: 'DELETED', deletedAt: new Date() },
    });
    await this.audit(actorId, 'USER_DELETE', `USER#${id}`);
    return updated;
  }

  async assignUserRole(actorId: number, id: number, dto: AssignRoleDto) {
    const actor = await this.prisma.user.findUnique({ where: { id: actorId } });
    const target = await this.prisma.user.findUnique({ where: { id } });
    if (!actor || !target) throw new BadRequestException('User not found');
    if (actor.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Only super admin can assign permissions');
    }
    if (target.role === 'SUPER_ADMIN') {
      throw new ForbiddenException('Cannot change super admin role');
    }
    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.role ? { role: dto.role } : {}),
        ...(dto.customRoleId !== undefined
          ? { customRoleId: dto.customRoleId }
          : {}),
        ...(dto.badge !== undefined ? { badge: dto.badge } : {}),
      },
      include: { customRole: true },
    });
    await this.audit(actorId, 'USER_ROLE', `USER#${id}`, JSON.stringify(dto));
    return updated;
  }

  polls() {
    return this.prisma.poll.findMany({
      orderBy: { createdAt: 'desc' },
      include: { author: { select: { uid: true, nickname: true } } },
      take: 50,
    });
  }

  async moderatePoll(id: number, actorId: number, dto: ModerationDto) {
    const poll = await this.prisma.poll.findUnique({ where: { id } });
    const data: Record<string, unknown> = {};
    if (dto.status === 'DELETED') {
      data.status = 'DELETED';
      data.deletedAt = new Date();
    } else if (dto.status) {
      data.status = dto.status;
      if (dto.status === 'COMMENT_LOCKED') data.allowComment = false;
      if (dto.status === 'COMMENT_LOCKED') data.allowLike = false;
      if (dto.status === 'COMMENT_LOCKED') data.allowShare = false;
      if (dto.status === 'PUBLISHED') data.allowComment = true;
      if (dto.status === 'PUBLISHED') data.allowLike = true;
      if (dto.status === 'PUBLISHED') data.allowShare = true;
      if (dto.status === 'LIKE_DISABLED') data.allowLike = false;
      if (dto.status === 'SHARE_DISABLED') data.allowShare = false;
    }
    const updated = await this.prisma.poll.update({ where: { id }, data });
    await this.audit(
      actorId,
      'POLL_MODERATE',
      `POLL#${id}`,
      JSON.stringify(dto),
    );
    if (poll) {
      const locked = dto.status === 'COMMENT_LOCKED';
      const unlocked = dto.status === 'PUBLISHED';
      const deleted = dto.status === 'DELETED';
      const body =
        dto.result ??
        (locked
          ? '该投票已被禁止互动'
          : unlocked
            ? '该投票已解除禁止互动'
            : deleted
              ? '该投票已被删除'
              : '该投票状态已更新');
      await this.prisma.notification.create({
        data: {
          userId: poll.authorId,
          type: 'POLL_MODERATED',
          title: locked
            ? '投票已禁止互动'
            : unlocked
              ? '投票已恢复互动'
              : deleted
                ? '投票已删除'
                : '投票状态已更新',
          body: `“${poll.title}”：${body}`,
          targetType: 'POLL',
          targetId: poll.id,
        },
      });
      if (actorId !== poll.authorId) {
        await this.prisma.notification.create({
          data: {
            userId: actorId,
            type: 'POLL_MODERATION_DONE',
            title: '管理操作已完成',
            body: `“${poll.title}”：${body}`,
            targetType: 'POLL',
            targetId: poll.id,
          },
        });
      }
    }
    return updated;
  }

  comments() {
    return this.prisma.comment.findMany({
      orderBy: { createdAt: 'desc' },
      include: { author: { select: { uid: true, nickname: true } } },
      take: 50,
    });
  }

  async moderateComment(id: number, actorId: number, dto: ModerationDto) {
    const comment = await this.prisma.comment.findUnique({
      where: { id },
      include: { poll: { select: { title: true } } },
    });
    const updated = await this.prisma.comment.update({
      where: { id },
      data:
        dto.status === 'FOLDED'
          ? { isFolded: true }
          : { deletedAt: new Date() },
    });
    await this.audit(
      actorId,
      'COMMENT_MODERATE',
      `COMMENT#${id}`,
      JSON.stringify(dto),
    );
    if (comment) {
      const deleted = dto.status !== 'FOLDED';
      await this.prisma.notification.create({
        data: {
          userId: comment.authorId,
          type: 'COMMENT_MODERATED',
          title: deleted ? '评论已删除' : '评论已折叠',
          body: `你在“${comment.poll.title}”下的评论已被处理`,
          targetType: 'COMMENT',
          targetId: comment.id,
        },
      });
      if (actorId !== comment.authorId) {
        await this.prisma.notification.create({
          data: {
            userId: actorId,
            type: 'COMMENT_MODERATION_DONE',
            title: '评论处理完成',
            body: deleted ? '评论已删除' : '评论已折叠',
            targetType: 'COMMENT',
            targetId: comment.id,
          },
        });
      }
    }
    return updated;
  }

  roles() {
    return this.prisma.customRole.findMany({
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { users: true } } },
    });
  }

  createRole(actorId: number, dto: UpsertCustomRoleDto) {
    return this.prisma.customRole.upsert({
      where: { name: dto.name },
      update: {
        badge: dto.badge,
        badgeColor: dto.badgeColor,
        permissions: dto.permissions as never,
      },
      create: {
        name: dto.name,
        badge: dto.badge,
        badgeColor: dto.badgeColor,
        permissions: dto.permissions as never,
        createdById: actorId,
      },
    });
  }

  updateRole(id: number, dto: UpsertCustomRoleDto) {
    return this.prisma.customRole.update({
      where: { id },
      data: {
        name: dto.name,
        badge: dto.badge,
        badgeColor: dto.badgeColor,
        permissions: dto.permissions as never,
      },
    });
  }

  async deleteRole(id: number) {
    await this.prisma.user.updateMany({
      where: { customRoleId: id },
      data: { customRoleId: null, role: 'USER', badge: null },
    });
    return this.prisma.customRole.delete({ where: { id } });
  }

  ads() {
    return this.prisma.adPlacement.findMany({
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
  }

  createAd(dto: UpsertAdDto) {
    return this.prisma.adPlacement.upsert({
      where: { key: dto.key },
      update: dto,
      create: dto,
    });
  }

  updateAd(id: number, dto: UpsertAdDto) {
    return this.prisma.adPlacement.update({ where: { id }, data: dto });
  }

  async announcements() {
    await this.prisma.announcement.upsert({
      where: { key: 'startup' },
      update: {},
      create: {
        key: 'startup',
        title: '欢迎来到站队',
        body: '这里可以匿名表达，也可以把热门观点分享给朋友。',
        enabled: true,
        showEveryLaunch: false,
      },
    });
    await this.prisma.announcement.upsert({
      where: { key: 'marquee' },
      update: {},
      create: {
        key: 'marquee',
        title: '社区公告',
        body: '文明讨论，恶意刷票、攻击和违法内容会被处理。',
        enabled: true,
        showEveryLaunch: true,
      },
    });
    return this.prisma.announcement.findMany({
      orderBy: { updatedAt: 'desc' },
    });

    await this.prisma.announcement.upsert({
      where: { key: 'startup' },
      update: {},
      create: {
        key: 'startup',
        title: '欢迎来到站队',
        body: '这里可以匿名表达，也可以把热门观点分享给朋友。',
        enabled: true,
        showEveryLaunch: false,
      },
    });
    await this.prisma.announcement.upsert({
      where: { key: 'marquee' },
      update: {},
      create: {
        key: 'marquee',
        title: '社区公告',
        body: '文明讨论，恶意刷票和攻击内容会被处理。',
        enabled: true,
        showEveryLaunch: true,
      },
    });
    return this.prisma.announcement.findMany({
      orderBy: { updatedAt: 'desc' },
    });
  }

  upsertAnnouncement(dto: UpsertAnnouncementDto) {
    return this.prisma.announcement.upsert({
      where: { key: dto.key },
      update: dto,
      create: dto,
    });
  }

  updateConfig() {
    return this.prisma.appUpdateConfig.upsert({
      where: { platform: 'android' },
      update: {},
      create: {
        platform: 'android',
        latestVersion: '1.0.0',
        latestBuild: 1,
        minBuild: 1,
        forceUpdate: false,
        enabled: false,
        title: '发现新版本',
        releaseNotes: '优化体验与稳定性。',
        updateUrl: '',
      },
    });
  }

  saveUpdateConfig(dto: UpsertUpdateConfigDto) {
    const platform = dto.platform?.trim() || 'android';
    return this.prisma.appUpdateConfig.upsert({
      where: { platform },
      update: { ...dto, platform },
      create: { ...dto, platform },
    });
  }

  feedback() {
    return this.prisma.appFeedback.findMany({
      include: {
        user: {
          select: { id: true, uid: true, nickname: true, username: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }
}
