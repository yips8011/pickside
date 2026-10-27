import { Controller, Delete, Get, Param, ParseIntPipe, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { TopicsService } from './topics.service';

@UseGuards(JwtAuthGuard)
@Controller('topics')
export class TopicsController {
  constructor(private readonly topics: TopicsService) {}

  @Get()
  list(@CurrentUser() user: AuthUser, @Query('q') q?: string) {
    return this.topics.list(user.id, q);
  }

  @Get(':id/polls')
  polls(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.topics.polls(id, user.id, Number(page ?? 1), Number(pageSize ?? 20));
  }

  @Post(':id/follow')
  follow(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.topics.follow(user.id, id, true);
  }

  @Delete(':id/follow')
  unfollow(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.topics.follow(user.id, id, false);
  }
}
