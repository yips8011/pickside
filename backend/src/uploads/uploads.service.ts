import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UploadsService {
  constructor(private readonly prisma: PrismaService) {}

  recordImage(
    ownerId: number,
    file: {
      filename: string;
      originalname: string;
      mimetype: string;
      size: number;
    },
  ) {
    const url = `/uploads/images/${file.filename}`;
    return this.prisma.appUpload.create({
      data: {
        ownerId,
        fileName: file.filename,
        originalName: file.originalname,
        mimeType: file.mimetype,
        size: file.size,
        url,
      },
    });
  }
}
