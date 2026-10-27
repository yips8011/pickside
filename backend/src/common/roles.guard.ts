import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from './roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles =
      this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) ?? [];
    if (roles.length === 0) return true;

    const user = context.switchToHttp().getRequest().user;
    if (!user) {
      throw new ForbiddenException('Insufficient permissions');
    }
    if (roles.includes(user.role)) return true;

    const permissions = new Set<string>(user.customRole?.permissions ?? []);
    const rolePermissionMap: Record<string, string[]> = {
      REVIEWER: ['COMMENT_MODERATE', 'POLL_MODERATE', 'REPORT_MANAGE'],
      REPORT_HANDLER: ['REPORT_MANAGE'],
      AD_MANAGER: ['AD_MANAGE', 'ANNOUNCEMENT_MANAGE'],
      ADMIN: ['USER_BAN', 'USER_DELETE', 'POLL_MODERATE', 'COMMENT_MODERATE', 'REPORT_MANAGE', 'AD_MANAGE', 'ANNOUNCEMENT_MANAGE'],
      SUPER_ADMIN: ['ROLE_MANAGE'],
    };
    const allowedByCustomRole = roles.some((role) =>
      (rolePermissionMap[role] ?? []).some((permission) => permissions.has(permission)),
    );
    if (!allowedByCustomRole) {
      throw new ForbiddenException('Insufficient permissions');
    }
    return true;
  }
}
