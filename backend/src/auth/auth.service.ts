import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto, LoginDto, RegisterDto } from './dto';

/**
 * 安全的 expiresIn 解析：环境变量可能被设成非法值（如纯数字/带空格/乱写），
 * 这里校验后兜底；纯数字按"秒"处理，合法 timespan 字符串原样返回，否则用默认值。
 */
function safeExpiresIn(
  value: string | undefined,
  fallback: string,
): string | number {
  const v = (value ?? fallback).trim();
  if (/^\d+$/.test(v)) return Number(v);
  if (/^\d+(ms|s|m|h|d|w|y)$/i.test(v)) return v;
  return fallback;
}

@Injectable()
export class AuthService {
  private readonly defaultAvatars = [
    'default:aurora',
    'default:mint',
    'default:sunset',
    'default:ocean',
    'default:peach',
    'default:violet',
    'default:forest',
    'default:sky',
  ];

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const passwordHash = await bcrypt.hash(dto.password, 12);
    const latestUser = await this.prisma.user.findFirst({
      orderBy: { uid: 'desc' },
      select: { uid: true },
    });
    let user;
    try {
      user = await this.prisma.user.create({
        data: {
          uid: Math.max(latestUser?.uid ?? 100000, 100000) + 1,
          username: dto.username,
          passwordHash,
          nickname: dto.nickname,
          avatarUrl: this.defaultAvatars[Math.floor(Math.random() * this.defaultAvatars.length)],
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new BadRequestException('账号已被占用，请换一个账号');
      }
      throw error;
    }
    return this.issueTokens(user.id);
  }

  async login(dto: LoginDto) {
    const login = dto.username.trim();
    const uid = /^\d+$/.test(login) ? Number(login) : null;
    const user = await this.prisma.user.findFirst({
      where: uid == null ? { username: login } : { OR: [{ uid }, { username: login }] },
    });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      this.writeSecurityLog('login_failed', { login });
      throw new UnauthorizedException('\u8D26\u53F7\u6216\u5BC6\u7801\u9519\u8BEF');
    }
    if (user.status !== 'ACTIVE') {
      this.writeSecurityLog('login_blocked', { userId: user.id, status: user.status });
      throw new UnauthorizedException('\u8D26\u53F7\u4E0D\u53EF\u7528\uFF0C\u8BF7\u8054\u7CFB\u7BA1\u7406\u5458');
    }
    this.writeSecurityLog('login_success', { userId: user.id });
    return this.issueTokens(user.id);
  }

  async refresh(refreshToken: string) {
    const payload = await this.jwt
      .verifyAsync<{ sub: number }>(refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET') ?? 'dev-refresh',
      })
      .catch(() => null);
    if (!payload) throw new UnauthorizedException('Invalid refresh token');

    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user?.refreshHash || !(await bcrypt.compare(refreshToken, user.refreshHash))) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    return this.issueTokens(user.id);
  }

  async logout(userId: number) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { refreshHash: null },
    });
    return { ok: true };
  }

  async changePassword(userId: number, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !(await bcrypt.compare(dto.oldPassword, user.passwordHash))) {
      throw new BadRequestException('\u65E7\u5BC6\u7801\u4E0D\u6B63\u786E');
    }
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: await bcrypt.hash(dto.newPassword, 12),
        refreshHash: null,
      },
    });
    return { ok: true };
  }

  private async issueTokens(userId: number) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: { id: true, uid: true, username: true, nickname: true, role: true },
    });
    const accessToken = await this.jwt.signAsync(
      { sub: user.id },
      {
        secret: this.config.get<string>('JWT_ACCESS_SECRET') ?? 'dev-access',
        expiresIn: safeExpiresIn(
          this.config.get<string>('JWT_ACCESS_EXPIRES_IN'),
          '15m',
        ) as never,
      },
    );
    const refreshToken = await this.jwt.signAsync(
      { sub: user.id },
      {
        secret: this.config.get<string>('JWT_REFRESH_SECRET') ?? 'dev-refresh',
        expiresIn: safeExpiresIn(
          this.config.get<string>('JWT_REFRESH_EXPIRES_IN'),
          '7d',
        ) as never,
      },
    );
    await this.prisma.user.update({
      where: { id: user.id },
      data: { refreshHash: await bcrypt.hash(refreshToken, 12) },
    });
    return { user, accessToken, refreshToken };
  }

  private writeSecurityLog(event: string, payload: Record<string, unknown>) {
    // Vercel Serverless 版：无持久磁盘，改 console.log（Vercel 控制台可查）
    console.log(JSON.stringify({ at: new Date().toISOString(), event, ...payload }));
  }
}
