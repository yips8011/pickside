import { Injectable, NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

/**
 * 请求日志（Vercel Serverless 版）：serverless 无持久磁盘，改为 console.log，
 * 日志可在 Vercel 控制台（Functions → Logs）查看。
 */
@Injectable()
export class RequestLoggingMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const startedAt = Date.now();
    res.on('finish', () => {
      const durationMs = Date.now() - startedAt;
      const entry = {
        at: new Date().toISOString(),
        method: req.method,
        path: req.originalUrl,
        statusCode: res.statusCode,
        durationMs,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
      };
      console.log(JSON.stringify(entry));
      if (durationMs >= Number(process.env.SLOW_REQUEST_MS ?? 800)) {
        console.log(JSON.stringify({ slow: true, ...entry }));
      }
    });
    next();
  }
}
