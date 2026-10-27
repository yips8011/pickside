import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { UpdateMeDto } from './dto';
import { UpdateSettingsDto, UpsertDraftDto } from './dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.users.me(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me')
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateMeDto) {
    return this.users.updateMe(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/voted-polls')
  voted(@CurrentUser() user: AuthUser) {
    return this.users.votedPollsOnly(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/favorites')
  favorites(@CurrentUser() user: AuthUser) {
    return this.users.favorites(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/liked-polls')
  liked(@CurrentUser() user: AuthUser) {
    return this.users.likedPollDetails(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/stats')
  stats(@CurrentUser() user: AuthUser) {
    return this.users.stats(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/following')
  following(@CurrentUser() user: AuthUser) {
    return this.users.following(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/followers')
  followers(@CurrentUser() user: AuthUser) {
    return this.users.followers(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/blocks')
  blocks(@CurrentUser() user: AuthUser) {
    return this.users.blocks(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/settings')
  settings(@CurrentUser() user: AuthUser) {
    return this.users.settings(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me/settings')
  updateSettings(@CurrentUser() user: AuthUser, @Body() dto: UpdateSettingsDto) {
    return this.users.updateSettings(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me/drafts')
  drafts(@CurrentUser() user: AuthUser) {
    return this.users.drafts(user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post('me/drafts')
  createDraft(@CurrentUser() user: AuthUser, @Body() dto: UpsertDraftDto) {
    return this.users.createDraft(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('me/drafts/:id')
  updateDraft(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpsertDraftDto,
  ) {
    return this.users.updateDraft(user.id, id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete('me/drafts/:id')
  deleteDraft(@CurrentUser() user: AuthUser, @Param('id', ParseIntPipe) id: number) {
    return this.users.deleteDraft(user.id, id);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':uid')
  profile(@Param('uid', ParseIntPipe) uid: number) {
    return this.users.profile(uid);
  }

  @UseGuards(JwtAuthGuard)
  @Get(':uid/polls')
  polls(@Param('uid', ParseIntPipe) uid: number) {
    return this.users.userPolls(uid);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':uid/follow')
  follow(@CurrentUser() user: AuthUser, @Param('uid', ParseIntPipe) uid: number) {
    return this.users.follow(user.id, uid, true);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':uid/follow')
  unfollow(@CurrentUser() user: AuthUser, @Param('uid', ParseIntPipe) uid: number) {
    return this.users.follow(user.id, uid, false);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':uid/block')
  block(@CurrentUser() user: AuthUser, @Param('uid', ParseIntPipe) uid: number) {
    return this.users.block(user.id, uid, true);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':uid/block')
  unblock(@CurrentUser() user: AuthUser, @Param('uid', ParseIntPipe) uid: number) {
    return this.users.block(user.id, uid, false);
  }
}
