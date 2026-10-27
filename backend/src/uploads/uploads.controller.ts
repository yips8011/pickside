import {
  BadRequestException,
  Controller,
  Get,
  Param,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { join } from 'node:path';
import { memoryStorage } from 'multer';
import { head, put } from '@vercel/blob';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { UploadsService } from './uploads.service';

const MAX_IMAGE_SIZE = 5 * 1024 * 1024;
const UPLOAD_ROOT = join(process.cwd(), 'uploads', 'images');

/**
 * 存储实现二选一（自动判断）：
 * - 配置了 BLOB_READ_WRITE_TOKEN → 存 Vercel Blob（Serverless 环境推荐）
 * - 未配置 → 存本地磁盘 uploads/images（传统服务器 / Docker）
 * 对外路径统一为 /uploads/images/:file，移动端无需感知差异。
 */
function useBlobStorage() {
  return Boolean(process.env.BLOB_READ_WRITE_TOKEN);
}

/** 魔数校验（与原后端一致：jpg/png/gif/webp） */
function isImageMagic(buffer: Buffer): boolean {
  if (!buffer || buffer.length < 8) return false;
  const header = buffer.subarray(0, 8).toString('hex').toLowerCase();
  const jpg = header.startsWith('ffd8');
  const png = header.startsWith('89504e47');
  const gif = header.startsWith('47494638');
  const webp = header.startsWith('52494646') && header.includes('57454250');
  return jpg || png || gif || webp;
}

@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @UseGuards(JwtAuthGuard)
  @Post('image')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_IMAGE_SIZE },
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.startsWith('image/')) {
          cb(new BadRequestException('Only image uploads are allowed'), false);
          return;
        }
        cb(null, true);
      },
    }),
  )
  async uploadImage(
    @CurrentUser() user: AuthUser,
    @UploadedFile()
    file?: {
      originalname: string;
      mimetype: string;
      size: number;
      buffer: Buffer;
    },
  ) {
    if (!file) throw new BadRequestException('Image file is required');
    if (!isImageMagic(file.buffer)) {
      throw new BadRequestException('Invalid image format');
    }

    const safeExt = file.originalname.split('.').pop()?.toLowerCase() ?? 'jpg';
    const filename = `${Date.now()}-${randomUUID()}.${safeExt}`;

    if (useBlobStorage()) {
      await put(`uploads/images/${filename}`, file.buffer, {
        access: 'public',
        contentType: file.mimetype,
      });
    } else {
      if (!existsSync(UPLOAD_ROOT)) mkdirSync(UPLOAD_ROOT, { recursive: true });
      writeFileSync(join(UPLOAD_ROOT, filename), file.buffer);
    }

    return this.uploads.recordImage(user.id, {
      filename,
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
    });
  }

  @Get('images/:file')
  async image(@Param('file') file: string, @Res() res: Response) {
    const safeFile = file.replace(/[^A-Za-z0-9._-]/g, '');
    if (safeFile !== file) throw new BadRequestException('Invalid filename');

    if (useBlobStorage()) {
      const blob = await head(`uploads/images/${safeFile}`);
      if (!blob) {
        res.status(404).json({
          success: false,
          error: { statusCode: 404, message: 'Image not found' },
          timestamp: new Date().toISOString(),
        });
        return;
      }
      const upstream = await fetch(blob.url);
      const buffer = Buffer.from(await upstream.arrayBuffer());
      res.setHeader(
        'Content-Type',
        blob.contentType ?? 'application/octet-stream',
      );
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      res.send(buffer);
      return;
    }

    const filePath = join(UPLOAD_ROOT, safeFile);
    if (!existsSync(filePath)) {
      res.status(404).json({
        success: false,
        error: { statusCode: 404, message: 'Image not found' },
        timestamp: new Date().toISOString(),
      });
      return;
    }
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.sendFile(filePath);
  }
}
