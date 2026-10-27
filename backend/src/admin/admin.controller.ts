import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { AdminService } from './admin.service';
import {
  AssignRoleDto,
  ModerationDto,
  UpdateReportDto,
  UpdateUserStatusDto,
  UpsertAdDto,
  UpsertAnnouncementDto,
  UpsertCustomRoleDto,
  UpsertUpdateConfigDto,
} from './dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('REVIEWER', 'REPORT_HANDLER', 'AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('reports')
  reports() {
    return this.admin.reports();
  }

  @Get('audit-logs')
  @Roles('SUPER_ADMIN')
  auditLogs(
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.admin.auditLogs(Number(page ?? 1), Number(pageSize ?? 50));
  }

  @Patch('reports/:id')
  updateReport(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateReportDto,
  ) {
    return this.admin.updateReport(id, user.id, dto);
  }

  @Get('users')
  users(@Query('search') search?: string) {
    return this.admin.users(search);
  }

  @Patch('users/:id/status')
  updateUserStatus(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateUserStatusDto,
  ) {
    return this.admin.updateUserStatus(user.id, id, dto);
  }

  @Delete('users/:id')
  deleteUser(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.admin.deleteUser(user.id, id);
  }

  @Patch('users/:id/role')
  assignUserRole(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AssignRoleDto,
  ) {
    return this.admin.assignUserRole(user.id, id, dto);
  }

  @Get('polls')
  polls() {
    return this.admin.polls();
  }

  @Patch('polls/:id/moderation')
  moderatePoll(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ModerationDto,
  ) {
    return this.admin.moderatePoll(id, user.id, dto);
  }

  @Get('comments')
  comments() {
    return this.admin.comments();
  }

  @Patch('comments/:id/moderation')
  moderateComment(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ModerationDto,
  ) {
    return this.admin.moderateComment(id, user.id, dto);
  }

  @Get('roles')
  roles() {
    return this.admin.roles();
  }

  @Post('roles')
  @Roles('ADMIN', 'SUPER_ADMIN')
  createRole(@CurrentUser() user: AuthUser, @Body() dto: UpsertCustomRoleDto) {
    return this.admin.createRole(user.id, dto);
  }

  @Patch('roles/:id')
  @Roles('ADMIN', 'SUPER_ADMIN')
  updateRole(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpsertCustomRoleDto,
  ) {
    return this.admin.updateRole(id, dto);
  }

  @Delete('roles/:id')
  @Roles('SUPER_ADMIN')
  deleteRole(@Param('id', ParseIntPipe) id: number) {
    return this.admin.deleteRole(id);
  }

  @Get('ads')
  ads() {
    return this.admin.ads();
  }

  @Post('ads')
  @Roles('AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
  createAd(@Body() dto: UpsertAdDto) {
    return this.admin.createAd(dto);
  }

  @Patch('ads/:id')
  @Roles('AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
  updateAd(@Param('id', ParseIntPipe) id: number, @Body() dto: UpsertAdDto) {
    return this.admin.updateAd(id, dto);
  }

  @Get('announcements')
  announcements() {
    return this.admin.announcements();
  }

  @Post('announcements')
  @Roles('AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
  upsertAnnouncement(@Body() dto: UpsertAnnouncementDto) {
    return this.admin.upsertAnnouncement(dto);
  }

  @Get('update-config')
  @Roles('AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
  updateConfig() {
    return this.admin.updateConfig();
  }

  @Post('update-config')
  @Roles('AD_MANAGER', 'ADMIN', 'SUPER_ADMIN')
  saveUpdateConfig(@Body() dto: UpsertUpdateConfigDto) {
    return this.admin.saveUpdateConfig(dto);
  }

  @Get('feedback')
  @Roles('ADMIN', 'SUPER_ADMIN')
  feedback() {
    return this.admin.feedback();
  }
}
