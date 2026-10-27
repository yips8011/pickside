import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtAuthGuard } from '../common/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('search')
export class SearchController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async search(@Query('q') q = '') {
    const query = q.trim();
    if (!query) return { polls: [], users: [] };
    const uid = Number(query);
    const normalizedCode = query.toUpperCase().replace(/\s+/g, '');
    const codeCandidates = Array.from(
      new Set([
        normalizedCode,
        normalizedCode.startsWith('ZD-')
          ? normalizedCode
          : normalizedCode.startsWith('ZD')
            ? `ZD-${normalizedCode.slice(2).replace(/^-/, '')}`
            : '',
      ]),
    ).filter(Boolean);
    const [polls, users] = await Promise.all([
      this.prisma.poll.findMany({
        where: {
          deletedAt: null,
          OR: [
            { title: { contains: query, mode: 'insensitive' } },
            { description: { contains: query, mode: 'insensitive' } },
            ...(codeCandidates.length > 0
              ? [{ shareCode: { in: codeCandidates } }]
              : []),
          ],
        },
        include: {
          author: { select: { id: true, uid: true, nickname: true, avatarUrl: true, badge: true, role: true, customRole: true } },
          options: true,
          comments: { where: { deletedAt: null }, take: 20, orderBy: { createdAt: 'desc' } },
          topic: true,
        },
        orderBy: [{ voteCount: 'desc' }, { createdAt: 'desc' }],
        take: 20,
      }),
      this.prisma.user.findMany({
        where: {
          OR: [
            { nickname: { contains: query, mode: 'insensitive' } },
            { username: { contains: query, mode: 'insensitive' } },
            ...(!Number.isNaN(uid) ? [{ uid }] : []),
          ],
        },
        select: { id: true, uid: true, username: true, nickname: true, avatarUrl: true, bio: true, badge: true, role: true, customRole: true, pollCount: true, receivedLikes: true, followingCount: true, followerCount: true },
        take: 20,
      }),
    ]);
    return { polls, users };
  }
}
