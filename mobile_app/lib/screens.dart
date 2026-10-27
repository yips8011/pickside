part of 'main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote_rounded, size: 54, color: Color(0xFF2563EB)),
            SizedBox(height: 14),
            Text(
              '绔欓槦',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final username = TextEditingController(text: 'admin');
  final password = TextEditingController(text: '123456');
  final nickname = TextEditingController(text: '鏂扮敤鎴?);
  bool registerMode = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFE0F2FE), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.how_to_vote,
                      size: 54,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registerMode ? '鍒涘缓璐﹀彿' : '绔欓槦',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: username,
                      decoration: InputDecoration(
                        labelText: registerMode ? '璐﹀彿' : '璐﹀彿鎴?ID',
                        helperText: registerMode
                            ? '鑷冲皯 5 浣嶏紝涓嶈兘绾暟瀛楁垨绗﹀彿寮€澶?
                            : '鍙緭鍏ヨ处鍙锋垨绯荤粺鍒嗛厤 ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '瀵嗙爜'),
                    ),
                    if (registerMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: nickname,
                        decoration: const InputDecoration(
                          labelText: '鏄电О',
                          helperText: '2-8 涓瓧锛屼粎鐢ㄤ簬灞曠ず',
                        ),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(registerMode ? '娉ㄥ唽骞惰繘鍏? : '鐧诲綍'),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => registerMode = !registerMode),
                      child: Text(registerMode ? '宸叉湁璐﹀彿锛屽幓鐧诲綍' : '娌℃湁璐﹀彿锛屾敞鍐屼竴涓?),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final state = ref.read(appStateProvider);
      if (registerMode) {
        await state.register(username.text, password.text, nickname.text);
      } else {
        await state.login(username.text, password.text);
      }
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(appStateProvider);
      final notice = state.startupAnnouncement;
      if (await state.shouldShowStartupAnnouncement() && mounted) {
        await state.markStartupAnnouncementShown();
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(notice.title),
            content: Text(notice.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('鐭ラ亾浜?),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: appPageBackground(context),
        appBar: AppBar(
          backgroundColor: appPageBackground(context),
          surfaceTintColor: Colors.transparent,
          title: const Text('绔欓槦'),
          actions: [
            IconButton(
              tooltip: '鎼滅储',
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: '娑堟伅',
              onPressed: () => context.go('/messages'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '鎺ㄨ崘'),
              Tab(text: '鏈€鏂?),
              Tab(text: '鐑棬'),
              Tab(text: '鍏虫敞'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PollFeed(polls: state.polls, showHeader: true),
            PollFeed(
              polls: [...state.polls]..sort((a, b) => b.id.compareTo(a.id)),
              showHeader: true,
            ),
            PollFeed(
              polls: [...state.polls]
                ..sort((a, b) => b.voteCount.compareTo(a.voteCount)),
              showHeader: true,
            ),
            const EmptyState(
              icon: Icons.people_outline,
              text: '鍏虫敞鐨勪汉鍙戝竷鎶曠エ鍚庝細鍑虹幇鍦ㄨ繖閲?,
            ),
          ],
        ),
      ),
    );
  }
}

class PollFeed extends ConsumerWidget {
  const PollFeed({required this.polls, this.showHeader = false, super.key});
  final List<Poll> polls;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final headerCount = showHeader ? 2 : 0;
    return RefreshIndicator(
      onRefresh: () async =>
          Future<void>.delayed(const Duration(milliseconds: 350)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
        itemBuilder: (_, index) {
          if (showHeader && index == 0) {
            return HomeAdBanner(
              ads: state.ads.where((ad) => ad.enabled).toList(),
            );
          }
          if (showHeader && index == 1) {
            return HomeMarquee(
              text: state.marqueeAnnouncement.enabled
                  ? state.marqueeAnnouncement.body
                  : '',
            );
          }
          final pollIndex = index - headerCount;
          return _FeedAppear(
            child: PollCard(poll: polls[pollIndex], homeFeed: true),
          );
        },
        separatorBuilder: (_, index) {
          if (showHeader && index < headerCount - 1) {
            return const SizedBox(height: 12);
          }
          return const SizedBox(height: 12);
        },
        itemCount: polls.length + headerCount,
      ),
    );
  }
}

class _FeedAppear extends StatelessWidget {
  const _FeedAppear({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FeedBreak extends StatelessWidget {
  const _FeedBreak();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: const Color(0xFFDDE5F0),
        ),
        Container(
          height: 12,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF1F5FA), Color(0xFFF7F9FC)],
            ),
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: Color(0xFFEAF0F7),
        ),
      ],
    );
  }
}

class HomeAdBanner extends StatelessWidget {
  const HomeAdBanner({required this.ads, super.key});
  final List<HomeAd> ads;

  @override
  Widget build(BuildContext context) {
    final visible = ads.isEmpty
        ? [
            HomeAd(
              '绔欓槦',
              '鎶婇€夋嫨浜ょ粰鐪熷疄浜虹兢',
              'https://picsum.photos/seed/default-poll-banner/900/320',
              true,
            ),
          ]
        : ads;
    return SizedBox(
      height: 148,
      child: PageView.builder(
        itemCount: visible.length,
        itemBuilder: (_, index) {
          final ad = visible[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFEFF6FF),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140F172A),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFFEFF6FF)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.46),
                        Colors.black.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Text(
                          '鍏憡',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ad.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HomeMarquee extends StatefulWidget {
  const HomeMarquee({required this.text, super.key});
  final String text;

  @override
  State<HomeMarquee> createState() => _HomeMarqueeState();
}

class _HomeMarqueeState extends State<HomeMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: Color(0xFFB45309),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(-controller.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 72),
                    Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PollCard extends ConsumerWidget {
  const PollCard({
    required this.poll,
    this.enableVoting = false,
    this.homeFeed = false,
    super.key,
  });
  final Poll poll;
  final bool enableVoting;
  final bool homeFeed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(appStateProvider);
    final revealAnonymous = state.currentUser.isCreatorAdmin;
    final title = poll.isAnonymous && !revealAnonymous
        ? null
        : state.titleForUser(poll.author);
    if (homeFeed) {
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeAuthorRow(
            name: poll.displayAuthorName(revealAnonymous: revealAnonymous),
            title: title?.name,
            titleColor: title?.color,
            anonymous: poll.isAnonymous && !revealAnonymous,
            avatarUrl: poll.isAnonymous && !revealAnonymous
                ? null
                : poll.author.avatarUrl,
            onAvatarTap: poll.isAnonymous && !revealAnonymous
                ? null
                : () => context.push('/user/${poll.author.uid}'),
            meta: formatEndTime(poll.endAt),
            active: !poll.hasEnded,
          ),
          const SizedBox(height: 14),
          Text(
            poll.title,
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              height: 1.18,
              fontSize: 20,
            ),
          ),
          if (poll.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              poll.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
          if (poll.isAnonymous ||
              poll.allowAnonymousVote ||
              poll.interactionLocked) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (poll.isAnonymous)
                  const StatusPill(
                    label: '鍖垮悕鍙戝竷',
                    color: Color(0xFF7C3AED),
                    compact: true,
                  ),
                if (poll.anonymousRevealLabel(revealAnonymous: revealAnonymous)
                    case final label?)
                  StatusPill(
                    label: label,
                    color: const Color(0xFF7C3AED),
                    compact: true,
                  ),
                if (poll.allowAnonymousVote)
                  const StatusPill(
                    label: '鍖垮悕鎶曠エ',
                    color: Color(0xFF2563EB),
                    compact: true,
                  ),
                if (poll.interactionLocked)
                  const StatusPill(
                    label: '绂佹浜掑姩',
                    color: Color(0xFFDC2626),
                    compact: true,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          ...poll.options
              .take(enableVoting ? poll.options.length : 3)
              .map(
                (option) => ResultBar(
                  option: option,
                  total: poll.voteCount,
                  selected: poll.myOptionId == option.id,
                  disabled:
                      !enableVoting ||
                      poll.votedUserIds.contains(state.currentUser.id),
                  framed: false,
                  onTap: enableVoting
                      ? () async {
                          if (poll.interactionLocked) {
                            showAppToast(
                              context,
                              title: '浜掑姩宸插叧闂?,
                              message: lockedInteractionMessage,
                              icon: Icons.lock_outline_rounded,
                              color: const Color(0xFFDC2626),
                            );
                            return;
                          }
                          await state.vote(poll.id, option.id);
                        }
                      : null,
                ),
              ),
          if (!enableVoting && poll.options.length > 3) ...[
            const SizedBox(height: 6),
            _MoreOptionsHint(count: poll.options.length - 3),
          ],
          const SizedBox(height: 10),
          enableVoting
              ? _PollDetailActionRow(poll: poll)
              : _HomeActionRow(poll: poll),
        ],
      );
      if (enableVoting) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
          child: content,
        );
      }
      return _HomeFeedSurface(
        onTap: () => context.push('/poll/${poll.id}'),
        child: content,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enableVoting ? null : () => context.push('/poll/${poll.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: UserBadge(
                      name: poll.displayAuthorName(
                        revealAnonymous: revealAnonymous,
                      ),
                      title: title?.name,
                      titleColor: title?.color,
                      anonymous: poll.isAnonymous && !revealAnonymous,
                      avatarUrl: poll.isAnonymous && !revealAnonymous
                          ? null
                          : poll.author.avatarUrl,
                      onAvatarTap: poll.isAnonymous && !revealAnonymous
                          ? null
                          : () => context.push('/user/${poll.author.uid}'),
                    ),
                  ),
                  _TinyStateDot(active: !poll.hasEnded),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                poll.title,
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  fontSize: 17,
                ),
              ),
              if (poll.description.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  poll.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (poll.isAnonymous)
                    const StatusPill(
                      label: '鍖垮悕鍙戝竷',
                      color: Color(0xFF7C3AED),
                      compact: true,
                    ),
                  if (poll.anonymousRevealLabel(
                        revealAnonymous: revealAnonymous,
                      )
                      case final label?)
                    StatusPill(
                      label: label,
                      color: const Color(0xFF7C3AED),
                      compact: true,
                    ),
                  if (poll.allowAnonymousVote)
                    const StatusPill(
                      label: '鍖垮悕鎶曠エ',
                      color: Color(0xFF2563EB),
                      compact: true,
                    ),
                  if (poll.interactionLocked)
                    const StatusPill(
                      label: '绂佹浜掑姩',
                      color: Color(0xFFDC2626),
                      compact: true,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...poll.options
                  .take(enableVoting ? poll.options.length : 3)
                  .map(
                    (option) => ResultBar(
                      option: option,
                      total: poll.voteCount,
                      selected: poll.myOptionId == option.id,
                      disabled:
                          !enableVoting ||
                          poll.votedUserIds.contains(state.currentUser.id),
                      onTap: enableVoting
                          ? () async {
                              if (poll.interactionLocked) {
                                showAppToast(
                                  context,
                                  title: '浜掑姩宸插叧闂?,
                                  message: lockedInteractionMessage,
                                  icon: Icons.lock_outline_rounded,
                                  color: const Color(0xFFDC2626),
                                );
                                return;
                              }
                              await state.vote(poll.id, option.id);
                            }
                          : null,
                    ),
                  ),
              if (!enableVoting && poll.options.length > 3) ...[
                const SizedBox(height: 6),
                _MoreOptionsHint(count: poll.options.length - 3),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconLabel(
                      icon: Icons.how_to_vote_outlined,
                      label: '${poll.voteCount} 浜?,
                    ),
                    IconLabel(
                      icon: Icons.chat_bubble_outline,
                      label: '${poll.comments.length}',
                    ),
                    IconLabel(
                      icon: Icons.thumb_up_alt_outlined,
                      label: '${poll.likeCount}',
                    ),
                    IconLabel(
                      icon: Icons.bookmark_border_rounded,
                      label: '${poll.favoriteCount}',
                    ),
                    const Spacer(),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatEndTime(poll.endAt),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeedSurface extends StatefulWidget {
  const _HomeFeedSurface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_HomeFeedSurface> createState() => _HomeFeedSurfaceState();
}

class _HomeFeedSurfaceState extends State<_HomeFeedSurface> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPressStart: (_) => setState(() => pressed = true),
      onLongPressEnd: (_) => setState(() => pressed = false),
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: pressed ? 0.8 : 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HomeAuthorRow extends StatelessWidget {
  const _HomeAuthorRow({
    required this.name,
    required this.meta,
    required this.active,
    this.title,
    this.titleColor,
    this.anonymous = false,
    this.avatarUrl,
    this.onAvatarTap,
  });

  final String name;
  final String meta;
  final bool active;
  final String? title;
  final Color? titleColor;
  final bool anonymous;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    return Row(
      children: [
        AppAvatar(
          name: name,
          avatarUrl: avatarUrl,
          anonymous: anonymous,
          size: 44,
          onTap: onAvatarTap,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasTitle) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (titleColor ?? const Color(0xFF475569))
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
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
              const SizedBox(height: 3),
              Text(
                meta,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _HomeActionRow extends ConsumerWidget {
  const _HomeActionRow({required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _HomeActionButton(
            icon: poll.isLiked
                ? Icons.thumb_up_alt_rounded
                : Icons.thumb_up_alt_outlined,
            label: '${poll.likeCount}',
            selected: poll.isLiked,
            onTap: () => state.likePoll(poll.id),
          ),
          _HomeActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${poll.comments.length}',
            onTap: () => context.push('/poll/${poll.id}'),
          ),
          _HomeActionButton(
            icon: Icons.ios_share_rounded,
            label: '鍒嗕韩',
            onTap: () {
              state.sharePoll(context, poll);
            },
          ),
          const Spacer(),
          _HomeActionButton(
            icon: Icons.how_to_vote_outlined,
            label: '${poll.voteCount} 浜?,
            onTap: () => context.push('/poll/${poll.id}'),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsHint extends StatelessWidget {
  const _MoreOptionsHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Container(
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.035),
        ),
      ),
      child: Text(
        '杩樻湁 $count 涓€夐」锛岃繘鍏ヨ鎯呮煡鐪?,
        style: TextStyle(
          color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PollDetailActionRow extends ConsumerWidget {
  const _PollDetailActionRow({required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.read(appStateProvider);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _HomeActionButton(
            icon: poll.isLiked
                ? Icons.thumb_up_alt_rounded
                : Icons.thumb_up_alt_outlined,
            label: '${poll.likeCount}',
            selected: poll.isLiked,
            onTap: () => state.likePoll(poll.id),
          ),
          _HomeActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${poll.comments.length}',
            onTap: () => Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            ),
          ),
          _HomeActionButton(
            icon: Icons.ios_share_rounded,
            label: '鍒嗕韩',
            onTap: () {
              state.sharePoll(context, poll);
            },
          ),
          const Spacer(),
          _HomeActionButton(
            icon: poll.isFavorited
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: '${poll.favoriteCount}',
            selected: poll.isFavorited,
            onTap: () => state.favoritePoll(poll.id),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatefulWidget {
  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_HomeActionButton> createState() => _HomeActionButtonState();
}

class _HomeActionButtonState extends State<_HomeActionButton> {
  bool pressed = false;

  void down() => setState(() => pressed = true);
  void up() => setState(() => pressed = false);

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? const Color(0xFF2563EB)
        : const Color(0xFF6B7280);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => down(),
      onTapUp: (_) {
        up();
        widget.onTap();
      },
      onTapCancel: up,
      child: AnimatedScale(
        scale: pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 20, color: color),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyStateDot extends StatelessWidget {
  const _TinyStateDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF16A34A) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            active ? '杩涜涓? : '宸茬粨鏉?,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ResultBar extends StatelessWidget {
  const ResultBar({
    required this.option,
    required this.total,
    this.selected = false,
    this.onTap,
    this.disabled = false,
    this.framed = true,
    super.key,
  });
  final PollOption option;
  final int total;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : option.voteCount / total;
    final percent = (ratio * 100).toStringAsFixed(0);
    final color = selected ? const Color(0xFF2563EB) : option.color;
    final canTap = onTap != null && !disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canTap ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: framed
                ? const EdgeInsets.all(12)
                : const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: framed
                  ? (selected ? const Color(0xFFEFF6FF) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: framed
                  ? Border.all(
                      color: selected
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFFE2E8F0),
                    )
                  : null,
              boxShadow: framed && selected
                  ? const [
                      BoxShadow(
                        color: Color(0x142563EB),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 720),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percent%',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              '鍗犳瘮',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (selected) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 17,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              option.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final dotWidth =
                              (constraints.maxWidth - 28).clamp(
                                0.0,
                                constraints.maxWidth,
                              ) *
                              ratio;
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 7,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: dotWidth),
                                duration: const Duration(milliseconds: 720),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) =>
                                    Transform.translate(
                                      offset: Offset(value, 0),
                                      child: child,
                                    ),
                                child: Container(
                                  width: 28,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.24),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MiniMetric(
                            icon: Icons.how_to_vote_rounded,
                            label: '${option.voteCount} 绁?,
                          ),
                          const SizedBox(width: 8),
                          _MiniMetric(
                            icon: Icons.group_outlined,
                            label: total == 0 ? '鏆傛棤鍙備笌' : '鍏?$total 浜?,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PollDetailScreen extends ConsumerStatefulWidget {
  const PollDetailScreen({required this.pollId, super.key});
  final int pollId;

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  final comment = TextEditingController();
  bool anonymousComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider).syncPollComments(widget.pollId);
    });
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final poll = state.maybePollById(widget.pollId);
    if (poll == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(title: const Text('鎶曠エ璇︽儏')),
        body: const EmptyState(icon: Icons.delete_outline, text: '鎶曠エ宸插垹闄ゆ垨涓嶅彲瑙?),
      );
    }
    final canManage = state.canManagePoll(poll);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('鎶曠エ璇︽儏'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '鏇村',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) async {
              if (value == 'report') {
                await showReportDialog(context, ref, 'POLL', poll.id);
              }
              if (value == 'lock') {
                await state.lockPollComments(poll.id);
              }
              if (value == 'unlock') {
                await state.unlockPollComments(poll.id);
              }
              if (value == 'delete') {
                await state.deletePoll(poll.id);
                if (context.mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                }
              }
              if (value == 'edit') {
                if (poll.editApproved) {
                  if (!context.mounted) return;
                  await showEditPollDialog(context, ref, poll);
                } else {
                  state.requestPollEdit(poll);
                  if (context.mounted) {
                    showAppToast(
                      context,
                      title: '鐢宠宸叉彁浜?,
                      message: '瀹℃牳閫氳繃鍚庡彲浠ョ紪杈戞爣棰樺拰鎻忚堪',
                      icon: Icons.edit_note_rounded,
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Text('涓炬姤')),
              if (poll.author.id == state.currentUser.id)
                PopupMenuItem(
                  value: 'edit',
                  child: Text(poll.editApproved ? '缂栬緫甯栧瓙' : '鐢宠鎭㈠缂栬緫'),
                ),
              if (canManage && !poll.interactionLocked)
                const PopupMenuItem(value: 'lock', child: Text('绂佹浜掑姩')),
              if (canManage && poll.interactionLocked)
                const PopupMenuItem(value: 'unlock', child: Text('瑙ｉ櫎绂佹浜掑姩')),
              if (canManage)
                const PopupMenuItem(value: 'delete', child: Text('鍒犻櫎鎶曠エ')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          PollCard(poll: poll, enableVoting: true, homeFeed: true),
          _ParticipantPreview(pollId: poll.id, voteCount: poll.voteCount),
          const _FeedBreak(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '璁ㄨ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (poll.allowAnonymousComment) ...[
                      Tooltip(
                        message: '鍖垮悕璇勮',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(
                            () => anonymousComment = !anonymousComment,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: anonymousComment
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: anonymousComment
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              '鍖?,
                              style: TextStyle(
                                color: anonymousComment
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: TextField(
                        controller: comment,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: poll.interactionLocked
                              ? lockedInteractionMessage
                              : '璇磋浣犵殑鐪嬫硶',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 46,
                      height: 42,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (poll.interactionLocked) {
                            showAppToast(
                              context,
                              title: '浜掑姩宸插叧闂?,
                              message: lockedInteractionMessage,
                              icon: Icons.lock_outline_rounded,
                              color: const Color(0xFFDC2626),
                            );
                            return;
                          }
                          await state.addComment(
                            poll.id,
                            comment.text,
                            anonymous:
                                poll.allowAnonymousComment && anonymousComment,
                          );
                          comment.clear();
                        },
                        child: const Icon(Icons.send_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
                if (poll.comments.isEmpty)
                  const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    text: '杩樻病鏈夎瘎璁?,
                  )
                else
                  for (final item in poll.comments)
                    _OpenCommentItem(
                      pollId: poll.id,
                      item: item,
                      revealAnonymous: state.currentUser.isCreatorAdmin,
                      onReport: () =>
                          showReportDialog(context, ref, 'COMMENT', item.id),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCommentItem extends ConsumerWidget {
  const _OpenCommentItem({
    required this.pollId,
    required this.item,
    required this.revealAnonymous,
    required this.onReport,
  });

  final int pollId;
  final PollComment item;
  final bool revealAnonymous;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anonymousMasked = item.isAnonymous && !revealAnonymous;
    final iconColor = anonymousMasked
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: item.displayAuthorName(revealAnonymous: revealAnonymous),
                avatarUrl: anonymousMasked ? null : item.author.avatarUrl,
                anonymous: anonymousMasked,
                size: 34,
                borderColor: iconColor.withValues(alpha: 0.18),
                onTap: anonymousMasked
                    ? null
                    : () => context.push('/user/${item.author.uid}'),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.displayAuthorName(
                              revealAnonymous: revealAnonymous,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isAnonymous || item.revealedByAdmin)
                          Builder(
                            builder: (context) {
                              final title = ref
                                  .read(appStateProvider)
                                  .titleForUser(item.author);
                              if (title == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: title.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    title.name,
                                    style: TextStyle(
                                      color: title.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (item.stanceColor != null)
                          Tooltip(
                            message: item.stanceText == null
                                ? '宸插弬涓庢姇绁?
                                : '绔嬪満锛?{item.stanceText}',
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: item.stanceColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: '涓炬姤璇勮',
                          onPressed: onReport,
                          icon: const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.content,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                    if (item.anonymousRevealLabel(
                          revealAnonymous: revealAnonymous,
                        )
                        case final label?) ...[
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _CommentMetric(
                          icon: item.myReaction == 'LIKE'
                              ? Icons.thumb_up_alt_rounded
                              : Icons.thumb_up_alt_outlined,
                          label: '${item.likeCount}',
                          selected: item.myReaction == 'LIKE',
                          onTap: () => ref
                              .read(appStateProvider)
                              .reactComment(pollId, item.id, 'LIKE'),
                        ),
                        const SizedBox(width: 14),
                        _CommentMetric(
                          icon: item.myReaction == 'DISLIKE'
                              ? Icons.thumb_down_alt_rounded
                              : Icons.thumb_down_alt_outlined,
                          label: '${item.dislikeCount}',
                          selected: item.myReaction == 'DISLIKE',
                          onTap: () => ref
                              .read(appStateProvider)
                              .reactComment(pollId, item.id, 'DISLIKE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF5)),
      ],
    );
  }
}

class _CommentMetric extends StatelessWidget {
  const _CommentMetric({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantPreview extends ConsumerWidget {
  const _ParticipantPreview({required this.pollId, required this.voteCount});

  final int pollId;
  final int voteCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<VoteParticipant>>(
      future: ref.read(appStateProvider).fetchPollParticipants(pollId),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];
        final preview = participants.take(3).toList();
        final remaining = participants.length > 3 ? participants.length - 3 : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Material(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: participants.isEmpty
                  ? null
                  : () => showParticipantsSheet(context, ref, pollId),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  children: [
                    if (snapshot.connectionState != ConnectionState.done)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (preview.isEmpty)
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group_outlined,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    else
                      SizedBox(
                        width:
                            34.0 +
                            (preview.length - 1) * 22.0 +
                            (remaining > 0 ? 28 : 0),
                        height: 36,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < preview.length; i++)
                              Positioned(
                                left: i * 22.0,
                                child: _ParticipantAvatar(
                                  participant: preview[i],
                                  size: 34,
                                ),
                              ),
                            if (remaining > 0)
                              Positioned(
                                left: preview.length * 22.0,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '+$remaining',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${participants.isEmpty ? voteCount : participants.length} 浜哄凡绔欓槦',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '鐐瑰嚮鏌ョ湅鍙備笌鎶曠エ鐢ㄦ埛',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
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
          ),
        );
      },
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.participant,
    this.size = 40,
    this.onTap,
  });

  final VoteParticipant participant;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: participant.displayName,
      avatarUrl: participant.avatarUrl,
      anonymous: participant.maskedAnonymous,
      size: size,
      onTap: onTap,
    );
  }
}

void showParticipantsSheet(BuildContext context, WidgetRef ref, int pollId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.68,
      child: FutureBuilder<List<VoteParticipant>>(
        future: ref.read(appStateProvider).fetchPollParticipants(pollId),
        builder: (context, snapshot) {
          final participants = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  Text(
                    '鍙備笌鎶曠エ鐢ㄦ埛',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${participants.length} 浜?,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                const EmptyState(
                  icon: Icons.error_outline_rounded,
                  text: '鍙備笌鐢ㄦ埛鍔犺浇澶辫触',
                )
              else if (participants.isEmpty)
                const EmptyState(icon: Icons.group_outlined, text: '杩樻病鏈夌敤鎴峰弬涓庢姇绁?)
              else
                ...participants.map(
                  (participant) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProfilePanel(
                      child: Row(
                        children: [
                          _ParticipantAvatar(
                            participant: participant,
                            onTap:
                                participant.maskedAnonymous ||
                                    participant.user == null
                                ? null
                                : () => context.push(
                                    '/user/${participant.user!.uid}',
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participant.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  participant.uidLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: participant.optionColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              participant.optionText,
                              style: TextStyle(
                                color: participant.optionColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class CreatePollScreen extends ConsumerStatefulWidget {
  const CreatePollScreen({super.key});

  @override
  ConsumerState<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends ConsumerState<CreatePollScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];
  DateTime? endAt = DateTime.now().add(const Duration(days: 7));
  bool isAnonymous = false;
  bool allowAnonymousVote = false;
  bool allowAnonymousComment = false;
  bool allowComment = true;
  bool allowLike = true;
  bool allowShare = true;
  bool publishing = false;

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    for (final option in options) {
      option.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('鍒涘缓鎶曠エ'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: appPanelColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appPanelBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.28)
                      : const Color(0x1A0F172A),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: publishing ? null : publish,
              icon: publishing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(publishing ? '鍙戝竷涓?..' : '鍙戝竷鎶曠エ'),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '鍏堝啓闂鍜岄€夐」锛岄珮绾у尶鍚嶈缃凡鎶樺彔锛涗簰鍔ㄥ紑鍏冲彂甯冨悗鍦ㄨ鎯呴〉绠＄悊銆?,
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '鎶曠エ鍐呭',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: '鏍囬'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '琛ュ厖鎻忚堪'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '鎶曠エ閫夐」',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: options[i],
                        decoration: InputDecoration(
                          labelText: '閫夐」 ${i + 1}',
                          prefixIcon: Icon(
                            Icons.circle,
                            color: optionColors[i % optionColors.length],
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: options.length >= 8
                            ? null
                            : () => setState(
                                () => options.add(TextEditingController()),
                              ),
                        icon: const Icon(Icons.add),
                        label: const Text('娣诲姞閫夐」'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: options.length <= 2
                            ? null
                            : () => setState(() {
                                final removed = options.removeLast();
                                removed.dispose();
                              }),
                        icon: const Icon(Icons.remove),
                        label: const Text('绉婚櫎'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftPanel(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('鎴鏃堕棿'),
                    subtitle: Text(
                      endAt == null
                          ? '闀挎湡鏈夋晥'
                          : DateFormat('yyyy-MM-dd HH:mm').format(endAt!),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: pickEndTime,
                  ),
                  const Divider(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text('楂樼骇璁剧疆'),
                    subtitle: const Text('鍖垮悕鍙戝竷銆佸尶鍚嶆姇绁ㄤ笌鍖垮悕璇勮'),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isAnonymous,
                        onChanged: (value) =>
                            setState(() => isAnonymous = value),
                        title: const Text('鍖垮悕鍙戝竷'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: allowAnonymousVote,
                        onChanged: (value) =>
                            setState(() => allowAnonymousVote = value),
                        title: const Text('鍏佽鍖垮悕鎶曠エ'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: allowAnonymousComment,
                        onChanged: (value) =>
                            setState(() => allowAnonymousComment = value),
                        title: const Text('鍏佽鍖垮悕璇勮'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> publish() async {
    if (publishing) return;
    final cleanOptions = options
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    if (title.text.trim().isEmpty || cleanOptions.length < 2) {
      showAppToast(
        context,
        title: '杩樺樊涓€鐐?,
        message: '璇峰～鍐欐爣棰橈紝骞惰嚦灏戞彁渚?2 涓€夐」',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFEA580C),
      );
      return;
    }
    setState(() => publishing = true);
    try {
      await ref
          .read(appStateProvider)
          .createPoll(
            title: title.text.trim(),
            description: description.text.trim(),
            options: cleanOptions,
            isAnonymous: isAnonymous,
            allowAnonymousVote: allowAnonymousVote,
            allowAnonymousComment: allowAnonymousComment,
            allowComment: allowComment,
            allowLike: allowLike,
            allowShare: allowShare,
            endAt: endAt,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => publishing = false);
      showAppToast(
        context,
        title: '鍙戝竷澶辫触',
        message: '$error',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFDC2626),
      );
      return;
    }
    if (!mounted) return;
    setState(() => publishing = false);
    showAppToast(
      context,
      title: '鍙戝竷鎴愬姛',
      message: '浣犵殑鎶曠エ宸茶繘鍏ラ椤?,
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF16A34A),
    );
    context.go('/home');
  }

  Future<void> pickEndTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: endAt ?? now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        endAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(() {
      endAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final query = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searching = query.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('鍙戠幇'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          TextField(
            controller: query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: '鎼滄姇绁ㄣ€佹悳鐢ㄦ埛',
              filled: true,
              fillColor: appPanelColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF93C5FD)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (searching)
            FutureBuilder<SearchBundle>(
              future: ref.read(appStateProvider).remoteSearch(query.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final result =
                    snapshot.data ?? const SearchBundle(polls: [], users: []);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DiscoverSectionTitle(
                      title: '鎶曠エ缁撴灉',
                      action: '${result.polls.length} 鏉?,
                    ),
                    if (result.polls.isEmpty)
                      const EmptyState(icon: Icons.search_off, text: '娌℃湁鎵惧埌鐩稿叧鎶曠エ')
                    else
                      ...result.polls.map(
                        (poll) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PollCard(poll: poll, homeFeed: true),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _DiscoverSectionTitle(
                      title: '鐢ㄦ埛缁撴灉',
                      action: '${result.users.length} 浣?,
                    ),
                    if (result.users.isEmpty)
                      const EmptyState(
                        icon: Icons.person_search_outlined,
                        text: '娌℃湁鎵惧埌鐩稿叧鐢ㄦ埛',
                      )
                    else
                      ...result.users.map(
                        (user) => _DiscoverUserTile(user: user),
                      ),
                  ],
                );
              },
            )
          else ...[
            FutureBuilder<List<TrendingTopic>>(
              future: ref.read(appStateProvider).fetchTrendingTopics(),
              builder: (context, snapshot) {
                final topics = snapshot.data ?? <TrendingTopic>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DiscoverSectionTitle(title: '鐑棬璇濋', action: '瀹炴椂'),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (topics.isEmpty)
                      const SizedBox.shrink()
                    else
                      _TopicCloud(
                        topics: topics.map((t) => t.name).toList(),
                        onSelected: (topic) => setState(() => query.text = topic),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const _DiscoverSectionTitle(title: '鍒嗙被', action: '鎺㈢储'),
            _CategoryGrid(
              onSelected: (category) => setState(() => query.text = category),
            ),
            const SizedBox(height: 22),
            FutureBuilder<List<Poll>>(
              future: ref.read(appStateProvider).fetchHotPolls(),
              builder: (context, snapshot) {
                final polls = snapshot.data ?? <Poll>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DiscoverSectionTitle(title: '鎺掕姒?, action: '楂樼儹搴?),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (polls.isEmpty)
                      const SizedBox.shrink()
                    else
                      ...polls.take(5).map(
                        (poll) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RankingTile(rank: polls.indexOf(poll) + 1, poll: poll),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscoverSectionTitle extends StatelessWidget {
  const _DiscoverSectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: dark ? const Color(0xFFFAFAFA) : const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            action,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCloud extends StatelessWidget {
  const _TopicCloud({required this.topics, required this.onSelected});

  final List<String> topics;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: topics
          .map(
            (topic) => Material(
              color: appPanelColor(context),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: appPanelBorder(context)),
                  ),
                  child: Text(
                    '#$topic',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFE4E4E7)
                          : const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onSelected});

  final ValueChanged<String> onSelected;

  static const items = [
    (Icons.memory_rounded, '绉戞妧', Color(0xFF2563EB)),
    (Icons.sports_esports_rounded, '娓告垙', Color(0xFF7C3AED)),
    (Icons.emoji_events_rounded, '浣撹偛', Color(0xFF16A34A)),
    (Icons.movie_filter_rounded, '濞变箰', Color(0xFFDB2777)),
    (Icons.local_cafe_rounded, '鐢熸椿', Color(0xFFF59E0B)),
    (Icons.favorite_rounded, '鎯呮劅', Color(0xFFEF4444)),
    (Icons.public_rounded, '绀句細', Color(0xFF0F766E)),
    (Icons.directions_car_rounded, '姹借溅', Color(0xFF475569)),
    (Icons.school_rounded, '鏍″洯', Color(0xFF0891B2)),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: appPanelColor(context),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(item.$2),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appPanelBorder(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.$1, color: item.$3, size: 22),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFFAFAFA)
                          : const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.rank, required this.poll});

  final int rank;
  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final heat = poll.voteCount + poll.likeCount + poll.comments.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/poll/${poll.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF9CA3AF),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poll.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${poll.voteCount} 浜哄弬涓?路 ${poll.comments.length} 璇勮 路 鐑害 $heat',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class _DiscoverUserTile extends ConsumerWidget {
  const _DiscoverUserTile({required this.user});

  final DemoUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final title = state.titleForUser(user);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              UserBadge(
                name: user.nickname,
                title: title?.name,
                titleColor: title?.color,
                avatarUrl: user.avatarUrl,
                onAvatarTap: () => context.push('/user/${user.uid}'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: user.id == state.currentUser.id
                    ? null
                    : () => state.followUser(user),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('鍏虫敞'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(appStateProvider);
      await state.syncNotifications();
      await state.markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(appStateProvider).notifications;
    final systemItems = notifications
        .where((item) => !item.isInteraction)
        .toList();
    final interactionItems = notifications
        .where((item) => item.isInteraction)
        .toList();
    final currentItems = tab == 0 ? systemItems : interactionItems;
    final unreadSystem = systemItems.where((item) => !item.isRead).length;
    final unreadInteraction = interactionItems
        .where((item) => !item.isRead)
        .length;
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('閫氱煡涓績'),
        actions: [
          TextButton(
            onPressed: () => ref.read(appStateProvider).markNotificationsRead(),
            child: const Text('鍏ㄩ儴宸茶'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(appStateProvider).syncNotifications(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            Row(
              children: [
                Expanded(
                  child: _NotificationTab(
                    label: '绯荤粺娑堟伅',
                    count: unreadSystem,
                    selected: tab == 0,
                    onTap: () => setState(() => tab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NotificationTab(
                    label: '浜掑姩娑堟伅',
                    count: unreadInteraction,
                    selected: tab == 1,
                    onTap: () => setState(() => tab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (currentItems.isEmpty)
              EmptyState(
                icon: tab == 0
                    ? Icons.admin_panel_settings_outlined
                    : Icons.forum_outlined,
                text: tab == 0 ? '鏆傛棤绯荤粺娑堟伅' : '鏆傛棤浜掑姩娑堟伅',
              )
            else
              ...currentItems.map(
                (item) => _NotificationTile(
                  item: item,
                  system: tab == 0,
                  onTap: () =>
                      ref.read(appStateProvider).markNotificationRead(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF2563EB)
          : Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: selected ? 0 : 0.04),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? const Color(0xFF2563EB) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.system,
    required this.onTap,
  });

  final AppNotification item;
  final bool system;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final color = system ? const Color(0xFF2563EB) : const Color(0xFFDB2777);
    final icon = system ? Icons.campaign_rounded : _interactionIcon(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: unread ? 0.92 : 0.74),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    if (unread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(item.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          height: 1.38,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _interactionIcon(AppNotification item) {
    final text = '${item.title} ${item.body}';
    if (text.contains('璇勮') || text.contains('鍥炲')) {
      return Icons.mode_comment_rounded;
    }
    if (text.contains('鐐硅禐')) return Icons.thumb_up_alt_rounded;
    if (text.contains('鍏虫敞')) return Icons.person_add_alt_1_rounded;
    return Icons.notifications_active_rounded;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final stats = state.profileStats;
    final title = state.titleForUser(state.currentUser);
    final dark = isDarkUi(context);
    String compactCount(int value) =>
        value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}涓? : '$value';
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('鎴戠殑'),
        actions: [
          IconButton(
            tooltip: '璁剧疆',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          _ProfilePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(
                      name: state.currentUser.nickname,
                      avatarUrl: state.currentUser.avatarUrl,
                      size: 72,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  state.currentUser.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: dark
                                        ? const Color(0xFFFAFAFA)
                                        : const Color(0xFF111827),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (title != null) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: title.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    title.name,
                                    style: TextStyle(
                                      color: title.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'UID ${state.currentUser.uid}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.currentUser.bio.isEmpty
                                ? '杩樻病鏈変釜鎬х鍚?
                                : state.currentUser.bio,
                            style: TextStyle(
                              color: dark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF6B7280),
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        label: '鍙戝竷',
                        value: compactCount(stats.pollCount),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProfileStat(
                        label: '鍏虫敞',
                        value: compactCount(stats.followingCount),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProfileStat(
                        label: '绮変笣',
                        value: compactCount(stats.followerCount),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProfileStat(
                        label: '鑾疯禐',
                        value: compactCount(stats.receivedLikes),
                      ),
                    ),
                  ],
                ),
                if (state.currentUser.canAdmin) ...[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('杩涘叆绠＄悊鍚庡彴'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePanel(
            child: Column(
              children: [
                _ProfileActionTile(
                  icon: Icons.how_to_vote_outlined,
                  title: '鎴戠殑鎶曠エ',
                  subtitle: '${stats.pollCount} 鏉″凡鍙戝竷',
                  onTap: () => showPollListSheet(
                    context,
                    ref,
                    '鎴戠殑鎶曠エ',
                    ref.read(appStateProvider).fetchMyPolls,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.history_rounded,
                  title: '鍙備笌鍘嗗彶',
                  subtitle: '${stats.votedCount} 鏉″弬涓庤褰?,
                  onTap: () => showPollListSheet(
                    context,
                    ref,
                    '鍙備笌鍘嗗彶',
                    ref.read(appStateProvider).fetchVotedPolls,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.bookmark_border_rounded,
                  title: '鏀惰棌',
                  subtitle: '${stats.favoriteCount} 鏉℃敹钘忓唴瀹?,
                  onTap: () => showPollListSheet(
                    context,
                    ref,
                    '鏀惰棌',
                    ref.read(appStateProvider).fetchFavoritePolls,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.thumb_up_alt_outlined,
                  title: '鐐硅禐璁板綍',
                  subtitle: '${stats.likedCount} 鏉＄偣璧炲唴瀹?,
                  onTap: () => showPollListSheet(
                    context,
                    ref,
                    '鐐硅禐璁板綍',
                    ref.read(appStateProvider).fetchLikedPolls,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePanel(
            child: Column(
              children: [
                _ProfileActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: '鍏虫敞鍒楄〃',
                  subtitle: '${stats.followingCount} 浣嶅叧娉?,
                  onTap: () => showUserListSheet(
                    context,
                    ref,
                    '鍏虫敞鍒楄〃',
                    ref.read(appStateProvider).fetchFollowing,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.groups_2_outlined,
                  title: '绮変笣鍒楄〃',
                  subtitle: '${stats.followerCount} 浣嶇矇涓?,
                  onTap: () => showUserListSheet(
                    context,
                    ref,
                    '绮変笣鍒楄〃',
                    ref.read(appStateProvider).fetchFollowers,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.block_outlined,
                  title: '榛戝悕鍗?,
                  subtitle: '鏌ョ湅鍜岀Щ闄ゅ睆钄界敤鎴?,
                  onTap: () => showUserListSheet(
                    context,
                    ref,
                    '榛戝悕鍗?,
                    ref.read(appStateProvider).fetchBlockedUsers,
                    allowUnblock: true,
                  ),
                ),
                _ProfileActionTile(
                  icon: Icons.settings_outlined,
                  title: '璁剧疆',
                  subtitle: '璐﹀彿銆佸畨鍏ㄤ笌鍏充簬',
                  onTap: () => context.push('/settings'),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({required this.uid, super.key});
  final int uid;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  late Future<(DemoUser, List<Poll>)> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<(DemoUser, List<Poll>)> _load() async {
    final state = ref.read(appStateProvider);
    final user = await state.fetchUserProfile(widget.uid);
    final polls = await state.fetchUserPolls(widget.uid);
    return (user, polls);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final dark = isDarkUi(context);
    String compactCount(int value) =>
        value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}涓? : '$value';
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('鐢ㄦ埛涓婚〉'),
      ),
      body: FutureBuilder<(DemoUser, List<Poll>)>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              text: '鐢ㄦ埛涓婚〉鍔犺浇澶辫触',
            );
          }
          final user = snapshot.data!.$1;
          final userPolls = snapshot.data!.$2;
          final title = state.titleForUser(user);
          final isSelf = user.uid == state.currentUser.uid;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _ProfilePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppAvatar(
                            name: user.nickname,
                            avatarUrl: user.avatarUrl,
                            size: 72,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.nickname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: dark
                                              ? const Color(0xFFFAFAFA)
                                              : const Color(0xFF111827),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    if (title != null) ...[
                                      const SizedBox(width: 7),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: title.color.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          title.name,
                                          style: TextStyle(
                                            color: title.color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'UID ${user.uid}',
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.bio.isEmpty ? '杩樻病鏈変釜鎬х鍚? : user.bio,
                                  style: TextStyle(
                                    color: dark
                                        ? const Color(0xFFA1A1AA)
                                        : const Color(0xFF6B7280),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileStat(
                              label: '鍙戝竷',
                              value: compactCount(user.pollCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '鍏虫敞',
                              value: compactCount(user.followingCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '绮変笣',
                              value: compactCount(user.followerCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '鑾疯禐',
                              value: compactCount(user.receivedLikes),
                            ),
                          ),
                        ],
                      ),
                      if (!isSelf) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await state.followUser(user);
                                  await _refresh();
                                  if (context.mounted) {
                                    showAppToast(
                                      context,
                                      title: '宸插叧娉?,
                                      message: '浣犲凡鍏虫敞 ${user.nickname}',
                                      icon: Icons.person_add_alt_1_rounded,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('鍏虫敞'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await state.blockUser(user);
                                  if (context.mounted) {
                                    showAppToast(
                                      context,
                                      title: '宸插姞鍏ラ粦鍚嶅崟',
                                      message: '浣犲皢鍑忓皯鐪嬪埌璇ョ敤鎴峰唴瀹?,
                                      icon: Icons.block_outlined,
                                      color: const Color(0xFFDC2626),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.block_outlined),
                                label: const Text('鎷夐粦'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '鍙戝竷鐨勭珯闃?,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: dark
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                if (userPolls.isEmpty)
                  const EmptyState(
                    icon: Icons.how_to_vote_outlined,
                    text: '杩樻病鏈夊彂甯冩姇绁?,
                  )
                else
                  for (final poll in userPolls) ...[
                    PollCard(poll: poll, homeFeed: true),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appPanelColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPanelBorder(context)),
      ),
      child: child,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: dark ? const Color(0xFFFAFAFA) : const Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
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

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final dark = isDarkUi(context);
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('璐﹀彿璁剧疆'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          _ProfilePanel(
            child: Row(
              children: [
                AppAvatar(
                  name: state.currentUser.nickname,
                  avatarUrl: state.currentUser.avatarUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.currentUser.nickname,
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFFAFAFA)
                              : const Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        state.currentUser.bio.isEmpty
                            ? '杩樻病鏈変釜浜虹畝浠?
                            : state.currentUser.bio,
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
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.image_outlined,
                  title: '淇敼澶村儚',
                  subtitle: '浠庣浉鍐岄€夋嫨骞朵笂浼犲ご鍍?,
                  onTap: () => pickAndUploadAvatar(context, ref),
                ),
                SettingsTile(
                  icon: Icons.badge_outlined,
                  title: '淇敼鏄电О',
                  subtitle: '鏇存柊浣犵殑鍏紑鏄电О',
                  onTap: () => showProfileEditDialog(context, ref),
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: '淇敼瀵嗙爜',
                  subtitle: '楠岃瘉鏃у瘑鐮佸悗鏇存柊鐧诲綍瀵嗙爜',
                  onTap: () => showPasswordDialog(context, ref),
                ),
                SettingsTile(
                  icon: Icons.notes_rounded,
                  title: '淇敼绠€浠?,
                  subtitle: '缂栬緫涓汉绛惧悕鍜屼富椤典粙缁?,
                  onTap: () => showProfileEditDialog(context, ref),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: '娣辫壊妯″紡',
                  subtitle: state.userSettings.darkMode ? '宸插紑鍚? : '宸插叧闂?,
                  onTap: () => state.updateUserSettings({
                    'darkMode': !state.userSettings.darkMode,
                  }),
                ),
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: '閫氱煡璁剧疆',
                  subtitle: '鐐硅禐銆佽瘎璁恒€佸叧娉ㄣ€佷妇鎶ュ鐞嗛€氱煡',
                  onTap: () => showNotificationSettings(context, ref),
                ),
                SettingsTile(
                  icon: Icons.screenshot_monitor_outlined,
                  title: '鎴浘鍒嗕韩鏂囨',
                  subtitle: state.userSettings.screenshotShareHint
                      ? '妫€娴嬫埅鍥惧悗鏄剧ず鍒嗕韩鎻愮ず'
                      : '宸插叧闂埅鍥炬彁绀?,
                  onTap: () => state.updateUserSettings({
                    'screenshotShareHint':
                        !state.userSettings.screenshotShareHint,
                  }),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '鍏充簬鎴戜滑',
                  subtitle: '绔欓槦 App 涓庣増鏈俊鎭?,
                  onTap: () => showSimpleSheet(context, '鍏充簬鎴戜滑', aboutText),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: '鐢ㄦ埛鍗忚',
                  subtitle: '鏌ョ湅鏈嶅姟鏉℃涓庣ぞ鍖鸿鍒?,
                  onTap: () => showSimpleSheet(context, '鐢ㄦ埛鍗忚', agreementText),
                ),
                SettingsTile(
                  icon: Icons.block_outlined,
                  title: '榛戝悕鍗曠鐞?,
                  subtitle: '鏌ョ湅鍜岀Щ闄ゅ凡灞忚斀鐢ㄦ埛',
                  onTap: () => showUserListSheet(
                    context,
                    ref,
                    '榛戝悕鍗曠鐞?,
                    ref.read(appStateProvider).fetchBlockedUsers,
                    allowUnblock: true,
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfilePanel(
            child: SettingsTile(
              icon: Icons.logout_rounded,
              title: '閫€鍑虹櫥褰?,
              subtitle: '閫€鍑哄綋鍓嶈处鍙峰苟杩斿洖鐧诲綍椤?,
              onTap: () => ref.read(appStateProvider).logout(),
              showDivider: false,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

const aboutText = '''
绔欓槦鏄竴娆惧洿缁曡鐐广€侀€夋嫨鍜屽尶鍚嶈〃杈剧殑鎶曠エ绀惧尯 App銆?
褰撳墠鐗堟湰瀹氫綅涓?MVP 1.0锛氭敮鎸佸彂甯冩姇绁ㄣ€佸弬涓庢姇绁ㄣ€佽瘎璁轰簰鍔ㄣ€佸叧娉ㄦ敹钘忋€侀€氱煡涓績銆佷妇鎶ュ鏍搞€佹潈闄愬悗鍙般€佸箍鍛婁笌鍏憡绛夋牳蹇冮棴鐜€?
鎴戜滑甯屾湜瀹冩棦鑳戒繚鐣欏尶鍚嶈〃杈剧殑杞绘澗鎰燂紝涔熻兘閫氳繃涓炬姤銆佸鏍搞€佸皝绂併€佺姝簰鍔ㄧ瓑鏈哄埗缁存寔绀惧尯绉╁簭銆?
鐗堟湰锛?.0.0 鏈湴娴嬭瘯鐗?鎶€鏈爤锛欶lutter + NestJS + Prisma + PostgreSQL
''';

const agreementText = '''
娆㈣繋浣跨敤绔欓槦銆備娇鐢ㄦ湰搴旂敤鍗宠〃绀轰綘鐞嗚В骞跺悓鎰忎互涓嬭鍒欙細

1. 璐﹀彿涓庡畨鍏?浣犻渶瑕佸鑷繁鐨勮处鍙疯涓鸿礋璐ｃ€傝鍕垮叡浜处鍙枫€佺洍鐢ㄤ粬浜鸿处鍙枫€佹伓鎰忔敞鍐屾垨缁曡繃骞冲彴闄愬埗銆?
2. 鍐呭鍙戝竷
浣犲彲浠ュ洿缁曡鐐广€侀€夋嫨鍜屽叕鍏辫瘽棰樺彂甯冩姇绁紝浣嗕笉寰楀彂甯冭繚娉曡繚瑙勩€佹毚鍔涙亹鍚撱€佽壊鎯呬綆淇椼€佽瘓楠楀紩娴併€佹伓鎰忔敾鍑汇€佷镜鐘殣绉併€佷镜鐘煡璇嗕骇鏉冩垨璇卞鍒风エ鐨勫唴瀹广€?
3. 鍖垮悕鍔熻兘
鍖垮悕鍙戝竷銆佸尶鍚嶆姇绁ㄥ拰鍖垮悕璇勮浠呯敤浜庨檷浣庤〃杈惧帇鍔涳紝涓嶄唬琛ㄥ彲浠ラ€冮伩绀惧尯瑙勫垯銆傚钩鍙颁粛浼氫繚鐣欏繀瑕佺殑瀹℃牳鍜岄鎺ц兘鍔涖€?
4. 浜掑姩瑙勫垯
璇峰皧閲嶄笉鍚岃鐐广€傜姝㈣颈楠傘€佷汉韬敾鍑汇€侀獨鎵般€佹伓鎰忓埛璧炪€佸埛绁ㄣ€佹壒閲忎妇鎶ユ垨鍒╃敤婕忔礊褰卞搷绀惧尯绉╁簭銆?
5. 涓炬姤涓庣鐞?鐢ㄦ埛鍙互涓炬姤鎶曠エ銆佽瘎璁烘垨鐢ㄦ埛銆傜鐞嗗憳鍙牴鎹鍒欏垹闄ゅ唴瀹广€佺姝簰鍔ㄣ€佸皝绂佹垨绂佽█璐﹀彿锛屽苟鍚戠浉鍏崇敤鎴峰彂閫佸鐞嗛€氱煡銆?
6. 鏁版嵁涓庨殣绉?骞冲彴浼氫繚瀛樿处鍙疯祫鏂欍€佹姇绁ㄨ褰曘€佸叧娉ㄦ敹钘忋€侀€氱煡鍜屽繀瑕佺殑鎿嶄綔鏃ュ織锛岀敤浜庢彁渚涙湇鍔°€佷繚闅滃畨鍏ㄥ拰澶勭悊浜夎銆傚ご鍍忋€佹樀绉般€佺畝浠嬬瓑鍏紑璧勬枡浼氬湪鐩稿簲椤甸潰灞曠ず銆?
7. 鏈嶅姟鍙樻洿
搴旂敤浠嶅浜庣涓€鐗堟祴璇曢樁娈碉紝鍔熻兘銆佽鍒欏拰灞曠ず鏂瑰紡鍙兘鎸佺画璋冩暣銆傞噸澶у彉鍖栦細閫氳繃鍏憡鎴栫郴缁熸秷鎭彁绀恒€?
璇风悊鎬ц〃杈撅紝璁ょ湡绔欓槦銆?''';

Future<void> pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 82,
    maxWidth: 1600,
  );
  if (picked == null) return;
  try {
    await ref.read(appStateProvider).updateAvatar(picked.path);
    if (context.mounted) {
      showAppToast(
        context,
        title: '澶村儚宸叉洿鏂?,
        message: '涓汉璧勬枡宸插悓姝ヤ繚瀛?,
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      );
    }
  } catch (error) {
    if (context.mounted) {
      showAppToast(
        context,
        title: '涓婁紶澶辫触',
        message: '$error',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFDC2626),
      );
    }
  }
}

Future<void> showProfileEditDialog(BuildContext context, WidgetRef ref) async {
  final state = ref.read(appStateProvider);
  final username = TextEditingController(text: state.currentUser.username);
  final nickname = TextEditingController(text: state.currentUser.nickname);
  final bio = TextEditingController(text: state.currentUser.bio);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('淇敼璧勬枡'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: username,
            decoration: const InputDecoration(
              labelText: '璐﹀彿',
              helperText: '鑷冲皯 5 浣嶏紝涓嶈兘绾暟瀛楁垨绗﹀彿寮€澶?,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nickname,
            decoration: const InputDecoration(
              labelText: '鏄电О',
              helperText: '2-8 涓瓧锛屼粎鐢ㄤ簬灞曠ず',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bio,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '绠€浠?),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('鍙栨秷'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await state.updateAccountProfile(
                username: username.text,
                nickname: nickname.text,
                bio: bio.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (error) {
              if (context.mounted) {
                showAppToast(
                  context,
                  title: '淇濆瓨澶辫触',
                  message: '$error',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                );
              }
            }
          },
          child: const Text('淇濆瓨'),
        ),
      ],
    ),
  );
}

Future<void> showPasswordDialog(BuildContext context, WidgetRef ref) async {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('淇敼瀵嗙爜'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: '鏃у瘑鐮?),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: '鏂板瘑鐮?),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('鍙栨秷'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await ref
                  .read(appStateProvider)
                  .api
                  .dio
                  .patch(
                    '/auth/password',
                    data: {
                      'oldPassword': oldPassword.text,
                      'newPassword': newPassword.text,
                    },
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                showAppToast(
                  context,
                  title: '瀵嗙爜宸叉洿鏂?,
                  message: '涓嬫鐧诲綍璇蜂娇鐢ㄦ柊瀵嗙爜',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                );
              }
            } catch (error) {
              if (context.mounted) {
                showAppToast(
                  context,
                  title: '淇敼澶辫触',
                  message: '$error',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                );
              }
            }
          },
          child: const Text('淇濆瓨'),
        ),
      ],
    ),
  );
}

void showNotificationSettings(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(appStateProvider);
        final settings = state.userSettings;
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '閫氱煡璁剧疆',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: settings.notifyLikes,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyLikes': value}),
              title: const Text('鐐硅禐閫氱煡'),
            ),
            SwitchListTile(
              value: settings.notifyComments,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyComments': value}),
              title: const Text('璇勮涓庡洖澶嶉€氱煡'),
            ),
            SwitchListTile(
              value: settings.notifyFollows,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyFollows': value}),
              title: const Text('鍏虫敞閫氱煡'),
            ),
            SwitchListTile(
              value: settings.notifyReports,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyReports': value}),
              title: const Text('涓炬姤澶勭悊閫氱煡'),
            ),
          ],
        );
      },
    ),
  );
}

void showSimpleSheet(BuildContext context, String title, String body) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.7,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            title,
            style: Theme.of(
              sheetContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(height: 1.55)),
        ],
      ),
    ),
  );
}

void showPollListSheet(
  BuildContext context,
  WidgetRef ref,
  String title,
  Future<List<Poll>> Function() loader,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.72,
      child: FutureBuilder<List<Poll>>(
        future: loader(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                EmptyState(
                  icon: Icons.error_outline_rounded,
                  text: '鍔犺浇澶辫触锛岃绋嶅悗閲嶈瘯',
                )
              else if (items.isEmpty)
                const EmptyState(icon: Icons.inbox_outlined, text: '鏆傛棤鍐呭')
              else
                ...items.map(
                  (poll) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PollCard(poll: poll, homeFeed: true),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

void showUserListSheet(
  BuildContext context,
  WidgetRef ref,
  String title,
  Future<List<DemoUser>> Function() loader, {
  bool allowUnblock = false,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.62,
      child: FutureBuilder<List<DemoUser>>(
        future: loader(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (users.isEmpty)
                const EmptyState(icon: Icons.people_outline, text: '鏆傛棤鐢ㄦ埛')
              else
                ...users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProfilePanel(
                      child: Row(
                        children: [
                          UserBadge(
                            name: user.nickname,
                            title: ref
                                .read(appStateProvider)
                                .titleForUser(user)
                                ?.name,
                            titleColor: ref
                                .read(appStateProvider)
                                .titleForUser(user)
                                ?.color,
                            avatarUrl: user.avatarUrl,
                            onAvatarTap: () =>
                                context.push('/user/${user.uid}'),
                          ),
                          const Spacer(),
                          if (allowUnblock)
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(appStateProvider)
                                    .unblockUser(user);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('绉婚櫎'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showEditPollDialog(
  BuildContext context,
  WidgetRef ref,
  Poll poll,
) async {
  final title = TextEditingController(text: poll.title);
  final description = TextEditingController(text: poll.description);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('缂栬緫甯栧瓙'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: '鏍囬'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '鎻忚堪'),
          ),
          const SizedBox(height: 8),
          const Text(
            '閫夐」涓嶅彲缂栬緫',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('鍙栨秷'),
        ),
        FilledButton(
          onPressed: () {
            ref
                .read(appStateProvider)
                .editPollContent(poll, title.text, description.text);
            Navigator.pop(dialogContext);
          },
          child: const Text('淇濆瓨'),
        ),
      ],
    ),
  );
}

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final tabs = <Tab>[const Tab(text: '涓炬姤'), const Tab(text: '鐢ㄦ埛')];
    final views = <Widget>[const _ReportsAdminView(), const _UsersAdminView()];
    if (state.currentUser.canAudit) {
      tabs.add(const Tab(text: '瀹℃牳'));
      views.add(const _ReviewAdminView());
    }
    if (state.currentUser.canManageAds) {
      tabs.add(const Tab(text: '骞垮憡'));
      views.add(const _AdsAdminView());
    }
    if (state.currentUser.canManageRoles) {
      tabs.add(const Tab(text: '鏉冮檺鐢ㄦ埛'));
      views.add(const _RolesAdminView());
    }
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9FC),
          surfaceTintColor: Colors.transparent,
          title: const Text('绠＄悊鎺у埗鍙?),
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

class _ReportsAdminView extends ConsumerWidget {
  const _ReportsAdminView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final visibleReports = state.reports;
    if (visibleReports.isEmpty) {
      return const EmptyState(icon: Icons.flag_outlined, text: '鏆傛棤涓炬姤');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visibleReports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final report = visibleReports[index];
        final isCommentReport = report.targetType == 'COMMENT';
        final poll = isCommentReport
            ? state.maybePollForComment(report.targetId)
            : state.maybePollById(report.targetId);
        final comment = isCommentReport
            ? state.maybeCommentById(report.targetId)
            : null;
        final handled = report.status != 'PENDING';
        final statusColor = handled
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
        final title = isCommentReport
            ? (comment == null ? '璇勮宸插垹闄? : '璇勮锛?{comment.content}')
            : (poll?.title ?? '甯栧瓙宸插垹闄?);
        return SoftPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: handled ? '宸插鐞? : '鏈鐞?,
                      color: statusColor,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                if (isCommentReport && poll != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '鎵€灞炲笘瀛愶細${poll.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '鍘熷洜锛?{reportReasonLabel(report.reason)} 路 涓炬姤浜猴細${report.reporter.nickname}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: poll == null
                          ? null
                          : () => context.push('/poll/${poll.id}'),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('鎵撳紑甯栧瓙'),
                    ),
                    if (isCommentReport) ...[
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'delete'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('鍒犻櫎璇勮'),
                      ),
                      TextButton(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'reject'),
                        child: const Text('椹冲洖'),
                      ),
                    ] else ...[
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'lock'),
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('鍙楃悊绂佹浜掑姩'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'delete'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('鍙楃悊鍒犻櫎'),
                      ),
                      TextButton(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'reject'),
                        child: const Text('椹冲洖'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsersAdminView extends ConsumerStatefulWidget {
  const _UsersAdminView();

  @override
  ConsumerState<_UsersAdminView> createState() => _UsersAdminViewState();
}

class _UsersAdminViewState extends ConsumerState<_UsersAdminView> {
  final query = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final users = state.searchUsersByUid(query.text);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index == 0) {
          return TextField(
            controller: query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '鎼滅储鐢ㄦ埛 ID',
            ),
          );
        }
        final user = users[index - 1];
        final title = state.titleForUser(user);
        final canDelete =
            state.currentUser.isCreatorAdmin &&
            !user.canAdmin &&
            title == null &&
            user.id != state.currentUser.id;
        final canChangeRole =
            state.currentUser.isCreatorAdmin &&
            !user.isCreatorAdmin &&
            user.id != state.currentUser.id;
        final canMute = !user.isCreatorAdmin && user.id != state.currentUser.id;
        return SoftPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      user.muted
                          ? Icons.volume_off_outlined
                          : Icons.person_outline,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: UserBadge(
                        name: user.nickname,
                        title: title?.name,
                        titleColor: title?.color,
                        uid: user.uid,
                        avatarUrl: user.avatarUrl,
                        onAvatarTap: () => context.push('/user/${user.uid}'),
                      ),
                    ),
                    StatusPill(
                      label: user.muted ? '宸茬瑷€' : '姝ｅ父',
                      color: user.muted
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF16A34A),
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: canMute
                          ? () => state.adminUserAction(
                              user,
                              user.muted ? 'unban' : 'ban',
                            )
                          : null,
                      child: Text(user.muted ? '瑙ｇ' : '绂佽█'),
                    ),
                    if (state.currentUser.isCreatorAdmin)
                      OutlinedButton(
                        onPressed: canChangeRole
                            ? () => showAssignTitleDialog(context, ref, user)
                            : null,
                        child: Text(title == null ? '璁炬潈闄? : '鏀规潈闄?),
                      ),
                    if (state.currentUser.isCreatorAdmin && title != null)
                      OutlinedButton(
                        onPressed: canChangeRole
                            ? () => state.removeTitleFromUser(user)
                            : null,
                        child: const Text('瑙ｉ櫎鏉冮檺'),
                      ),
                    if (canDelete)
                      TextButton(
                        onPressed: () => state.adminUserAction(user, 'delete'),
                        child: const Text('鍒犻櫎'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showAssignTitleDialog(
  BuildContext context,
  WidgetRef ref,
  DemoUser user,
) async {
  final state = ref.read(appStateProvider);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('璁剧疆 ${user.nickname} 鐨勬潈闄?),
      children: [
        for (final title in state.titles.where((title) => title.id != 1))
          SimpleDialogOption(
            onPressed: () {
              state.assignTitleToUser(title, user);
              Navigator.pop(dialogContext);
            },
            child: Row(
              children: [
                StatusPill(
                  label: title.name,
                  color: title.color,
                  compact: true,
                ),
                const SizedBox(width: 8),
                Text('${title.permissions.length} 椤规潈闄?),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: () {
            state.removeTitleFromUser(user);
            Navigator.pop(dialogContext);
          },
          child: const Text('鍙樹负鏅€氱敤鎴?),
        ),
      ],
    ),
  );
}

class _ReviewAdminView extends ConsumerWidget {
  const _ReviewAdminView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final candidates =
        state.polls
            .where(
              (poll) =>
                  poll.editRequested ||
                  poll.editApproved ||
                  poll.interactionLocked,
            )
            .toList()
          ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    if (candidates.isEmpty) {
      return const EmptyState(icon: Icons.fact_check_outlined, text: '鏆傛棤瀹℃牳浜嬮」');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '瀹℃牳澶勭悊',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        for (final poll in candidates)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftPanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(
                          label: poll.editRequested ? '鏈鐞? : '宸插鐞?,
                          color: poll.editRequested
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            poll.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${poll.voteCount} 浜哄弬涓?路 ${poll.comments.length} 鏉¤瘎璁?路 ${poll.interactionLocked ? '宸茬姝簰鍔? : '鍙簰鍔?}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/poll/${poll.id}'),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('鎵撳紑'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.interactionLocked
                              ? null
                              : () => state.lockPollComments(poll.id),
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text('绂佹浜掑姩'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.interactionLocked
                              ? () => state.unlockPollComments(poll.id)
                              : null,
                          icon: const Icon(Icons.lock_open, size: 16),
                          label: const Text('瑙ｉ櫎绂佷簰'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.editRequested
                              ? () => state.approvePollEdit(poll)
                              : null,
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('閫氳繃缂栬緫鐢宠'),
                        ),
                        TextButton(
                          onPressed: () => state.deletePoll(poll.id),
                          child: const Text('鍒犻櫎'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdsAdminView extends ConsumerWidget {
  const _AdsAdminView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => showAdDialog(context, ref),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('鏂板缓/淇敼骞垮憡'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => showAnnouncementDialog(
            context,
            ref,
            state.startupAnnouncement,
            '杩涘叆 App 寮圭獥鍏憡',
          ),
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('璁剧疆寮圭獥鍏憡'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => showAnnouncementDialog(
            context,
            ref,
            state.marqueeAnnouncement,
            '涓婚〉璺戦┈鐏叕鍛?,
            marquee: true,
          ),
          icon: const Icon(Icons.view_stream_outlined),
          label: const Text('璁剧疆璺戦┈鐏叕鍛?),
        ),
        const SizedBox(height: 16),
        for (final ad in state.ads)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftPanel(
              child: ListTile(
                leading: Icon(
                  ad.enabled
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF2563EB),
                ),
                title: Text(ad.title),
                subtitle: Text(ad.body),
                trailing: Switch(
                  value: ad.enabled,
                  onChanged: (value) => state.updateAd(ad, enabled: value),
                ),
                onTap: () => showAdDialog(context, ref, ad: ad),
              ),
            ),
          ),
      ],
    );
  }
}

class _RolesAdminView extends ConsumerWidget {
  const _RolesAdminView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => showCreateTitleDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('娣诲姞澶磋'),
        ),
        const SizedBox(height: 12),
        for (final title in state.titles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SoftPanel(
              child: ExpansionTile(
                leading: StatusPill(
                  label: title.name,
                  color: title.color,
                  compact: true,
                ),
                title: Text(
                  '${title.userIds.length} 鍚嶇敤鎴?,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  title.permissions.map(permissionLabel).join('銆?).isEmpty
                      ? '鏆傛棤鏉冮檺'
                      : title.permissions.map(permissionLabel).join('銆?),
                ),
                trailing: title.id == 1
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => state.deleteTitle(title),
                      ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              showAssignUserToTitleDialog(context, ref, title),
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('娣诲姞鐢ㄦ埛'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showPermissionPackageDialog(context, ref, title),
                          icon: const Icon(
                            Icons.rule_folder_outlined,
                            size: 16,
                          ),
                          label: const Text('鏉冮檺鍖?),
                        ),
                      ],
                    ),
                  ),
                  for (final user in state.users.where(
                    (user) => title.userIds.contains(user.id),
                  ))
                    ListTile(
                      title: UserBadge(
                        name: user.nickname,
                        title: title.name,
                        titleColor: title.color,
                        uid: user.uid,
                        avatarUrl: user.avatarUrl,
                        onAvatarTap: () => context.push('/user/${user.uid}'),
                      ),
                      trailing: TextButton(
                        onPressed: () => state.removeTitleFromUser(user),
                        child: const Text('绉婚櫎'),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String permissionLabel(AppPermission permission) => switch (permission) {
  AppPermission.userMute => '绂佽█瑙ｇ',
  AppPermission.userRoleManage => '鏉冮檺鍒嗛厤',
  AppPermission.userDelete => '鍒犻櫎鐢ㄦ埛',
  AppPermission.pollDelete => '鍒犻櫎甯栧瓙',
  AppPermission.pollLock => '绂佹浜掑姩',
  AppPermission.pollUnlock => '瑙ｉ櫎绂佷簰',
  AppPermission.reportHandle => '涓炬姤澶勭悊',
  AppPermission.auditReview => '鍐呭瀹℃牳',
  AppPermission.adManage => '骞垮憡绠＄悊',
  AppPermission.announcementManage => '鍏憡绠＄悊',
  AppPermission.titleManage => '澶磋绠＄悊',
};

Future<void> showCreateTitleDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('娣诲姞澶磋'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: '澶磋鍚嶇О锛屼緥濡傦細鐗堜富'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('鍙栨秷'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(appStateProvider).addTitle(controller.text);
            Navigator.pop(dialogContext);
          },
          child: const Text('鍒涘缓'),
        ),
      ],
    ),
  );
}

Future<void> showAssignUserToTitleDialog(
  BuildContext context,
  WidgetRef ref,
  PermissionTitle title,
) async {
  final state = ref.read(appStateProvider);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('娣诲姞鐢ㄦ埛鍒?${title.name}'),
      children: [
        for (final user in state.users.where(
          (user) => !title.userIds.contains(user.id),
        ))
          SimpleDialogOption(
            onPressed: () {
              state.assignTitleToUser(title, user);
              Navigator.pop(dialogContext);
            },
            child: UserBadge(
              name: user.nickname,
              title: state.titleForUser(user)?.name,
              titleColor: state.titleForUser(user)?.color,
              uid: user.uid,
              avatarUrl: user.avatarUrl,
              onAvatarTap: () => context.push('/user/${user.uid}'),
            ),
          ),
      ],
    ),
  );
}

Future<void> showPermissionPackageDialog(
  BuildContext context,
  WidgetRef ref,
  PermissionTitle title,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(appStateProvider);
        return AlertDialog(
          title: Text('${title.name} 鏉冮檺鍖?),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final permission in AppPermission.values)
                    CheckboxListTile(
                      dense: true,
                      value: title.permissions.contains(permission),
                      onChanged: (value) => state.toggleTitlePermission(
                        title,
                        permission,
                        value ?? false,
                      ),
                      title: Text(permissionLabel(permission)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('瀹屾垚'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> showAdDialog(
  BuildContext context,
  WidgetRef ref, {
  HomeAd? ad,
}) async {
  final title = TextEditingController(text: ad?.title ?? '棣栭〉椤堕儴骞垮憡');
  final body = TextEditingController(text: ad?.body ?? '鏂扮殑绀惧尯娲诲姩姝ｅ湪杩涜');
  final image = TextEditingController(
    text: ad?.imageUrl ?? 'https://picsum.photos/seed/new-vote-ad/900/320',
  );
  var enabled = ad?.enabled ?? true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('骞垮憡璁剧疆'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '骞垮憡鏍囬'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                decoration: const InputDecoration(labelText: '骞垮憡璇存槑'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: image,
                decoration: const InputDecoration(labelText: '鍥剧墖鐩磋繛 URL'),
              ),
              SwitchListTile(
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
                title: const Text('鍚敤鏄剧ず'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('鍙栨秷'),
          ),
          FilledButton(
            onPressed: () {
              final state = ref.read(appStateProvider);
              if (ad == null) {
                state.addAd(HomeAd(title.text, body.text, image.text, enabled));
              } else {
                state.updateAd(
                  ad,
                  title: title.text,
                  body: body.text,
                  imageUrl: image.text,
                  enabled: enabled,
                );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('淇濆瓨'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showAnnouncementDialog(
  BuildContext context,
  WidgetRef ref,
  AppAnnouncement announcement,
  String title, {
  bool marquee = false,
}) async {
  final noticeTitle = TextEditingController(text: announcement.title);
  final body = TextEditingController(text: announcement.body);
  var enabled = announcement.enabled;
  var every = announcement.showEveryLaunch;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noticeTitle,
              decoration: const InputDecoration(labelText: '鍏憡鏍囬'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '鍏憡鍐呭'),
            ),
            SwitchListTile(
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
              title: const Text('寮€鍚?),
            ),
            if (!marquee)
              SwitchListTile(
                value: every,
                onChanged: (value) => setState(() => every = value),
                title: const Text('姣忔杩涘叆閮藉脊鍑?),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('鍙栨秷'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(appStateProvider)
                  .updateAnnouncement(
                    announcement,
                    title: noticeTitle.text,
                    body: body.text,
                    enabled: enabled,
                    showEveryLaunch: marquee
                        ? announcement.showEveryLaunch
                        : every,
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('淇濆瓨'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showRoleDialog(BuildContext context, WidgetRef ref) async {
  final title = TextEditingController();
  var userOps = true;
  var postOps = true;
  var audit = false;
  var ads = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('鍒涘缓鏂版潈闄愮敤鎴?),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '澶磋鍚嶇О'),
              ),
              CheckboxListTile(
                value: userOps,
                onChanged: (v) => setState(() => userOps = v ?? false),
                title: const Text('鐢ㄦ埛鎿嶄綔锛氱瑷€/瑙ｇ'),
              ),
              CheckboxListTile(
                value: postOps,
                onChanged: (v) => setState(() => postOps = v ?? false),
                title: const Text('甯栧瓙鎿嶄綔锛氬垹闄?绂佹浜掑姩'),
              ),
              CheckboxListTile(
                value: audit,
                onChanged: (v) => setState(() => audit = v ?? false),
                title: const Text('瀹℃牳鏉冮檺'),
              ),
              CheckboxListTile(
                value: ads,
                onChanged: (v) => setState(() => ads = v ?? false),
                title: const Text('骞垮憡鏉冮檺'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('鍙栨秷'),
          ),
          FilledButton(
            onPressed: () async {
              final name = title.text.trim();
              if (name.isEmpty) return;
              await ref
                  .read(appStateProvider)
                  .createCustomPermissionUser(
                    title: name,
                    userOps: userOps,
                    postOps: postOps,
                    audit: audit,
                    ads: ads,
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('鍒涘缓'),
          ),
        ],
      ),
    ),
  );
}
