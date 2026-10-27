import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomBytes } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser } from '../common/current-user.decorator';
import { CreatePollDto, UpdatePollContentDto, VoteDto } from './dto';
import { topicSlug } from '../topics/topics.service';

const OPTION_COLORS = [
  '#5B8DEF',
  '#22C55E',
  '#F97316',
  '#EC4899',
  '#14B8A6',
  '#A855F7',
  '#EAB308',
  '#EF4444',
];

const SENSITIVE_WORDS = ['违法', '诈骗', '色情', '赌博', '暴力', '人身攻击'];

function sensitiveHit(...values: Array<string | undefined>) {
  const text = values.filter(Boolean).join(' ').toLowerCase();
  return SENSITIVE_WORDS.find((word) => text.includes(word.toLowerCase()));
}

@Injectable()
export class PollsService {
  constructor(private readonly prisma: PrismaService) {}

  private async createShareCode(tx: PrismaService | any) {
    for (let index = 0; index < 10; index += 1) {
      const code = `ZD-${randomBytes(5)
        .toString('base64url')
        .replace(/[^A-Z0-9]/gi, '')
        .toUpperCase()
        .slice(0, 8)}`;
      const exists = await tx.poll.findUnique({ where: { shareCode: code } });
      if (!exists) return code;
    }
    return `ZD-${Date.now().toString(36).toUpperCase()}${randomBytes(2)
      .toString('hex')
      .toUpperCase()}`;
  }

