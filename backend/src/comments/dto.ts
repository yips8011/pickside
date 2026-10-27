import { IsBoolean, IsOptional, IsString, Length } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @Length(1, 500)
  content: string;

  @IsOptional()
  @IsBoolean()
  isAnonymous?: boolean;
}
