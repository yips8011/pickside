import { Controller, Get, Param, ParseIntPipe, Patch, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { PrismaService } from '../prisma/prisma.service';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@CurrentUser() user: AuthUser) {
    const items = await this.prisma.notification.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    const commentIds = items
      .filter((item) => item.targetType === 'COMMENT' && item.targetId)
      .map((item) => item.targetId)
      .filter((id): id is number => typeof id === 'number');
    if (commentIds.length === 0) return items;
    const comments = await this.prisma.comment.findMany({
      where: { id: { in: commentIds } },
      select: { id: true, pollId: true },
    });
    const pollByComment = new Map(
      comments.map((comment) => [comment.id, comment.pollId]),
    );
    return items.map((item) => ({
      ...item,
      targetPollId:
        item.targetType === 'COMMENT' && typeof item.targetId === 'number'
          ? pollByComment.get(item.targetId)
          : null,
    }));
  }

  @Patch('read-all')
  async readAll(@CurrentUser() user: AuthUser) {
    await this.prisma.notification.updateMany({
      where: { userId: user.id, isRead: false },
      data: { isRead: true },
    });
    return { ok: true };
  }

  @Patch(':id/read')
  async readOne(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    await this.prisma.notification.updateMany({
      where: { id, userId: user.id },
      data: { isRead: true },
    });
    return { ok: true };
  }
}