  async list(tab = 'recommended', page = 1, pageSize = 20, userId?: number) {
    const skip = (Math.max(page, 1) - 1) * Math.min(pageSize, 50);
    const take = Math.min(pageSize, 50);
    const where: Record<string, unknown> = {
      deletedAt: null,
      status: { not: 'DELETED' },
    };

    if (tab === 'following' && userId) {
      const follows = await this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { followingId: true },
      });
      where.authorId = { in: follows.map((follow) => follow.followingId) };
      where.isAnonymous = false;
    }

    if (userId) {
      const [setting, blocks] = await Promise.all([
        this.prisma.userSetting.findUnique({ where: { userId } }),
        this.prisma.block.findMany({
          where: { blockerId: userId },
          select: { blockedId: true },
        }),
      ]);
      if (blocks.length > 0) {
        where.authorId = {
          ...(where.authorId as Record<string, unknown> | undefined),
          notIn: blocks.map((block) => block.blockedId),
        };
      }
      const blocked = (setting?.blockedKeywords ?? [])
        .map((item) => item.trim())
        .filter(Boolean);
      if (blocked.length > 0) {
        where.NOT = blocked.flatMap((keyword) => [
          { title: { contains: keyword, mode: 'insensitive' } },
          { description: { contains: keyword, mode: 'insensitive' } },
        ]);
      }
    }

    const orderBy =
      tab === 'latest'
        ? [{ createdAt: 'desc' as const }]
        : tab === 'hot'
          ? [{ voteCount: 'desc' as const }, { commentCount: 'desc' as const }]
          : [{ createdAt: 'desc' as const }];

    const [items, total] = await Promise.all([
      this.prisma.poll.findMany({
        where,
        skip,
        take,
        orderBy,
        include: {
          author: {
            select: {
              id: true,
              uid: true,
              nickname: true,
              avatarUrl: true,
              badge: true,
              role: true,
              customRole: true,
            },
          },
          options: { orderBy: { sortOrder: 'asc' } },
          topic: true,
        },
      }),
      this.prisma.poll.count({ where }),
    ]);
    return {
      items: await this.withViewerState(items, userId),
      total,
      page,
      pageSize: take,
    };
  }

  private async withViewerState<T extends { id: number }>(
    items: T[],
    userId?: number,
  ) {
    if (!userId || items.length === 0) return items;
    const ids = items.map((item) => item.id);
    const [votes, likes, favorites, dislikes] = await Promise.all([
      this.prisma.vote.findMany({
        where: { userId, pollId: { in: ids } },
        select: { pollId: true, optionId: true },
      }),
      this.prisma.like.findMany({
        where: { userId, targetType: 'POLL', targetId: { in: ids } },
        select: { targetId: true },
      }),
      this.prisma.favorite.findMany({
        where: { userId, pollId: { in: ids } },
        select: { pollId: true },
      }),
      this.prisma.pollDislike.findMany({
        where: { userId, pollId: { in: ids } },
        select: { pollId: true },
      }),
    ]);
    const voteByPoll = new Map(
      votes.map((vote) => [vote.pollId, vote.optionId]),
    );
    const liked = new Set(likes.map((like) => like.targetId));
    const favorited = new Set(favorites.map((favorite) => favorite.pollId));
    const disliked = new Set(dislikes.map((dislike) => dislike.pollId));
    return items.map((item) => ({
      ...item,
      viewerState: {
        myOptionId: voteByPoll.get(item.id) ?? null,
        isLiked: liked.has(item.id),
        isFavorited: favorited.has(item.id),
        isDisliked: disliked.has(item.id),
      },
    }));
  }

  async create(authorId: number, dto: CreatePollDto) {
    const author = await this.prisma.user.findUnique({
      where: { id: authorId },
      select: { isMuted: true, mutedUntil: true, status: true },
    });
    if (!author || author.status !== 'ACTIVE') {
      throw new ForbiddenException('Account is not active');
    }
    if (
      author.isMuted &&
      (!author.mutedUntil || author.mutedUntil.getTime() > Date.now())
    ) {
      throw new ForbiddenException('User is muted');
    }
    if (
      author.isMuted &&
      author.mutedUntil &&
      author.mutedUntil.getTime() <= Date.now()
    ) {
      await this.prisma.user.update({
        where: { id: authorId },
        data: { isMuted: false, mutedUntil: null, mutedReason: null },
      });
    }
    const endAt = dto.endAt ? new Date(dto.endAt) : undefined;
    if (endAt && endAt.getTime() <= Date.now()) {
      throw new BadRequestException('End time must be in the future');
    }

    return this.prisma.$transaction(async (tx) => {
      const hit = sensitiveHit(dto.title, dto.description, ...dto.options);
      const topicNames = Array.from(
        new Set(
          [...(dto.topicNames ?? []), ...(dto.topicName ? [dto.topicName] : [])]
            .map((name) => name.trim().replace(/^#+/, ''))
            .filter(Boolean)
            .slice(0, 5),
        ),
      );
      const topic = topicNames[0]
        ? await tx.topic.upsert({
            where: { name: topicNames[0] },
            update: { heat: { increment: 1 }, pollCount: { increment: 1 } },
            create: {
              name: topicNames[0],
              slug: topicSlug(topicNames[0]) || `topic-${Date.now()}`,
              category: dto.templateKey,
              heat: 1,
              pollCount: 1,
            },
          })
        : null;
      for (const name of topicNames.slice(1)) {
        await tx.topic.upsert({
          where: { name },
          update: { heat: { increment: 1 }, pollCount: { increment: 1 } },
          create: {
            name,
            slug:
              topicSlug(name) ||
              `topic-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
            category: dto.templateKey,
            heat: 1,
            pollCount: 1,
          },
        });
      }
      const poll = await tx.poll.create({
        data: {
          shareCode: await this.createShareCode(tx),
          authorId,
          title: dto.title,
          description: dto.description,
          isAnonymous: dto.isAnonymous ?? false,
          allowAnonymousVote: dto.allowAnonymousVote ?? true,
          allowAnonymousComment: dto.allowAnonymousComment ?? true,
          allowComment: dto.allowComment ?? true,
          allowLike: dto.allowLike ?? true,
          allowShare: dto.allowShare ?? true,
          imageUrls: dto.imageUrls ?? [],
          endAt,
          status: hit ? 'PENDING_REVIEW' : 'PUBLISHED',
          reviewReason: hit ? `命中敏感词：${hit}` : undefined,
          topicId: topic?.id,
          options: {
            create: dto.options.map((text, index) => ({
              text,
              color: OPTION_COLORS[index],
              sortOrder: index,
            })),
          },
        },
        include: { options: true },
      });
      await tx.user.update({
        where: { id: authorId },
        data: { pollCount: { increment: 1 } },
      });
      await tx.notification.create({
        data: {
          userId: authorId,
          type: 'POLL_CREATED',
          title: '发布成功',
          body: `你的投票“${poll.title}”已发布`,
          targetType: 'POLL',
          targetId: poll.id,
        },
      });
      if (hit) {
        const reviewers = await tx.user.findMany({
          where: { role: { in: ['REVIEWER', 'ADMIN', 'SUPER_ADMIN'] } },
          select: { id: true },
        });
        if (reviewers.length > 0) {
          await tx.notification.createMany({
            data: reviewers.map((reviewer) => ({
              userId: reviewer.id,
              type: 'POLL_REVIEW_REQUIRED',
              title: '投票需要审核',
              body: `“${poll.title}”命中敏感词，等待审核`,
              targetType: 'POLL',
              targetId: poll.id,
            })),
          });
        }
      }
      return poll;
    });
  }

  async detail(id: number, userId?: number) {
    const poll = await this.prisma.poll.update({
      where: { id },
      data: { viewCount: { increment: 1 } },
      include: {
        author: {
          select: {
            id: true,
            uid: true,
            nickname: true,
            avatarUrl: true,
            badge: true,
            role: true,
            customRole: true,
          },
        },
        options: { orderBy: { sortOrder: 'asc' } },
        topic: true,
      },
    });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    const [item] = await this.withViewerState([poll], userId);
    return item;
  }

  async summary(id: number) {
    const poll = await this.prisma.poll.findUnique({
      where: { id },
      include: { options: { orderBy: { voteCount: 'desc' } }, topic: true },
    });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    const total = poll.options.reduce(
      (sum, option) => sum + option.voteCount,
      0,
    );
    const top = poll.options[0] ?? null;
    const second = poll.options[1] ?? null;
    const topPercent =
      total && top ? Math.round((top.voteCount / total) * 100) : 0;
    const gap =
      top && second ? top.voteCount - second.voteCount : (top?.voteCount ?? 0);
    return {
      pollId: poll.id,
      title: poll.title,
      topic: poll.topic,
      totalVotes: total,
      commentCount: poll.commentCount,
      likeCount: poll.likeCount,
      topOption: top
        ? {
            id: top.id,
            text: top.text,
            voteCount: top.voteCount,
            percent: topPercent,
            color: top.color,
          }
        : null,
      gap,
      ended: poll.endAt ? poll.endAt.getTime() <= Date.now() : false,
      summaryText: top
        ? `当前最多用户选择“${top.text}”，占比约 ${topPercent}%，领先第二名 ${gap} 票。`
        : '暂无投票结果。',
    };
  }

  async requestEdit(userId: number, pollId: number) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (poll.authorId !== userId)
      throw new ForbiddenException('Only the author can request editing');
    if (poll.editApproved) return poll;
    const updated = await this.prisma.poll.update({
      where: { id: pollId },
      data: { editRequested: true },
    });
    const reviewers = await this.prisma.user.findMany({
      where: { role: { in: ['REVIEWER', 'ADMIN', 'SUPER_ADMIN'] } },
      select: { id: true },
    });
    if (reviewers.length > 0) {
      await this.prisma.notification.createMany({
        data: reviewers.map((reviewer) => ({
          userId: reviewer.id,
          type: 'POLL_EDIT_REQUESTED',
          title: '收到帖子编辑申请',
          body: `“${poll.title}”的发布者申请恢复编辑`,
          targetType: 'POLL',
          targetId: poll.id,
        })),
      });
    }
    await this.prisma.notification.create({
      data: {
        userId,
        type: 'POLL_EDIT_REQUEST_SUBMITTED',
        title: '编辑申请已提交',
        body: `“${poll.title}”将在审核通过后开放编辑`,
        targetType: 'POLL',
        targetId: poll.id,
      },
    });
    return updated;
  }

  async approveEdit(actor: AuthUser, pollId: number) {
    if (!['REVIEWER', 'ADMIN', 'SUPER_ADMIN'].includes(actor.role)) {
      throw new ForbiddenException('No review permission');
    }
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    const updated = await this.prisma.poll.update({
      where: { id: pollId },
      data: { editRequested: false, editApproved: true },
    });
    await this.prisma.notification.create({
      data: {
        userId: poll.authorId,
        type: 'POLL_EDIT_APPROVED',
        title: '编辑申请已通过',
        body: `“${poll.title}”现在可以编辑标题和描述，选项不可编辑`,
        targetType: 'POLL',
        targetId: poll.id,
      },
    });
    return updated;
  }

  async updateContent(
    userId: number,
    pollId: number,
    dto: UpdatePollContentDto,
  ) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (poll.authorId !== userId)
      throw new ForbiddenException('Only the author can edit this poll');
    if (!poll.editApproved)
      throw new ForbiddenException('Edit request is not approved');
    const updated = await this.prisma.poll.update({
      where: { id: pollId },
      data: {
        title: dto.title.trim(),
        description: dto.description?.trim() ?? '',
        editApproved: false,
        editRequested: false,
      },
      include: {
        author: {
          select: {
            id: true,
            uid: true,
            nickname: true,
            avatarUrl: true,
            badge: true,
            role: true,
            customRole: true,
          },
        },
        options: { orderBy: { sortOrder: 'asc' } },
        topic: true,
      },
    });
    await this.prisma.notification.create({
      data: {
        userId,
        type: 'POLL_EDITED',
        title: '帖子已更新',
        body: `“${updated.title}”的标题和描述已保存`,
        targetType: 'POLL',
        targetId: pollId,
      },
    });
    return updated;
  }

  async participants(pollId: number, viewer: AuthUser) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    const canRevealAnonymous = viewer.role === 'SUPER_ADMIN';
    const votes = await this.prisma.vote.findMany({
      where: { pollId },
      orderBy: { createdAt: 'desc' },
      include: {
        option: { select: { id: true, text: true, color: true } },
        user: {
          select: {
            id: true,
            uid: true,
            nickname: true,
            avatarUrl: true,
            badge: true,
            role: true,
            customRole: true,
          },
        },
      },
    });
    return votes.map((vote) => {
      const maskedAnonymous = poll.allowAnonymousVote || vote.isAnonymous;
      return {
        id: vote.id,
        pollId: vote.pollId,
        optionId: vote.optionId,
        option: vote.option,
        isAnonymous: maskedAnonymous,
        anonymousId: `\u533f\u540d#${String(vote.id).padStart(4, '0')}`,
        revealedByAdmin: maskedAnonymous && canRevealAnonymous,
        createdAt: vote.createdAt,
        user: maskedAnonymous && !canRevealAnonymous ? null : vote.user,
      };
    });
  }

  async vote(userId: number, pollId: number, dto: VoteDto) {
    const poll = await this.prisma.poll.findUnique({
      where: { id: pollId },
      include: { options: true },
    });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (poll.endAt && poll.endAt.getTime() <= Date.now()) {
      throw new ForbiddenException('Poll has ended');
    }
    if (!poll.options.some((option) => option.id === dto.optionId)) {
      throw new BadRequestException('Invalid option');
    }

    return this.prisma.$transaction(async (tx) => {
      const vote = await tx.vote.create({
        data: {
          userId,
          pollId,
          optionId: dto.optionId,
          isAnonymous: dto.isAnonymous ?? false,
        },
      });
      await tx.poll.update({
        where: { id: pollId },
        data: { voteCount: { increment: 1 } },
      });
      await tx.pollOption.update({
        where: { id: dto.optionId },
        data: { voteCount: { increment: 1 } },
      });
      await tx.notification.create({
        data: {
          userId,
          type: 'VOTE_CREATED',
          title: '投票成功',
          body: `你参与了“${poll.title}”`,
          targetType: 'POLL',
          targetId: pollId,
        },
      });
      if (poll.authorId !== userId) {
        await tx.notification.create({
          data: {
            userId: poll.authorId,
            type: 'POLL_VOTED',
            title: '有人参与了你的投票',
            body: `“${poll.title}”收到了一次新投票`,
            targetType: 'POLL',
            targetId: pollId,
          },
        });
      }
      return vote;
    });
  }

  async toggleLike(userId: number, pollId: number, enabled: boolean) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (!poll.allowLike) throw new ForbiddenException('Likes disabled');
    if (enabled) {
      const existing = await this.prisma.like.findUnique({
        where: {
          userId_targetType_targetId: {
            userId,
            targetType: 'POLL',
            targetId: pollId,
          },
        },
      });
      await this.prisma.$transaction([
        this.prisma.pollDislike.deleteMany({ where: { userId, pollId } }),
        this.prisma.like.upsert({
          where: {
            userId_targetType_targetId: {
              userId,
              targetType: 'POLL',
              targetId: pollId,
            },
          },
          update: {},
          create: { userId, targetType: 'POLL', targetId: pollId },
        }),
      ]);
      if (!existing) {
        if (poll.authorId !== userId) {
          await this.prisma.user.update({
            where: { id: poll.authorId },
            data: { receivedLikes: { increment: 1 } },
          });
        }
        await this.prisma.notification.create({
          data: {
            userId,
            type: 'POLL_LIKED_SELF',
            title: '点赞成功',
            body: `你点赞了“${poll.title}”`,
            targetType: 'POLL',
            targetId: pollId,
          },
        });
        if (poll.authorId !== userId) {
          await this.prisma.notification.create({
            data: {
              userId: poll.authorId,
              type: 'POLL_LIKED',
              title: '你的投票被点赞',
              body: `“${poll.title}”收到了一次点赞`,
              targetType: 'POLL',
              targetId: pollId,
            },
          });
        }
      }
    } else {
      const removed = await this.prisma.like.deleteMany({
        where: { userId, targetType: 'POLL', targetId: pollId },
      });
      if (removed.count > 0 && poll.authorId !== userId) {
        await this.prisma.user.update({
          where: { id: poll.authorId },
          data: { receivedLikes: { decrement: 1 } },
        });
      }
    }
    const likeCount = await this.prisma.like.count({
      where: { targetType: 'POLL', targetId: pollId },
    });
    const dislikeCount = await this.prisma.pollDislike.count({
      where: { pollId },
    });
    return this.prisma.poll.update({
      where: { id: pollId },
      data: { likeCount, dislikeCount },
    });
  }

  async toggleDislike(userId: number, pollId: number, enabled: boolean) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (!poll.allowLike) throw new ForbiddenException('Interactions disabled');
    if (enabled) {
      const existingLike = await this.prisma.like.findUnique({
        where: {
          userId_targetType_targetId: {
            userId,
            targetType: 'POLL',
            targetId: pollId,
          },
        },
      });
      await this.prisma.$transaction([
        this.prisma.like.deleteMany({
          where: { userId, targetType: 'POLL', targetId: pollId },
        }),
        this.prisma.pollDislike.upsert({
          where: { userId_pollId: { userId, pollId } },
          update: {},
          create: { userId, pollId },
        }),
      ]);
      if (existingLike && poll.authorId !== userId) {
        await this.prisma.user.update({
          where: { id: poll.authorId },
          data: { receivedLikes: { decrement: 1 } },
        });
      }
      await this.prisma.notification.create({
        data: {
          userId,
          type: 'POLL_DISLIKED_SELF',
          title: '反馈已记录',
          body: `你对「${poll.title}」表达了不感兴趣`,
          targetType: 'POLL',
          targetId: pollId,
        },
      });
    } else {
      await this.prisma.pollDislike.deleteMany({ where: { userId, pollId } });
    }
    const [likeCount, dislikeCount] = await Promise.all([
      this.prisma.like.count({
        where: { targetType: 'POLL', targetId: pollId },
      }),
      this.prisma.pollDislike.count({ where: { pollId } }),
    ]);
    return this.prisma.poll.update({
      where: { id: pollId },
      data: { likeCount, dislikeCount },
    });
  }

  async toggleFavorite(userId: number, pollId: number, enabled: boolean) {
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (enabled) {
      const existing = await this.prisma.favorite.findUnique({
        where: { userId_pollId: { userId, pollId } },
      });
      await this.prisma.favorite.upsert({
        where: { userId_pollId: { userId, pollId } },
        update: {},
        create: { userId, pollId },
      });
      if (!existing) {
        await this.prisma.notification.create({
          data: {
            userId,
            type: 'POLL_FAVORITED_SELF',
            title: '收藏成功',
            body: `你收藏了“${poll.title}”`,
            targetType: 'POLL',
            targetId: pollId,
          },
        });
        if (poll.authorId !== userId) {
          await this.prisma.notification.create({
            data: {
              userId: poll.authorId,
              type: 'POLL_FAVORITED',
              title: '你的投票被收藏',
              body: `“${poll.title}”收到了一次收藏`,
              targetType: 'POLL',
              targetId: pollId,
            },
          });
        }
      }
    } else {
      await this.prisma.favorite.deleteMany({ where: { userId, pollId } });
    }
    const favoriteCount = await this.prisma.favorite.count({
      where: { pollId },
    });
    return this.prisma.poll.update({
      where: { id: pollId },
      data: { favoriteCount },
    });
  }
}
