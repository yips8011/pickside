import { BadRequestException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReportDto } from './dto';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(reporterId: number, dto: CreateReportDto) {
    const since = new Date(Date.now() - 10 * 60 * 1000);
    const recentCount = await this.prisma.report.count({
      where: { reporterId, createdAt: { gte: since } },
    });
    if (recentCount >= 5) {
      throw new HttpException('举报过于频繁，请稍后再试', HttpStatus.TOO_MANY_REQUESTS);
    }
    const existingPending = await this.prisma.report.findFirst({
      where: {
        reporterId,
        targetType: dto.targetType,
        targetId: dto.targetId,
        status: 'PENDING',
      },
    });
    if (existingPending) {
      throw new BadRequestException('你已经举报过该内容，正在处理中');
    }
    return this.prisma.$transaction(async (tx) => {
      const report = await tx.report.create({ data: { reporterId, ...dto } });
      await tx.notification.create({
        data: {
          userId: reporterId,
          type: 'REPORT_CREATED',
          title: '\u4E3E\u62A5\u5DF2\u63D0\u4EA4',
          body: '\u6211\u4EEC\u4F1A\u5C3D\u5FEB\u5BA1\u6838\u4F60\u63D0\u4EA4\u7684\u4E3E\u62A5',
          targetType: dto.targetType,
          targetId: dto.targetId,
        },
      });
      let targetLabel = `${dto.targetType}#${dto.targetId}`;
      if (dto.targetType === 'POLL') {
        const poll = await tx.poll.findUnique({ where: { id: dto.targetId }, select: { title: true } });
        targetLabel = poll?.title ? `\u6295\u7968\u300C${poll.title}\u300D` : '\u4E00\u6761\u6295\u7968';
      }
      if (dto.targetType === 'COMMENT') {
        const comment = await tx.comment.findUnique({
          where: { id: dto.targetId },
          select: { content: true, poll: { select: { title: true } } },
        });
        const preview = comment?.content?.slice(0, 18) || '\u4E00\u6761\u8BC4\u8BBA';
        targetLabel = `\u8BC4\u8BBA\u300C${preview}\u300D${comment?.poll?.title ? ` · \u6765\u81EA\u300C${comment.poll.title}\u300D` : ''}`;
      }
      // Fallback for unhandled target types (e.g. VOTE, STANCE)
      if (dto.targetType !== 'POLL' && dto.targetType !== 'COMMENT') {
        targetLabel = '一条内容';
      }
      const handlers = await tx.user.findMany({
        where: { role: { in: ['REPORT_HANDLER', 'REVIEWER', 'ADMIN', 'SUPER_ADMIN'] } },
        select: { id: true },
      });
      if (handlers.length > 0) {
        await tx.notification.createMany({
          data: handlers.map((handler) => ({
            userId: handler.id,
            type: 'REPORT_PENDING',
            title: '\u6536\u5230\u65B0\u7684\u4E3E\u62A5',
            body: `${targetLabel} \u7B49\u5F85\u5904\u7406`,
            targetType: dto.targetType,
            targetId: dto.targetId,
          })),
        });
      }
      const targetReportCount = await tx.report.count({
        where: {
          targetType: dto.targetType,
          targetId: dto.targetId,
          status: 'PENDING',
        },
      });
      if (dto.targetType === 'POLL' && targetReportCount >= 3) {
        const poll = await tx.poll.update({
          where: { id: dto.targetId },
          data: {
            status: 'PENDING_REVIEW',
            reviewReason: `累计 ${targetReportCount} 条举报，自动进入审核`,
          },
          select: { id: true, title: true, authorId: true },
        });
        await tx.user.update({
          where: { id: poll.authorId },
          data: { reputation: { decrement: 2 } },
        });
        if (handlers.length > 0) {
          await tx.notification.createMany({
            data: handlers.map((handler) => ({
              userId: handler.id,
              type: 'POLL_AUTO_REVIEW',
              title: '帖子已自动进入审核',
              body: `“${poll.title}”累计举报较多，请尽快处理`,
              targetType: 'POLL',
              targetId: poll.id,
            })),
          });
        }
      }
      return report;
    });
  }
}

