import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ContentService } from './content.service';
import { SubmitFeedbackDto } from './dto';

@Controller('content')
export class ContentController {
  constructor(private readonly content: ContentService) {}

  @Get('ads')
  ads() {
    return this.content.ads();
  }

  @Get('announcements')
  announcements() {
    return this.content.announcements();
  }

  @Get('update')
  update(
    @Query('platform') platform = 'android',
    @Query('build') build?: string,
  ) {
    return this.content.update(platform, Number(build ?? 1));
  }

  @Post('feedback')
  @UseGuards(JwtAuthGuard)
  feedback(@CurrentUser() user: AuthUser, @Body() dto: SubmitFeedbackDto) {
    return this.content.feedback(user.id, dto);
  }
}
