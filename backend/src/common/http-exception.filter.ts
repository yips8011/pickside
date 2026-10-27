import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    // 非 HTTP 异常（500 等）打印堆栈，方便 Vercel 日志排查
    if (!(exception instanceof HttpException)) {
      console.error('[unhandled]', exception);
    }
    const response = host.switchToHttp().getResponse<Response>();
    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    let message: unknown =
      exception instanceof HttpException
        ? exception.message
        : 'Internal server error';
    if (exception instanceof HttpException) {
      const detail = exception.getResponse();
      if (typeof detail === 'object' && detail !== null && 'message' in detail) {
        message = (detail as { message?: unknown }).message ?? message;
      }
    }

    response.status(status).json({
      success: false,
      error: { statusCode: status, message },
      timestamp: new Date().toISOString(),
    });
  }
}
