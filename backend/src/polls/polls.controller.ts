import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { CreatePollDto, UpdatePollContentDto, VoteDto } from './dto';
import { PollsService } from './polls.service';

@Controller('polls')
export class PollsController {
  constructor(private readonly polls: PollsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  list(
    @CurrentUser() user: AuthUser,
    @Query('tab') tab = 'recommended',
    @Query('page') page = '1',
    @Query('pageSize') pageSize = '20',
  ) {
    return this.polls.list(tab, Number(page), Number(pageSize), user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreatePollDto) {
    return this.polls.create(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id/participants')
  participants(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.participants(id, user);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  detail(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.detail(id, user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id/summary')
  summary(@Param('id', ParseIntPipe) id: number) {
    return this.polls.summary(id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/edit-request')
  requestEdit(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.requestEdit(user.id, id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id/edit-approval')
  approveEdit(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.approveEdit(user, id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id/content')
  updateContent(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdatePollContentDto,
  ) {
    return this.polls.updateContent(user.id, id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/vote')
  vote(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: VoteDto,
  ) {
    return this.polls.vote(user.id, id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/like')
  like(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleLike(user.id, id, true);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id/like')
  unlike(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleLike(user.id, id, false);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/dislike')
  dislike(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleDislike(user.id, id, true);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id/dislike')
  undislike(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleDislike(user.id, id, false);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/favorite')
  favorite(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleFavorite(user.id, id, true);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id/favorite')
  unfavorite(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.polls.toggleFavorite(user.id, id, false);
  }
}
