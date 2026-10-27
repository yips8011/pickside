import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('should return API health metadata', () => {
      expect(appController.health()).toEqual({
        name: 'anonymous-polls-api',
        status: 'ok',
        version: '1.0.0',
      });
    });
  });
});
