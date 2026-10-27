import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto';

@Controller()
export class CommentsController {
  constructor(private readonly comments: CommentsService) {}

  @UseGuards(JwtAuthGuard)
  @Get('polls/:id/comments')
  list(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) pollId: number,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.comments.list(pollId, user, Number(page ?? 1), Number(pageSize ?? 20));
  }

  @UseGuards(JwtAuthGuard)
  @Post('polls/:id/comments')
  create(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) pollId: number,
    @Body() dto: CreateCommentDto,
  ) {
    return this.comments.create(user.id, pollId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('comments/:id/replies')
  reply(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) parentId: number,
    @Body() dto: CreateCommentDto,
  ) {
    return this.comments.reply(user.id, parentId, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post('comments/:id/like')
  like(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.comments.toggleReaction(user.id, id, 'like');
  }

  @UseGuards(JwtAuthGuard)
  @Post('comments/:id/dislike')
  dislike(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.comments.toggleReaction(user.id, id, 'dislike');
  }

  @UseGuards(JwtAuthGuard)
  @Delete('comments/:id')
  remove(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.comments.remove(user.id, user.role, id);
  }
}
