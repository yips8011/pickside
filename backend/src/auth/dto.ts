import { Matches, IsString, Length } from 'class-validator';

export class RegisterDto {
  @IsString({ message: '\u8BF7\u8F93\u5165\u8D26\u53F7' })
  @Length(5, 24, { message: '\u8D26\u53F7\u957F\u5EA6\u5FC5\u987B\u4E3A 5-24 \u4F4D' })
  @Matches(/^(?!\d+$)[A-Za-z0-9][A-Za-z0-9_]{4,23}$/, {
    message:
      '\u8D26\u53F7\u53EA\u80FD\u4F7F\u7528\u5B57\u6BCD\u3001\u6570\u5B57\u3001\u4E0B\u5212\u7EBF\uFF0C\u4E0D\u80FD\u662F\u7EAF\u6570\u5B57\uFF0C\u4E5F\u4E0D\u80FD\u4EE5\u7B26\u53F7\u5F00\u5934',
  })
  username: string;

  @IsString({ message: '\u8BF7\u8F93\u5165\u5BC6\u7801' })
  @Length(6, 64, { message: '\u5BC6\u7801\u957F\u5EA6\u81F3\u5C11 6 \u4F4D' })
  password: string;

  @IsString({ message: '\u8BF7\u8F93\u5165\u6635\u79F0' })
  @Length(2, 8, { message: '\u6635\u79F0\u5FC5\u987B\u4E3A 2-8 \u4E2A\u5B57' })
  nickname: string;
}

export class LoginDto {
  @IsString({ message: '\u8BF7\u8F93\u5165\u8D26\u53F7\u6216\u7528\u6237 ID' })
  @Length(1, 24, { message: '\u8BF7\u8F93\u5165\u8D26\u53F7\u6216\u7528\u6237 ID' })
  username: string;

  @IsString({ message: '\u8BF7\u8F93\u5165\u5BC6\u7801' })
  @Length(1, 64, { message: '\u8BF7\u8F93\u5165\u5BC6\u7801' })
  password: string;
}

export class RefreshDto {
  @IsString()
  refreshToken: string;
}

export class ChangePasswordDto {
  @IsString({ message: '\u8BF7\u8F93\u5165\u65E7\u5BC6\u7801' })
  @Length(1, 64, { message: '\u8BF7\u8F93\u5165\u65E7\u5BC6\u7801' })
  oldPassword: string;

  @IsString({ message: '\u8BF7\u8F93\u5165\u65B0\u5BC6\u7801' })
  @Length(6, 64, { message: '\u65B0\u5BC6\u7801\u957F\u5EA6\u81F3\u5C11 6 \u4F4D' })
  newPassword: string;
}
