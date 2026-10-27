import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
} from 'class-validator';

export class UpdateReportDto {
  @IsEnum(['RESOLVED', 'REJECTED'])
  status: 'RESOLVED' | 'REJECTED';

  @IsOptional()
  @IsString()
  result?: string;
}

export class UpdateUserStatusDto {
  @IsEnum(['ACTIVE', 'BANNED', 'DELETED'])
  status: 'ACTIVE' | 'BANNED' | 'DELETED';

  @IsOptional()
  @IsInt()
  @IsPositive()
  muteDays?: number;

  @IsOptional()
  @IsString()
  reason?: string;
}

export class ModerationDto {
  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  result?: string;
}

export class UpsertCustomRoleDto {
  @IsString()
  name: string;

  @IsString()
  badge: string;

  @IsOptional()
  @IsString()
  badgeColor?: string;

  @IsArray()
  @IsEnum(
    [
      'REPORT_MANAGE',
      'USER_BAN',
      'USER_DELETE',
      'POLL_MODERATE',
      'COMMENT_MODERATE',
      'AD_MANAGE',
      'ANNOUNCEMENT_MANAGE',
      'ROLE_MANAGE',
    ],
    { each: true },
  )
  permissions: string[];
}

export class AssignRoleDto {
  @IsOptional()
  @IsEnum([
    'GUEST',
    'USER',
    'REVIEWER',
    'REPORT_HANDLER',
    'AD_MANAGER',
    'ADMIN',
    'SUPER_ADMIN',
  ])
  role?:
    | 'GUEST'
    | 'USER'
    | 'REVIEWER'
    | 'REPORT_HANDLER'
    | 'AD_MANAGER'
    | 'ADMIN'
    | 'SUPER_ADMIN';

  @IsOptional()
  @IsInt()
  customRoleId?: number;

  @IsOptional()
  @IsString()
  badge?: string;
}

export class UpsertAdDto {
  @IsString()
  key: string;

  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsString()
  imageUrl?: string;

  @IsOptional()
  @IsString()
  linkUrl?: string;

  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsInt()
  sortOrder?: number;
}

export class UpsertAnnouncementDto {
  @IsString()
  key: string;

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @IsOptional()
  @IsBoolean()
  showEveryLaunch?: boolean;
}

export class UpsertUpdateConfigDto {
  @IsOptional()
  @IsString()
  platform?: string;

  @IsString()
  latestVersion: string;

  @IsInt()
  latestBuild: number;

  @IsInt()
  minBuild: number;

  @IsBoolean()
  forceUpdate: boolean;

  @IsBoolean()
  enabled: boolean;

  @IsString()
  title: string;

  @IsString()
  releaseNotes: string;

  @IsString()
  updateUrl: string;
}
