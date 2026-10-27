import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SubmitFeedbackDto } from './dto';

@Injectable()
export class ContentService {
  constructor(private readonly prisma: PrismaService) {}

  async ads() {
    await this.ensureDefaultAds();
    return this.prisma.adPlacement.findMany({
      where: {
        enabled: true,
        imageUrl: { not: null },
        NOT: { imageUrl: '' },
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
    });
  }

  async announcements() {
    await this.ensureDefaultAnnouncements();
    return this.prisma.announcement.findMany({
      where: { enabled: true },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async update(platform = 'android', currentBuild = 1) {
    const config = await this.prisma.appUpdateConfig.upsert({
      where: { platform },
      update: {},
      create: {
        platform,
        latestVersion: '1.0.0',
        latestBuild: 1,
        minBuild: 1,
        forceUpdate: false,
        enabled: false,
        title: '发现新版本',
        releaseNotes: '优化体验与稳定性。',
        updateUrl: '',
      },
    });
    const hasUpdate = config.enabled && config.latestBuild > currentBuild;
    const forceUpdate =
      hasUpdate && (config.forceUpdate || config.minBuild > currentBuild);
    return {
      ...config,
      currentBuild,
      hasUpdate,
      forceUpdate,
    };
  }

  feedback(userId: number, dto: SubmitFeedbackDto) {
    return this.prisma.appFeedback.create({
      data: {
        userId,
        category: dto.category,
        content: dto.content,
        contact: dto.contact,
        includeLogs: dto.includeLogs,
        logs: dto.includeLogs ? dto.logs : null,
        appVersion: dto.appVersion,
        buildNumber: dto.buildNumber,
        platform: dto.platform ?? 'android',
      },
    });
  }

  private async ensureDefaultAds() {
    await this.prisma.adPlacement.upsert({
      where: { key: 'home_default' },
      update: {
        title: '站队社区',
        body: '匿名表达真实选择，看看大家站在哪一边。',
        imageUrl: 'https://picsum.photos/seed/vote-community/900/320',
        enabled: true,
        sortOrder: 1,
      },
      create: {
        key: 'home_default',
        title: '站队社区',
        body: '匿名表达真实选择，看看大家站在哪一边。',
        imageUrl: 'https://picsum.photos/seed/vote-community/900/320',
        enabled: true,
        sortOrder: 1,
      },
    });
    await this.prisma.adPlacement.upsert({
      where: { key: 'home_event' },
      update: {
        title: '新人话题',
        body: '发布你的第一条投票，收集第一批真实观点。',
        imageUrl: 'https://picsum.photos/seed/poll-event/900/320',
        enabled: true,
        sortOrder: 2,
      },
      create: {
        key: 'home_event',
        title: '新人话题',
        body: '发布你的第一条投票，收集第一批真实观点。',
        imageUrl: 'https://picsum.photos/seed/poll-event/900/320',
        enabled: true,
        sortOrder: 2,
      },
    });
  }

  private async ensureDefaultAnnouncements() {
    await this.prisma.announcement.upsert({
      where: { key: 'startup' },
      update: {
        title: '欢迎来到站队',
        body: '站队是观点投票社区，用于理性表达、了解分歧和收集选择，不鼓励也不允许刻意制造对立、焦虑、矛盾或违法违规争议话题。',
        enabled: true,
        showEveryLaunch: false,
      },
      create: {
        key: 'startup',
        title: '欢迎来到站队',
        body: '站队是观点投票社区，用于理性表达、了解分歧和收集选择，不鼓励也不允许刻意制造对立、焦虑、矛盾或违法违规争议话题。',
        enabled: true,
        showEveryLaunch: false,
      },
    });
    await this.prisma.announcement.upsert({
      where: { key: 'marquee' },
      update: {
        title: '社区公告',
        body: '文明讨论，恶意刷票、攻击和违法内容会被处理。',
        enabled: true,
        showEveryLaunch: true,
      },
      create: {
        key: 'marquee',
        title: '社区公告',
        body: '文明讨论，恶意刷票、攻击和违法内容会被处理。',
        enabled: true,
        showEveryLaunch: true,
      },
    });
  }
}
