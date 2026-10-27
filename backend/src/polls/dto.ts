import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  Length,
} from 'class-validator';

export class CreatePollDto {
  @IsString()
  @Length(1, 100)
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

  @IsBoolean()
  @IsOptional()
  isAnonymous?: boolean;

  @IsBoolean()
  @IsOptional()
  allowAnonymousVote?: boolean;

  @IsBoolean()
  @IsOptional()
  allowAnonymousComment?: boolean;

  @IsBoolean()
  @IsOptional()
  allowComment?: boolean;

  @IsBoolean()
  @IsOptional()
  allowLike?: boolean;

  @IsBoolean()
  @IsOptional()
  allowShare?: boolean;

  @IsOptional()
  @IsDateString()
  endAt?: string;

  @IsOptional()
  @IsString()
  @Length(1, 24)
  topicName?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsString({ each: true })
  topicNames?: string[];

  @IsOptional()
  @IsString()
  @Length(1, 32)
  templateKey?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(3)
  @IsString({ each: true })
  imageUrls?: string[];
}

export class VoteDto {
  @IsInt()
  optionId: number;

  @IsOptional()
  @IsBoolean()
  isAnonymous?: boolean;
}

export class UpdatePollContentDto {
  @IsString()
  @Length(1, 100)
  title: string;

  @IsOptional()
  @IsString()
  @Length(0, 1000)
  description?: string;
}
