import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const DEFAULT_TOPICS = [
  ['世界杯', '体育'],
  ['苹果vs安卓', '科技'],
  ['动漫角色', '娱乐'],
  ['AI工具', '科技'],
  ['校园生活', '校园'],
  ['恋爱观点', '情感'],
  ['汽车选择', '汽车'],
  ['游戏阵营', '游戏'],
] as const;

export function topicSlug(name: string) {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 64);
}

@Injectable()
export class TopicsService {
  constructor(private readonly prisma: PrismaService) {}

  async ensureDefaults() {
    for (const [name, category] of DEFAULT_TOPICS) {
      await this.prisma.topic.upsert({
        where: { name },
        update: {
          category,
          description: `${category}话题`,
        },
        create: {
          name,
          slug: topicSlug(name) || `topic-${Date.now()}`,
          category,
          description: `${category}话题`,
        },
      });
    }
  }

  async list(userId: number, q?: string) {
    await this.ensureDefaults();
    const where = q?.trim()
      ? { name: { contains: q.trim(), mode: 'insensitive' as const } }
      : {};
    const topics = await this.prisma.topic.findMany({
      where,
      orderBy: [{ heat: 'desc' }, { pollCount: 'desc' }, { updatedAt: 'desc' }],
      take: 50,
      include: { followers: { where: { userId }, select: { id: true } } },
    });
    return topics.map((topic) => ({
      ...topic,
      followed: topic.followers.length > 0,
      followers: undefined,
    }));
  }

  async polls(topicId: number, userId: number, page = 1, pageSize = 20) {
    const [setting, blocks] = await Promise.all([
      this.prisma.userSetting.findUnique({ where: { userId } }),
      this.prisma.block.findMany({
        where: { blockerId: userId },
        select: { blockedId: true },
      }),
    ]);
    const blocked = (setting?.blockedKeywords ?? [])
      .map((item) => item.trim())
      .filter(Boolean);
    const where = {
      topicId,
      deletedAt: null,
      status: { not: 'DELETED' as const },
      ...(blocks.length
        ? { authorId: { notIn: blocks.map((block) => block.blockedId) } }
        : {}),
      ...(blocked.length
        ? {
            NOT: blocked.flatMap((keyword) => [
              { title: { contains: keyword, mode: 'insensitive' as const } },
              {
                description: {
                  contains: keyword,
                  mode: 'insensitive' as const,
                },
              },
            ]),
          }
        : {}),
    };
    const take = Math.min(Math.max(pageSize, 1), 50);
    const skip = (Math.max(page, 1) - 1) * take;
    const [items, total] = await Promise.all([
      this.prisma.poll.findMany({
        where,
        skip,
        take,
        orderBy: [{ voteCount: 'desc' }, { createdAt: 'desc' }],
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
    return { items, total, page, pageSize: take };
  }

  async follow(userId: number, topicId: number, enabled: boolean) {
    if (enabled) {
      await this.prisma.topicFollow.upsert({
        where: { userId_topicId: { userId, topicId } },
        update: {},
        create: { userId, topicId },
      });
    } else {
      await this.prisma.topicFollow.deleteMany({ where: { userId, topicId } });
    }
    return { ok: true };
  }
}
