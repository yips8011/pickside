import type { INestApplication } from '@nestjs/common';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import compression from 'compression';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { ApiResponseInterceptor } from './common/api-response.interceptor';
import { HttpExceptionFilter } from './common/http-exception.filter';

/**
 * Vercel Serverless 入口（原 main.ts 保留用于本地常驻运行）。
 * 冷启动时缓存 app 实例；每个请求由 Express 实例直接处理。
 */
let appPromise: Promise<INestApplication> | null = null;

async function bootstrap(): Promise<INestApplication> {
  if (!appPromise) {
    appPromise = NestFactory.create(AppModule).then(async (app) => {
      app.use(helmet());
      app.use(compression());
      app.enableCors({
        origin:
          process.env.CORS_ORIGIN?.split(',') ?? [
            'http://localhost:3000',
            'http://10.0.2.2:3000',
          ],
        credentials: true,
      });
      app.useGlobalPipes(
        new ValidationPipe({
          whitelist: true,
          transform: true,
          forbidNonWhitelisted: true,
        }),
      );
      app.useGlobalInterceptors(new ApiResponseInterceptor());
      app.useGlobalFilters(new HttpExceptionFilter());
      await app.init();
      return app;
    });
  }
  return appPromise;
}

/** Vercel Node handler：接收 (req, res)，转交 NestJS Express 实例 */
export default async function handler(req: unknown, res: unknown) {
  const app = await bootstrap();
  const instance = app.getHttpAdapter().getInstance();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return (instance as any)(req, res);
}
