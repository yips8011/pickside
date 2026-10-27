import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsOptional,
  IsString,
  Length,
  Matches,
} from 'class-validator';

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @Length(2, 8)
  nickname?: string;

  @IsOptional()
  @IsString()
  @Length(5, 24)
  @Matches(/^(?!\d+$)[A-Za-z0-9][A-Za-z0-9_]{4,23}$/)
  username?: string;

  @IsOptional()
  @IsString()
  @Length(0, 160)
  bio?: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;
}

export class UpdateSettingsDto {
  @IsOptional()
  @IsBoolean()
  darkMode?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyComments?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyLikes?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyFollows?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyReports?: boolean;

  @IsOptional()
  @IsBoolean()
  screenshotShareHint?: boolean;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  blockedKeywords?: string[];
}

export class UpsertDraftDto {
  @IsString()
  @Length(0, 100)
  title: string;

  @IsOptional()
  @IsString()
  @Length(0, 1000)
  description?: string;

  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(8)
  @IsString({ each: true })
  options: string[];

  @IsOptional()
  @IsBoolean()
  isAnonymous?: boolean;

  @IsOptional()
  @IsBoolean()
  allowAnonymousVote?: boolean;

  @IsOptional()
  @IsBoolean()
  allowAnonymousComment?: boolean;

  @IsOptional()
  @IsDateString()
  endAt?: string;

  @IsOptional()
  @IsString()
  @Length(0, 24)
  topicName?: string;

  @IsOptional()
  @IsString()
  @Length(0, 32)
  templateKey?: string;
}
