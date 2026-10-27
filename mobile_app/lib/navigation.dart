part of 'main.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool showPublishDrop = true;

  bool handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          showPublishDrop) {
        setState(() => showPublishDrop = false);
      } else if (notification.direction == ScrollDirection.forward &&
          !showPublishDrop) {
        setState(() => showPublishDrop = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref
        .watch(appStateProvider)
        .notifications
        .where((item) => !item.isRead)
        .length;
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      '/search' => 1,
      '/messages' => 2,
      '/profile' || '/settings' || '/admin' => 3,
      _ => 0,
    };
    final isHome = location == '/home';
    final showDrop = isHome && showPublishDrop;
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!isHome) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/home');
          }
          return true;
        }
        return false;
      },
      child: PopScope(
        canPop: isHome,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !isHome) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          }
        },
        child: Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: handleScroll,
            child: widget.child,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: SizedBox(
              height: 54,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: _GooeyNavBar(
                      selectedIndex: index,
                      unreadMessages: unreadCount,
                      onHome: () => context.go('/home'),
                      onDiscover: () => context.go('/search'),
                      onMessages: () => context.go('/messages'),
                      onProfile: () => context.go('/profile'),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    bottom: showDrop ? 34 : 3,
                    child: IgnorePointer(
                      ignoring: !showDrop,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: showDrop ? 1 : 0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutBack,
                          scale: showDrop ? 1 : 0.56,
                          child: _PublishDropButton(
                            onPressed: () => context.push('/create'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishDropButton extends StatelessWidget {
  const _PublishDropButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x332563EB),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 29),
      ),
    );
  }
}

class _GooeyNavBar extends StatelessWidget {
  const _GooeyNavBar({
    required this.selectedIndex,
    required this.onHome,
    required this.onDiscover,
    required this.onMessages,
    required this.onProfile,
    this.unreadMessages = 0,
  });
  final int selectedIndex;
  final int unreadMessages;
  final VoidCallback onHome;
  final VoidCallback onDiscover;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const outerPadding = 8.0;
        final stackWidth = constraints.maxWidth - outerPadding * 2;
        final itemWidth = stackWidth / 4;
        final indicatorLeft = itemWidth * selectedIndex + 5;
        return Container(
          height: 48,
          padding: const EdgeInsets.fromLTRB(outerPadding, 5, outerPadding, 0),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
              top: BorderSide(
                color: dark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
              left: BorderSide(
                color: dark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
              right: BorderSide(
                color: dark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0x100F172A),
                blurRadius: 14,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                left: indicatorLeft,
                top: 6,
                width: itemWidth - 10,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x242563EB),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _BottomNavButton(
                      selected: selectedIndex == 0,
                      icon: Icons.dynamic_feed_outlined,
                      label: '棣栭〉',
                      onTap: onHome,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavButton(
                      selected: selectedIndex == 1,
                      icon: Icons.explore_outlined,
                      label: '鍙戠幇',
                      onTap: onDiscover,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavButton(
                      selected: selectedIndex == 2,
                      icon: Icons.notifications_outlined,
                      label: '娑堟伅',
                      badge: unreadMessages,
                      onTap: onMessages,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavButton(
                      selected: selectedIndex == 3,
                      icon: Icons.person_outline,
                      label: '鎴戠殑',
                      onTap: onProfile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    final foreground = selected
        ? Colors.white
        : (dark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B));
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: foreground, size: 19),
                if (badge > 0 && !selected)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
