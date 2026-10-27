part of 'main.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.36)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFFAFAFA)
                              : const Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFA1A1AA)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: dark ? const Color(0xFF27272A) : const Color(0xFFE8EDF5),
          ),
      ],
    );
  }
}

class AdminFeatureList extends StatelessWidget {
  const AdminFeatureList({
    required this.items,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final List<(String, String)> items;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) {
        if (index == 0 && actionLabel != null) {
          return FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel!),
          );
        }
        final itemIndex = actionLabel == null ? index : index - 1;
        final item = items[itemIndex];
        return SoftPanel(
          child: ListTile(
            leading: StatusPill(
              label: '${index + 1}',
              color: const Color(0xFF2563EB),
            ),
            title: Text(
              item.$1,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(item.$2),
            trailing: const Icon(Icons.tune_rounded),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemCount: items.length + (actionLabel == null ? 0 : 1),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.compact = false,
    super.key,
  });
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ActionPill extends StatelessWidget {
  const ActionPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF334155),
        backgroundColor: selected ? const Color(0xFF2563EB) : Colors.white,
        side: BorderSide(
          color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

String formatEndTime(DateTime? value) {
  if (value == null) return '闀挎湡';
  final now = DateTime.now();
  final diff = value.difference(now);
  if (diff.isNegative) return '宸茬粨鏉?;
  if (diff.inDays > 0) return '${diff.inDays}澶╁悗';
  if (diff.inHours > 0) return '${diff.inHours}灏忔椂鍚?;
  return '${diff.inMinutes.clamp(1, 59)}鍒嗛挓鍚?;
}

class _AvatarSpec {
  const _AvatarSpec(this.key, this.start, this.end, this.icon);
  final String key;
  final Color start;
  final Color end;
  final IconData icon;
}

const _builtInAvatarSpecs = [
  _AvatarSpec(
    'aurora',
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Icons.auto_awesome_rounded,
  ),
  _AvatarSpec('mint', Color(0xFF34D399), Color(0xFF22D3EE), Icons.spa_rounded),
  _AvatarSpec(
    'sunset',
    Color(0xFFFB7185),
    Color(0xFFF59E0B),
    Icons.wb_sunny_rounded,
  ),
  _AvatarSpec(
    'ocean',
    Color(0xFF38BDF8),
    Color(0xFF2563EB),
    Icons.water_drop_rounded,
  ),
  _AvatarSpec(
    'peach',
    Color(0xFFFDA4AF),
    Color(0xFFFB923C),
    Icons.favorite_rounded,
  ),
  _AvatarSpec(
    'violet',
    Color(0xFFC084FC),
    Color(0xFF7C3AED),
    Icons.bolt_rounded,
  ),
  _AvatarSpec(
    'forest',
    Color(0xFF4ADE80),
    Color(0xFF15803D),
    Icons.eco_rounded,
  ),
  _AvatarSpec('sky', Color(0xFF93C5FD), Color(0xFF06B6D4), Icons.cloud_rounded),
];

_AvatarSpec _avatarSpecFor(String? avatarUrl, String name) {
  final key = avatarUrl != null && avatarUrl.startsWith('default:')
      ? avatarUrl.substring('default:'.length)
      : null;
  if (key != null) {
    return _builtInAvatarSpecs.firstWhere(
      (item) => item.key == key,
      orElse: () => _builtInAvatarSpecs.first,
    );
  }
  final seed = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return _builtInAvatarSpecs[seed % _builtInAvatarSpecs.length];
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.avatarUrl,
    this.anonymous = false,
    this.size = 40,
    this.onTap,
    this.borderColor,
    super.key,
  });

  final String name;
  final String? avatarUrl;
  final bool anonymous;
  final double size;
  final VoidCallback? onTap;
  final Color? borderColor;

  bool get _isNetwork =>
      avatarUrl != null &&
      (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final spec = _avatarSpecFor(avatarUrl, name);
    final content = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: anonymous || !_isNetwork
            ? LinearGradient(
                colors: anonymous
                    ? const [Color(0xFFEDE9FE), Color(0xFFDCFCE7)]
                    : [spec.start, spec.end],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isNetwork ? const Color(0xFFEFF6FF) : null,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.78),
          width: size >= 40 ? 2 : 1.4,
        ),
      ),
      child: _isNetwork
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _BuiltInAvatarFace(
                spec: spec,
                name: name,
                anonymous: anonymous,
                size: size,
              ),
            )
          : _BuiltInAvatarFace(
              spec: spec,
              name: name,
              anonymous: anonymous,
              size: size,
            ),
    );
    if (onTap == null) return content;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: content,
    );
  }
}

class _BuiltInAvatarFace extends StatelessWidget {
  const _BuiltInAvatarFace({
    required this.spec,
    required this.name,
    required this.anonymous,
    required this.size,
  });
  final _AvatarSpec spec;
  final String name;
  final bool anonymous;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (anonymous) {
      return Center(
        child: Text(
          '鍖?,
          style: TextStyle(
            color: const Color(0xFF166534),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Icon(
          spec.icon,
          color: Colors.white.withValues(alpha: 0.34),
          size: size * 0.72,
        ),
        Center(
          child: Text(
            name.trim().isEmpty ? '?' : name.trim().characters.first,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class UserBadge extends StatelessWidget {
  const UserBadge({
    required this.name,
    this.title,
    this.titleColor,
    this.anonymous = false,
    this.uid,
    this.avatarUrl,
    this.onAvatarTap,
    super.key,
  });
  final String name;
  final String? title;
  final Color? titleColor;
  final bool anonymous;
  final int? uid;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppAvatar(
          name: name,
          avatarUrl: avatarUrl,
          anonymous: anonymous,
          size: 32,
          onTap: onAvatarTap,
          borderColor: const Color(0xFFE2E8F0),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (hasTitle) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (titleColor ?? const Color(0xFF475569))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (titleColor ?? const Color(0xFF475569))
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: titleColor ?? const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (uid != null)
                Text(
                  'ID $uid',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class IconLabel extends StatelessWidget {
  const IconLabel({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref,
  String targetType,
  int targetId,
) {
  var reason = 'SPAM';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('涓炬姤鍐呭'),
      content: DropdownButtonFormField<String>(
        initialValue: reason,
        items: [
          DropdownMenuItem(value: 'SPAM', child: Text('鍨冨溇骞垮憡')),
          DropdownMenuItem(value: 'ILLEGAL', child: Text('杩濇硶杩濊')),
          DropdownMenuItem(value: 'HARASSMENT', child: Text('浜鸿韩鏀诲嚮')),
          DropdownMenuItem(value: 'PORNOGRAPHIC', child: Text('鑹叉儏浣庝織')),
          DropdownMenuItem(value: 'OTHER', child: Text('鍏朵粬')),
        ],
        onChanged: (value) => reason = value ?? reason,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('鍙栨秷'),
        ),
        FilledButton(
          onPressed: () async {
            await ref
                .read(appStateProvider)
                .report(targetType, targetId, reason);
            if (!context.mounted) return;
            Navigator.pop(context);
            showAppToast(
              context,
              title: '涓炬姤宸叉彁浜?,
              message: '绠＄悊鍛樹細鍦ㄥ悗鍙板鐞嗚繖鏉′妇鎶?,
              icon: Icons.flag_rounded,
              color: const Color(0xFF7C3AED),
            );
          },
          child: const Text('鎻愪氦'),
        ),
      ],
    ),
  );
}
