import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthUser } from '../common/current-user.decorator';
import { CreateCommentDto } from './dto';

const userSelect = {
  id: true,
  uid: true,
  username: true,
  nickname: true,
  avatarUrl: true,
  badge: true,
  role: true,
  customRole: true,
} as const;

const SENSITIVE_WORDS = ['违法', '诈骗', '色情', '赌博', '暴力', '人身攻击'];

function sensitiveHit(value: string) {
  const text = value.toLowerCase();
  return SENSITIVE_WORDS.find((word) => text.includes(word.toLowerCase()));
}

@Injectable()
export class CommentsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(pollId: number, viewer: AuthUser, page = 1, pageSize = 20) {
    const canRevealAnonymous = viewer.role === 'SUPER_ADMIN';
    const take = Math.min(Math.max(pageSize, 1), 50);
    const skip = (Math.max(page, 1) - 1) * take;
    const where = { pollId, deletedAt: null };
    const [comments, total] = await Promise.all([
      this.prisma.comment.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: { author: { select: userSelect } },
      }),
      this.prisma.comment.count({ where }),
    ]);
    const authorIds = comments.map((comment) => comment.authorId);
    const votes = await this.prisma.vote.findMany({
      where: { pollId, userId: { in: authorIds } },
      include: { option: { select: { id: true, text: true, color: true } } },
    });
    const viewerReactions = await this.prisma.commentReaction.findMany({
      where: { userId: viewer.id, commentId: { in: comments.map((comment) => comment.id) } },
    });
    const voteByUser = new Map(votes.map((vote) => [vote.userId, vote]));
    const reactionByComment = new Map(viewerReactions.map((item) => [item.commentId, item.reaction]));
    const items = comments.map((comment) => {
      const vote = voteByUser.get(comment.authorId);
      return {
        ...comment,
        revealedByAdmin: comment.isAnonymous && canRevealAnonymous,
        author: comment.isAnonymous && !canRevealAnonymous ? null : comment.author,
        canDelete: comment.authorId === viewer.id || canRevealAnonymous,
        stance: vote ? { optionId: vote.optionId, color: vote.option.color, text: vote.option.text } : null,
        myReaction: reactionByComment.get(comment.id) ?? null,
      };
    });
    return { items, total, page, pageSize: take };
  }

  async create(userId: number, pollId: number, dto: CreateCommentDto, parentId?: number) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { isMuted: true, mutedUntil: true, status: true },
    });
    if (!user || user.status !== 'ACTIVE') {
      throw new ForbiddenException('Account is not active');
    }
    if (
      user.isMuted &&
      (!user.mutedUntil || user.mutedUntil.getTime() > Date.now())
    ) {
      throw new ForbiddenException('User is muted');
    }
    if (
      user.isMuted &&
      user.mutedUntil &&
      user.mutedUntil.getTime() <= Date.now()
    ) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { isMuted: false, mutedUntil: null, mutedReason: null },
      });
    }
    const poll = await this.prisma.poll.findUnique({ where: { id: pollId } });
    if (!poll || poll.deletedAt) throw new NotFoundException('Poll not found');
    if (!poll.allowComment || poll.status === 'COMMENT_LOCKED') {
      throw new ForbiddenException('Comments disabled');
    }
    const parent = parentId ? await this.prisma.comment.findUnique({ where: { id: parentId } }) : null;
    return this.prisma.$transaction(async (tx) => {
      const hit = sensitiveHit(dto.content);
      const comment = await tx.comment.create({
        data: {
          pollId,
          authorId: userId,
          parentId,
          content: dto.content,
          isAnonymous: dto.isAnonymous ?? false,
          isFolded: Boolean(hit),
        },
        include: { author: { select: userSelect } },
      });
      await tx.poll.update({
        where: { id: pollId },
        data: { commentCount: { increment: 1 } },
      });
      await tx.notification.create({
        data: {
          userId,
          type: parentId ? 'REPLY_CREATED_SELF' : 'COMMENT_CREATED_SELF',
          title: parentId ? '回复发布成功' : '评论发布成功',
          body: `你参与了“${poll.title}”的讨论`,
          targetType: 'COMMENT',
          targetId: comment.id,
        },
      });
      if (poll.authorId !== userId) {
        await tx.notification.create({
          data: {
            userId: poll.authorId,
            type: 'POLL_COMMENTED',
            title: parentId ? '你的投票收到新回复' : '你的投票收到新评论',
            body: `“${poll.title}”有了新的讨论`,
            targetType: 'COMMENT',
            targetId: comment.id,
          },
        });
      }
      if (parent && parent.authorId !== userId && parent.authorId !== poll.authorId) {
        await tx.notification.create({
          data: {
            userId: parent.authorId,
            type: 'COMMENT_REPLIED',
            title: '你的评论收到回复',
            body: `有人回复了你在“${poll.title}”下的评论`,
            targetType: 'COMMENT',
            targetId: comment.id,
          },
        });
      }
      if (hit) {
        const reviewers = await tx.user.findMany({
          where: { role: { in: ['REVIEWER', 'ADMIN', 'SUPER_ADMIN'] } },
          select: { id: true },
        });
        if (reviewers.length > 0) {
          await tx.notification.createMany({
            data: reviewers.map((reviewer) => ({
              userId: reviewer.id,
              type: 'COMMENT_REVIEW_REQUIRED',
              title: '评论需要审核',
              body: `评论命中敏感词：${hit}`,
              targetType: 'COMMENT',
              targetId: comment.id,
            })),
          });
        }
      }
      return comment;
    });
  }

  async reply(userId: number, parentId: number, dto: CreateCommentDto) {
    const parent = await this.prisma.comment.findUnique({ where: { id: parentId } });
    if (!parent || parent.deletedAt) throw new NotFoundException('Comment not found');
    return this.create(userId, parent.pollId, dto, parentId);
  }

  async toggleReaction(userId: number, commentId: number, reaction: 'like' | 'dislike') {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment || comment.deletedAt) throw new NotFoundException('Comment not found');
    const nextReaction = reaction === 'like' ? 'LIKE' : 'DISLIKE';
    const existing = await this.prisma.commentReaction.findUnique({
      where: { userId_commentId: { userId, commentId } },
    });
    await this.prisma.$transaction(async (tx) => {
      if (!existing) {
        await tx.commentReaction.create({ data: { userId, commentId, reaction: nextReaction } });
      } else if (existing.reaction === nextReaction) {
        await tx.commentReaction.delete({ where: { id: existing.id } });
      } else {
        await tx.commentReaction.update({ where: { id: existing.id }, data: { reaction: nextReaction } });
      }
      const [likeCount, dislikeCount] = await Promise.all([
        tx.commentReaction.count({ where: { commentId, reaction: 'LIKE' } }),
        tx.commentReaction.count({ where: { commentId, reaction: 'DISLIKE' } }),
      ]);
      await tx.comment.update({ where: { id: commentId }, data: { likeCount, dislikeCount } });
      if (!existing && nextReaction === 'LIKE') {
        await tx.notification.create({
          data: { userId, type: 'COMMENT_LIKED_SELF', title: '点赞成功', body: '你点赞了一条评论', targetType: 'COMMENT', targetId: commentId },
        });
        if (comment.authorId !== userId) {
          await tx.notification.create({
            data: { userId: comment.authorId, type: 'COMMENT_LIKED', title: '你的评论被点赞', body: '有人点赞了你的评论', targetType: 'COMMENT', targetId: commentId },
          });
        }
      }
    });
    return this.prisma.comment.findUnique({ where: { id: commentId } });
  }

  async remove(userId: number, role: string, commentId: number) {
    const comment = await this.prisma.comment.findUnique({ where: { id: commentId } });
    if (!comment) throw new NotFoundException('Comment not found');
    const canModerate = ['ADMIN', 'SUPER_ADMIN', 'REVIEWER'].includes(role);
    if (comment.authorId !== userId && !canModerate) {
      throw new ForbiddenException('Cannot delete this comment');
    }
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.comment.update({
        where: { id: commentId },
        data: { deletedAt: new Date() },
      });
      await tx.poll.update({
        where: { id: comment.pollId },
        data: { commentCount: { decrement: 1 } },
      });
      return updated;
    });
  }
}
