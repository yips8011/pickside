import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMeDto, UpdateSettingsDto, UpsertDraftDto } from './dto';

@Injectable()
export class UsersService {
  private readonly defaultAvatars = [
    'default:aurora',
    'default:mint',
    'default:sunset',
    'default:ocean',
    'default:peach',
    'default:violet',
    'default:forest',
    'default:sky',
  ];

  constructor(private readonly prisma: PrismaService) {}

  private randomDefaultAvatar() {
    return this.defaultAvatars[Math.floor(Math.random() * this.defaultAvatars.length)];
  }

  async me(id: number) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        uid: true,
        username: true,
        nickname: true,
        avatarUrl: true,
        bio: true,
        badge: true,
        role: true,
        isMuted: true,
        mutedUntil: true,
        mutedReason: true,
        pollCount: true,
        receivedLikes: true,
        followingCount: true,
        followerCount: true,
        customRole: true,
        createdAt: true,
      },
    });
    if (user && !user.avatarUrl) {
      const avatarUrl = this.randomDefaultAvatar();
      await this.prisma.user.update({ where: { id }, data: { avatarUrl } });
      return { ...user, avatarUrl };
    }
    return user;
  }

  updateMe(id: number, dto: UpdateMeDto) {
    return this.prisma.user.update({ where: { id }, data: dto });
  }

  async profile(uid: number) {
    const user = await this.prisma.user.findUnique({
      where: { uid },
      select: {
        id: true,
        uid: true,
        username: true,
        nickname: true,
        avatarUrl: true,
        bio: true,
        badge: true,
        role: true,
        customRole: true,
        isMuted: true,
        mutedUntil: true,
        mutedReason: true,
        pollCount: true,
        receivedLikes: true,
        followingCount: true,
        followerCount: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    if (!user.avatarUrl) {
      const avatarUrl = this.randomDefaultAvatar();
      await this.prisma.user.update({ where: { id: user.id }, data: { avatarUrl } });
      return { ...user, avatarUrl };
    }
    return user;
  }

  async userPolls(uid: number) {
    const user = await this.prisma.user.findUnique({ where: { uid } });
    if (!user) throw new NotFoundException('User not found');
    return this.prisma.poll.findMany({
      where: { authorId: user.id, deletedAt: null, isAnonymous: false },
      include: {
        author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
        options: { orderBy: { sortOrder: 'asc' } },
        comments: {
          where: { deletedAt: null },
          take: 20,
          orderBy: { createdAt: 'desc' },
          include: { author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  votedPolls(id: number) {
    return this.prisma.vote.findMany({
      where: { userId: id },
      include: {
        poll: {
          include: {
            author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
            options: { orderBy: { sortOrder: 'asc' } },
            comments: {
              where: { deletedAt: null },
              take: 20,
              orderBy: { createdAt: 'desc' },
              include: { author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } } },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  favorites(id: number) {
    return this.prisma.favorite.findMany({
      where: { userId: id, poll: { deletedAt: null } },
      include: {
        poll: {
          include: {
            author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
            options: { orderBy: { sortOrder: 'asc' } },
            comments: {
              where: { deletedAt: null },
              take: 20,
              orderBy: { createdAt: 'desc' },
              include: { author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } } },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  votedPollsOnly(id: number) {
    return this.prisma.vote.findMany({
      where: { userId: id, poll: { deletedAt: null } },
      include: {
        poll: {
          include: {
            author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
            options: { orderBy: { sortOrder: 'asc' } },
            comments: {
              where: { deletedAt: null },
              take: 20,
              orderBy: { createdAt: 'desc' },
              include: { author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } } },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  likedPolls(id: number) {
    return this.prisma.like.findMany({
      where: { userId: id, targetType: 'POLL' },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  async likedPollDetails(id: number) {
    const likes = await this.likedPolls(id);
    const ids = likes.map((like) => like.targetId);
    if (ids.length === 0) return [];
    return this.prisma.poll.findMany({
      where: { id: { in: ids }, deletedAt: null },
      include: {
        author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
        options: { orderBy: { sortOrder: 'asc' } },
        comments: {
          where: { deletedAt: null },
          take: 20,
          orderBy: { createdAt: 'desc' },
          include: { author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } } },
        },
      },
    });
  }

  async stats(id: number) {
    const [user, likedCount, votedCount, favoriteCount, authoredPolls] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id },
        select: {
          pollCount: true,
          followingCount: true,
          followerCount: true,
          receivedLikes: true,
        },
      }),
      this.prisma.like.count({ where: { userId: id, targetType: 'POLL' } }),
      this.prisma.vote.count({ where: { userId: id } }),
      this.prisma.favorite.count({ where: { userId: id } }),
      this.prisma.poll.findMany({
        where: { authorId: id, deletedAt: null },
        select: { id: true, likeCount: true },
      }),
    ]);
    const receivedLikes = authoredPolls.reduce(
      (total, poll) => total + poll.likeCount,
      0,
    );
    return { ...user, receivedLikes, likedCount, votedCount, favoriteCount };
  }

  following(id: number) {
    return this.prisma.follow.findMany({
      where: { followerId: id },
      include: { following: { select: { id: true, uid: true, nickname: true, avatarUrl: true, bio: true, badge: true, role: true, customRole: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  followers(id: number) {
    return this.prisma.follow.findMany({
      where: { followingId: id },
      include: { follower: { select: { id: true, uid: true, nickname: true, avatarUrl: true, bio: true, badge: true, role: true, customRole: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async follow(followerId: number, uid: number, enabled: boolean) {
    const target = await this.prisma.user.findUnique({ where: { uid } });
    if (!target) throw new NotFoundException('User not found');
    if (target.id === followerId) throw new BadRequestException('Cannot follow self');
    await this.prisma.$transaction(async (tx) => {
      if (enabled) {
        const existing = await tx.follow.findUnique({
          where: { followerId_followingId: { followerId, followingId: target.id } },
        });
        if (!existing) {
          await tx.follow.create({ data: { followerId, followingId: target.id } });
          await tx.user.update({ where: { id: followerId }, data: { followingCount: { increment: 1 } } });
          await tx.user.update({ where: { id: target.id }, data: { followerCount: { increment: 1 } } });
          await tx.notification.create({
            data: {
              userId: target.id,
              type: 'FOLLOW',
              title: '有人关注了你',
              body: '你收到了新的关注',
              targetType: 'USER',
              targetId: followerId,
            },
          });
        }
      } else {
        const removed = await tx.follow.deleteMany({
          where: { followerId, followingId: target.id },
        });
        if (removed.count > 0) {
          await tx.user.update({ where: { id: followerId }, data: { followingCount: { decrement: 1 } } });
          await tx.user.update({ where: { id: target.id }, data: { followerCount: { decrement: 1 } } });
        }
      }
    });
    return { ok: true };
  }

  blocks(id: number) {
    return this.prisma.block.findMany({
      where: { blockerId: id },
      include: { blocked: { select: { id: true, uid: true, nickname: true, avatarUrl: true, bio: true, badge: true, role: true, customRole: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async block(blockerId: number, uid: number, enabled: boolean) {
    const target = await this.prisma.user.findUnique({ where: { uid } });
    if (!target) throw new NotFoundException('User not found');
    if (target.id === blockerId) throw new BadRequestException('Cannot block self');
    if (enabled) {
      await this.prisma.block.upsert({
        where: { blockerId_blockedId: { blockerId, blockedId: target.id } },
        update: {},
        create: { blockerId, blockedId: target.id },
      });
    } else {
      await this.prisma.block.deleteMany({
        where: { blockerId, blockedId: target.id },
      });
    }
    return { ok: true };
  }

  settings(id: number) {
    return this.prisma.userSetting.upsert({
      where: { userId: id },
      update: {},
      create: { userId: id },
    });
  }

  updateSettings(id: number, dto: UpdateSettingsDto) {
    return this.prisma.userSetting.upsert({
      where: { userId: id },
      update: dto,
      create: { userId: id, ...dto },
    });
  }

  drafts(id: number) {
    return this.prisma.pollDraft.findMany({
      where: { userId: id },
      orderBy: { updatedAt: 'desc' },
      take: 20,
    });
  }

  createDraft(id: number, dto: UpsertDraftDto) {
    return this.prisma.pollDraft.create({
      data: {
        userId: id,
        title: dto.title,
        description: dto.description,
        options: dto.options,
        isAnonymous: dto.isAnonymous ?? false,
        allowAnonymousVote: dto.allowAnonymousVote ?? false,
        allowAnonymousComment: dto.allowAnonymousComment ?? false,
        endAt: dto.endAt ? new Date(dto.endAt) : undefined,
        topicName: dto.topicName,
        templateKey: dto.templateKey,
      },
    });
  }

  updateDraft(userId: number, id: number, dto: UpsertDraftDto) {
    return this.prisma.pollDraft.updateMany({
      where: { id, userId },
      data: {
        title: dto.title,
        description: dto.description,
        options: dto.options,
        isAnonymous: dto.isAnonymous ?? false,
        allowAnonymousVote: dto.allowAnonymousVote ?? false,
        allowAnonymousComment: dto.allowAnonymousComment ?? false,
        endAt: dto.endAt ? new Date(dto.endAt) : null,
        topicName: dto.topicName,
        templateKey: dto.templateKey,
      },
    });
  }

  deleteDraft(userId: number, id: number) {
    return this.prisma.pollDraft.deleteMany({ where: { id, userId } });
  }
}
