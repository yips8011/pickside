import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  health() {
    return {
      name: 'anonymous-polls-api',
      status: 'ok',
      version: '1.0.0',
    };
  }
}
