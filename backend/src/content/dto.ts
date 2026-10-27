import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

export class SubmitFeedbackDto {
  @IsString()
  @Length(1, 32)
  category: string;

  @IsString()
  @Length(5, 2000)
  content: string;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  contact?: string;

  @IsBoolean()
  includeLogs: boolean;

  @IsOptional()
  @IsString()
  @Length(0, 8000)
  logs?: string;

  @IsOptional()
  @IsString()
  appVersion?: string;

  @IsOptional()
  @IsInt()
  buildNumber?: number;

  @IsOptional()
  @IsString()
  platform?: string;
}
