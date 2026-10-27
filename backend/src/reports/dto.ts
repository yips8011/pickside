import { IsEnum, IsInt, IsOptional, IsString, Length } from 'class-validator';

export class CreateReportDto {
  @IsEnum(['POLL', 'COMMENT', 'USER'])
  targetType: 'POLL' | 'COMMENT' | 'USER';

  @IsInt()
  targetId: number;

  @IsEnum(['SPAM', 'ILLEGAL', 'HARASSMENT', 'PORNOGRAPHIC', 'OTHER'])
  reason: 'SPAM' | 'ILLEGAL' | 'HARASSMENT' | 'PORNOGRAPHIC' | 'OTHER';

  @IsOptional()
  @IsString()
  @Length(0, 500)
  detail?: string;
}
