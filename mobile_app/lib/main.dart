import 'dart:collection';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/zhande_refresh/zhande_refresh.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
const screenshotChannel = MethodChannel('anonymous_polls/screenshot');
bool screenshotShareHintEnabled = true;
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);
const appVersionName = '1.0.0';
const appBuildNumber = 4023;

const lockedInteractionMessage = '该内容已禁止互动';

bool isDarkUi(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color appPageBackground(BuildContext context) =>
    isDarkUi(context) ? const Color(0xFF09090B) : const Color(0xFFF7F8FA);
Color appPanelColor(BuildContext context) => isDarkUi(context)
    ? const Color(0xFF18181B).withValues(alpha: 0.86)
    : Colors.white.withValues(alpha: 0.76);
Color appPanelBorder(BuildContext context) => isDarkUi(context)
    ? Colors.white.withValues(alpha: 0.07)
    : Colors.black.withValues(alpha: 0.04);

List<String> extractTopicNames(String value) {
  final matches = RegExp(r'#([A-Za-z0-9_\-\u4e00-\u9fa5]{1,24})')
      .allMatches(value)
      .map((match) => match.group(1)?.trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
  return LinkedHashSet<String>.from(matches).take(5).toList();
}

void showAppToast(
  BuildContext context, {
  required String message,
  String title = '提示',
  IconData icon = Icons.info_outline_rounded,
  Color color = const Color(0xFF2563EB),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      duration: const Duration(milliseconds: 2200),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      height: 1.25,
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

class UserFacingException implements Exception {
  const UserFacingException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyErrorMessage(Object error) {
  if (error is UserFacingException) return error.message;
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '连接服务器超时，请检查后端是否已启动或稍后再试';
    }
    if (error.type == DioExceptionType.connectionError) {
      return '无法连接服务器，请检查网络或后端服务';
    }
    final status = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error.response?.data);
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return _translateServerMessage(serverMessage, status);
    }
    if (status == 400) return '输入内容不符合要求，请检查后再试';
    if (status == 401) return '账号或密码错误';
    if (status == 403) return '当前账号没有权限执行此操作';
    if (status == 404) return '请求的内容不存在';
    if (status != null && status >= 500) return '服务器暂时不可用，请稍后再试';
    return '网络连接异常，请检查网络后再试';
  }
  final text = error.toString().replaceFirst('Exception: ', '').trim();
  final lowerText = text.toLowerCase();
  if (lowerText.contains('timeout') || lowerText.contains('timed out')) {
    return '连接服务器超时，请检查后端是否已启动或稍后再试';
  }
  if (text.contains('DioException') || text.contains('RequestOptions')) {
    return '网络请求失败，请检查后端服务后再试';
  }
  return _translateServerMessage(text, null);
}

String? _extractServerMessage(Object? data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return _messageToText(error['message']);
    }
    if (data['message'] != null) return _messageToText(data['message']);
    if (data['error'] != null) return _messageToText(data['error']);
  }
  return null;
}

String _messageToText(Object value) {
  if (value is List) return value.map((item) => '$item').join('，');
  return '$value';
}

String _translateServerMessage(String message, int? status) {
  final text = message.trim();
  final lower = text.toLowerCase();
  if (lower.contains('invalid username') ||
      lower.contains('invalid password') ||
      lower.contains('unauthorized') ||
      lower.contains('old password is incorrect')) {
    return status == 400 ? '旧密码不正确' : '账号或密码错误';
  }
  if (lower.contains('account is not active')) return '账号不可用，请联系管理员';
  if (lower.contains('refresh token')) return '登录状态已失效，请重新登录';
  if (lower.contains('username must be longer') ||
      lower.contains('username must be shorter') ||
      lower.contains('username must match')) {
    return '账号必须为 5-24 位，只能包含字母、数字、下划线，不能是纯数字，也不能以符号开头';
  }
  if (lower.contains('password must be longer') ||
      lower.contains('newpassword must be longer')) {
    return '密码长度至少 6 位';
  }
  if (lower.contains('nickname must be longer') ||
      lower.contains('nickname must be shorter')) {
    return '昵称必须为 2-8 个字';
  }
  if (lower.contains('bad request')) return '输入内容不符合要求，请检查后再试';
  if (text.contains('璐﹀') || text.contains('鍗犵') || text.contains('占用')) {
    return '账号已被占用，请换一个账号';
  }
  if (text.isEmpty) return '操作失败，请稍后再试';
  return text;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  screenshotChannel.setMethodCallHandler((call) async {
    if (call.method == 'onScreenshot' && screenshotShareHintEnabled) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('这一票很有态度。分享给朋友，看看 TA 会站哪边。'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: '知道了', onPressed: () {}),
        ),
      );
    }
  });
  runApp(const ProviderScope(child: PollCommunityApp()));
}

final appStateProvider = ChangeNotifierProvider<AppState>((ref) => AppState());

const feedRefreshInterval = Duration(seconds: 5);
const detailRefreshInterval = Duration(seconds: 5);

bool _validUsername(String value) =>
    RegExp(r'^(?!\d+$)[A-Za-z0-9][A-Za-z0-9_]{4,23}$').hasMatch(value);

final routerProvider = Provider<GoRouter>((ref) {
  final appState = ref.read(appStateProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    redirect: (context, state) {
      final booting = appState.isBootstrapping;
      final onSplash = state.matchedLocation == '/splash';
      final loggingIn = state.matchedLocation == '/login';
      if (booting) return onSplash ? null : '/splash';
      if (onSplash) return appState.isLoggedIn ? '/home' : '/login';
      if (!appState.isLoggedIn && !loggingIn) return '/login';
      if (appState.isLoggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (_, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
        ],
      ),
      GoRoute(
        path: '/user/:uid',
        builder: (_, state) =>
            PublicProfileScreen(uid: int.parse(state.pathParameters['uid']!)),
      ),
      GoRoute(path: '/create', builder: (_, _) => const CreatePollScreen()),
      GoRoute(
        path: '/poll/:id',
        builder: (_, state) =>
            PollDetailScreen(pollId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/rules', builder: (_, _) => const RulesCenterScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/settings/edit-profile', builder: (_, _) => const EditProfileScreen()),
    ],
  );
});

class PollCommunityApp extends ConsumerWidget {
  const PollCommunityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    return MaterialApp.router(
      title: '站队',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: ref.watch(routerProvider),
      themeMode: appState.userSettings.darkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
          surface: const Color(0xFFF7F9FC),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF7F9FC),
          foregroundColor: Color(0xFF0F172A),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF0F172A),
          unselectedLabelColor: Color(0xFF64748B),
          labelStyle: TextStyle(fontWeight: FontWeight.w900),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
          indicatorSize: TabBarIndicatorSize.label,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool fabVisible = true;

  bool _handleScroll(ScrollNotification notification) {
    if (widget.location != '/home') return false;
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse && fabVisible) {
        setState(() => fabVisible = false);
      } else if (notification.direction == ScrollDirection.forward &&
          !fabVisible) {
        setState(() => fabVisible = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final hideChrome =
        location == '/settings' ||
        location == '/admin' ||
        location == '/create' ||
        location.startsWith('/poll/') ||
        location.startsWith('/user/');
    if (hideChrome) return widget.child;

    final index = switch (location) {
      '/search' => 1,
      '/messages' => 2,
      '/profile' => 3,
      _ => 0,
    };
    final dark = isDarkUi(context);
    final appState = ref.watch(appStateProvider);
    final unreadSystem = appState.notifications
        .where((item) => !item.isRead && !item.isInteraction)
        .length;
    final unreadInteraction = appState.notifications
        .where((item) => !item.isRead && item.isInteraction)
        .length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barColor = dark ? const Color(0xFF18181B) : Colors.white;
    final destinations = const [
      _ShellDestination('首页', Icons.home_rounded, Icons.home_outlined, '/home'),
      _ShellDestination(
        '发现',
        Icons.explore_rounded,
        Icons.explore_outlined,
        '/search',
      ),
      _ShellDestination(
        '消息',
        Icons.notifications_rounded,
        Icons.notifications_outlined,
        '/messages',
      ),
      _ShellDestination(
        '我的',
        Icons.person_rounded,
        Icons.person_outline_rounded,
        '/profile',
      ),
    ];

    return Scaffold(
      extendBody: false,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: widget.child,
      ),
      bottomNavigationBar: SizedBox(
        height: 70 + bottomInset,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(top: 30, child: ColoredBox(color: barColor)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: Container(
                height: 70 + bottomInset,
                padding: EdgeInsets.fromLTRB(8, 9, 8, bottomInset + 8),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.045),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withValues(alpha: 0.34)
                          : const Color(0x180F172A),
                      blurRadius: 26,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _ShellNavItem(
                          destination: destinations[i],
                          selected: index == i,
                          badgeCount: i == 2 ? unreadInteraction : 0,
                          showDot:
                              i == 2 &&
                              unreadInteraction == 0 &&
                              unreadSystem > 0,
                          onTap: () {
                            if (index != i) context.go(destinations[i].route);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (location == '/home')
              Positioned(
                bottom: bottomInset + 31,
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Center(
                    child: _CreatePollFab(
                      visible: fabVisible,
                      onTap: () => context.push('/create'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.selectedIcon, this.icon, this.route);

  final String label;
  final IconData selectedIcon;
  final IconData icon;
  final String route;
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.destination,
    required this.selected,
    this.badgeCount = 0,
    this.showDot = false,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final int badgeCount;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: color,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -9,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                else if (showDot)
                  Positioned(
                    right: -3,
                    top: -4,
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
            const SizedBox(height: 2),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePollFab extends StatelessWidget {
  const _CreatePollFab({required this.visible, required this.onTap});

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.05),
        duration: Duration(milliseconds: visible ? 360 : 260),
        curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
        child: AnimatedScale(
          scale: visible ? 1 : 0.78,
          duration: Duration(milliseconds: visible ? 360 : 240),
          curve: visible ? Curves.easeOutBack : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: Duration(milliseconds: visible ? 220 : 150),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -9,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: visible ? 36 : 12,
                      height: visible ? 14 : 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.30),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
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

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final storage = const FlutterSecureStorage();
  String? accessToken;
  String? refreshToken;

  Future<void> saveTokens(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    await storage.write(key: 'accessToken', value: access);
    await storage.write(key: 'refreshToken', value: refresh);
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }
}

class AppState extends ChangeNotifier {
  final api = ApiClient();
  final users = <DemoUser>[];

  late DemoUser currentUser = DemoUser(
    id: 0,
    uid: 0,
    username: '',
    nickname: '未登录用户',
    role: UserRole.user,
    bio: '',
  );
  bool isBootstrapping = true;
  bool isLoggedIn = false;
  final List<Poll> polls = [];
  final Map<String, List<Poll>> _feedCache = {};
  final Map<String, DateTime> _feedFetchedAt = {};
  final List<AppNotification> notifications = [];
  final List<ReportItem> reports = [];
  UserSettings userSettings = UserSettings();
  ProfileStats profileStats = const ProfileStats();
  final List<PermissionTitle> titles = [
    PermissionTitle(
      id: 1,
      name: '超级管理员',
      color: const Color(0xFF7C3AED),
      permissions: AppPermission.values.toSet(),
      userIds: {1},
    ),
    PermissionTitle(
      id: 2,
      name: '广告运营',
      color: const Color(0xFF0891B2),
      permissions: {AppPermission.adManage, AppPermission.announcementManage},
      userIds: {},
    ),
  ];
  final List<HomeAd> ads = [
    HomeAd(
      '默认推广',
      '参与匿名投票，看看大家真实选择',
      'https://picsum.photos/seed/vote-community/900/320',
      true,
    ),
    HomeAd(
      '新人活动',
      '发布第一条投票，收获你的第一批观点',
      'https://picsum.photos/seed/poll-event/900/320',
      true,
    ),
  ];
  final AppAnnouncement startupAnnouncement = AppAnnouncement(
    title: '欢迎来到站队',
    body: '这里可以匿名表达，也可以把热门观点分享给朋友。',
    enabled: true,
    showEveryLaunch: false,
  );
  final AppAnnouncement marqueeAnnouncement = AppAnnouncement(
    title: '社区公告',
    body: '文明讨论，恶意刷票和攻击内容会被处理。',
    enabled: true,
    showEveryLaunch: true,
  );
  bool startupAnnouncementShown = false;

  AppState() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadStartupAnnouncementSeenState();
    await api.storage.delete(key: 'permissionTitles');
    await api.storage.delete(key: 'pollInteractionOverrides');
    final access = await api.storage.read(key: 'accessToken');
    final refresh = await api.storage.read(key: 'refreshToken');
    if (access == null || refresh == null) {
      isBootstrapping = false;
      notifyListeners();
      return;
    }
    api.accessToken = access;
    api.refreshToken = refresh;
    try {
      isLoggedIn = true;
      await syncCurrentUser();
      await syncUserSettings();
      await syncProfileStats();
      await syncAdminRoles();
      await syncReports();
      await refreshPolls();
      await syncNotifications();
    } catch (_) {
      isLoggedIn = false;
      await api.clearTokens();
    }
    isBootstrapping = false;
    notifyListeners();
  }

  String get _startupAnnouncementSignature =>
      '${startupAnnouncement.title.trim()}|${startupAnnouncement.body.trim()}';

  Future<void> _loadStartupAnnouncementSeenState() async {
    final seen = await api.storage.read(
      key: 'startupAnnouncementSeenSignature',
    );
    startupAnnouncementShown = seen == _startupAnnouncementSignature;
  }

  Future<bool> shouldShowStartupAnnouncement() async {
    if (!startupAnnouncement.enabled) return false;
    if (startupAnnouncement.showEveryLaunch) return true;
    final seen = await api.storage.read(
      key: 'startupAnnouncementSeenSignature',
    );
    startupAnnouncementShown = seen == _startupAnnouncementSignature;
    return !startupAnnouncementShown;
  }

  Future<void> markStartupAnnouncementShown() async {
    startupAnnouncementShown = true;
    if (!startupAnnouncement.showEveryLaunch) {
      await api.storage.write(
        key: 'startupAnnouncementSeenSignature',
        value: _startupAnnouncementSignature,
      );
    }
    notifyListeners();
  }

  Future<void> syncCurrentUser() async {
    final response = await api.dio.get<Map<String, dynamic>>('/users/me');
    final user = DemoUser.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
    _upsertUser(user);
    currentUser = user;
  }

  Future<void> syncUserSettings() async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/users/me/settings',
      );
      userSettings = UserSettings.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
      screenshotShareHintEnabled = userSettings.screenshotShareHint;
    } catch (_) {}
  }

  Future<void> updateUserSettings(Map<String, dynamic> data) async {
    final response = await api.dio.patch<Map<String, dynamic>>(
      '/users/me/settings',
      data: data,
    );
    userSettings = UserSettings.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
    screenshotShareHintEnabled = userSettings.screenshotShareHint;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkForUpdate() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/content/update',
      queryParameters: {'platform': 'android', 'build': appBuildNumber},
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null || data['hasUpdate'] != true) return null;
    return data;
  }

  Future<void> submitFeedback({
    required String category,
    required String content,
    String? contact,
    required bool includeLogs,
  }) async {
    await api.dio.post(
      '/content/feedback',
      data: {
        'category': category,
        'content': content,
        'contact': contact ?? '',
        'includeLogs': includeLogs,
        if (includeLogs)
          'logs':
              'user=${currentUser.uid}; build=$appBuildNumber; version=$appVersionName',
        'appVersion': appVersionName,
        'buildNumber': appBuildNumber,
        'platform': 'android',
      },
    );
  }

  Future<Map<String, dynamic>> fetchUpdateConfig() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/admin/update-config',
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> saveUpdateConfig(Map<String, dynamic> data) async {
    await api.dio.post('/admin/update-config', data: data);
  }

  Future<List<Map<String, dynamic>>> fetchAdminFeedback() async {
    final response = await api.dio.get<Map<String, dynamic>>('/admin/feedback');
    final items = response.data?['data'] as List<dynamic>? ?? const [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<void> syncProfileStats({bool notify = false}) async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/users/me/stats',
      );
      profileStats = ProfileStats.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
      currentUser
        ..pollCount = profileStats.pollCount
        ..receivedLikes = profileStats.receivedLikes
        ..followingCount = profileStats.followingCount
        ..followerCount = profileStats.followerCount;
      if (notify) notifyListeners();
    } catch (_) {}
  }

  void _upsertUser(DemoUser user) {
    final index = users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      users.add(user);
    } else {
      users[index]
        ..username = user.username
        ..nickname = user.nickname
        ..role = user.role
        ..bio = user.bio
        ..avatarUrl = user.avatarUrl
        ..pollCount = user.pollCount
        ..receivedLikes = user.receivedLikes
        ..followingCount = user.followingCount
        ..followerCount = user.followerCount;
    }
  }

  Future<void> syncAdminRoles() async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>('/admin/roles');
      final items = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final item in items) {
        final id = item['id'] as int;
        if (titles.any((title) => title.id == id)) continue;
        titles.add(
          PermissionTitle.fromStored(
            item,
            fallbackColor: titleColorForIndex(titles.length),
          ),
        );
      }
    } catch (_) {
      // Normal users cannot read admin roles.
    }
  }

  Future<void> syncReports() async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/admin/reports',
      );
      final items = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      reports
        ..clear()
        ..addAll(items.map(ReportItem.fromJson));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> syncAdminUsers({String search = ''}) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: search.trim().isEmpty ? null : {'search': search.trim()},
    );
    final items = (response.data?['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    for (final item in items) {
      _upsertUser(DemoUser.fromJson(item));
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final loginName = username.trim();
    if (loginName.isEmpty) {
      throw const UserFacingException('请输入账号或用户 ID');
    }
    if (password.isEmpty) {
      throw const UserFacingException('请输入密码');
    }
    if (password.length < 6) {
      throw const UserFacingException('密码长度至少 6 位');
    }
    final response = await api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': loginName, 'password': password},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    currentUser = DemoUser.fromJson(data['user'] as Map<String, dynamic>);
    await api.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    isLoggedIn = true;
    await syncCurrentUser();
    await syncUserSettings();
    await syncProfileStats();
    await syncAdminRoles();
    await syncReports();
    await refreshPolls();
    await syncNotifications();
    notifyListeners();
  }

  Future<void> register(
    String username,
    String password,
    String nickname,
  ) async {
    final account = username.trim();
    final displayName = nickname.trim();
    if (!_validUsername(account)) {
      throw const UserFacingException(
        '账号必须为 5-24 位，只能包含字母、数字、下划线，不能是纯数字，也不能以符号开头',
      );
    }
    if (password.length < 6) {
      throw const UserFacingException('密码长度至少 6 位');
    }
    if (displayName.length < 2 || displayName.length > 8) {
      throw const UserFacingException('昵称必须为 2-8 个字');
    }
    final response = await api.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': account,
        'password': password,
        'nickname': displayName,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    currentUser = DemoUser.fromJson(data['user'] as Map<String, dynamic>);
    await api.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );
    isLoggedIn = true;
    await syncCurrentUser();
    await syncUserSettings();
    await syncProfileStats();
    await syncAdminRoles();
    await syncReports();
    await refreshPolls();
    await syncNotifications();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/auth/logout');
    } catch (_) {
      // Local logout should still work if the server is unavailable.
    }
    await api.clearTokens();
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> clearLocalSession() async {
    await api.clearTokens();
    isLoggedIn = false;
    notifyListeners();
  }

  Future<void> refreshPolls({String tab = 'recommended'}) async {
    final items = await fetchPollFeed(tab: tab);
    polls
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  List<Poll> cachedPollFeed(String tab) =>
      List.unmodifiable(_feedCache[tab] ?? const <Poll>[]);

  bool isFeedFresh(String tab, {Duration maxAge = const Duration(seconds: 8)}) {
    final fetchedAt = _feedFetchedAt[tab];
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < maxAge;
  }

  Future<List<Poll>> fetchPollFeed({
    String tab = 'recommended',
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls',
      queryParameters: {'tab': tab, 'page': page, 'pageSize': pageSize},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final result = items.map((item) => cachePoll(Poll.fromJson(item))).toList();
    if (page == 1) {
      _feedCache[tab] = result;
      _feedFetchedAt[tab] = DateTime.now();
    }
    return result;
  }

  Future<Poll> syncPollDetail(int pollId, {bool notify = true}) async {
    final response = await api.dio.get<Map<String, dynamic>>('/polls/$pollId');
    final poll = cachePoll(
      Poll.fromJson(response.data!['data'] as Map<String, dynamic>),
    );
    await syncPollComments(pollId, notify: false);
    if (notify) notifyListeners();
    return poll;
  }

  Future<void> syncNotifications() async {
    try {
      final response = await api.dio.get<Map<String, dynamic>>(
        '/notifications',
      );
      final items = (response.data!['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      notifications
        ..clear()
        ..addAll(items.map(AppNotification.fromJson));
    } catch (_) {
      // Keep current in-memory notifications if the server is unavailable.
    }
    notifyListeners();
  }

  Future<void> markNotificationsRead() async {
    for (final item in notifications) {
      item.isRead = true;
    }
    notifyListeners();
    try {
      await api.dio.patch('/notifications/read-all');
    } catch (_) {}
  }

  Future<void> markNotificationRead(AppNotification item) async {
    item.isRead = true;
    notifyListeners();
    if (item.id == null) return;
    try {
      await api.dio.patch('/notifications/${item.id}/read');
    } catch (_) {}
  }

  Future<void> createPoll({
    required String title,
    required String description,
    required List<String> options,
    required List<String> topicNames,
    required bool isAnonymous,
    required bool allowAnonymousVote,
    required bool allowAnonymousComment,
    required bool allowComment,
    required bool allowLike,
    required bool allowShare,
    List<String> imageUrls = const [],
    DateTime? endAt,
  }) async {
    if (currentUser.isCurrentlyMuted) {
      throw Exception('账号已被禁言，禁言期间不能发布投票');
    }
    await api.dio.post(
      '/polls',
      data: {
        'title': title,
        'description': description,
        'options': options,
        'topicNames': topicNames.take(5).toList(),
        if (topicNames.isNotEmpty) 'topicName': topicNames.first,
        'isAnonymous': isAnonymous,
        'allowAnonymousVote': allowAnonymousVote,
        'allowAnonymousComment': allowAnonymousComment,
        'allowComment': allowComment,
        'allowLike': allowLike,
        'allowShare': allowShare,
        'imageUrls': imageUrls.take(3).toList(),
        if (endAt != null) 'endAt': endAt.toIso8601String(),
      },
    );
    await refreshPolls();
    await syncProfileStats();
    await syncNotifications();
  }

  Future<void> vote(int pollId, int optionId, {bool anonymous = false}) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('互动已关闭', '该内容已禁止互动', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (poll.myOptionId != null ||
        poll.votedUserIds.contains(currentUser.id) ||
        poll.hasEnded) {
      return;
    }
    final option = poll.options.firstWhere((item) => item.id == optionId);
    option.voteCount += 1;
    poll.votedUserIds.add(currentUser.id);
    poll.myOptionId = optionId;
    notifyListeners();
    await api.dio.post(
      '/polls/$pollId/vote',
      data: {'optionId': optionId, 'isAnonymous': anonymous},
    );
    unawaited(syncPollDetail(pollId, notify: false).catchError((_) => poll));
    await syncProfileStats(notify: true);
    unawaited(syncNotifications());
    notifyListeners();
  }

  Future<void> addComment(
    int pollId,
    String content, {
    bool anonymous = false,
  }) async {
    if (currentUser.isCurrentlyMuted) {
      throw Exception('账号已被禁言，禁言期间不能评论');
    }
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('互动已关闭', '该内容已禁止互动', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (!poll.allowComment || content.trim().isEmpty) return;
    final response = await api.dio.post<Map<String, dynamic>>(
      '/polls/$pollId/comments',
      data: {'content': content.trim(), 'isAnonymous': anonymous},
    );
    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      poll.comments.insert(0, PollComment.fromJson(data));
      poll.commentCount += 1;
      notifyListeners();
    }
    unawaited(syncPollComments(pollId).catchError((_) {}));
    unawaited(syncNotifications());
    notifyListeners();
  }

  Future<void> syncPollComments(int pollId, {bool notify = true}) async {
    final poll = maybePollById(pollId);
    if (poll == null) return;
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls/$pollId/comments',
    );
    final data = response.data!['data'];
    final rawItems = data is Map<String, dynamic> ? data['items'] : data;
    final items = (rawItems as List<dynamic>).cast<Map<String, dynamic>>();
    poll.comments
      ..clear()
      ..addAll(items.map(PollComment.fromJson));
    poll.commentCount = poll.comments.length;
    if (notify) notifyListeners();
  }

  Future<void> reactComment(int pollId, int commentId, String reaction) async {
    final poll = maybePollById(pollId);
    PollComment? comment;
    if (poll != null) {
      for (final item in poll.comments) {
        if (item.id == commentId) {
          comment = item;
          break;
        }
      }
    }
    final oldReaction = comment?.myReaction;
    final oldLikeCount = comment?.likeCount ?? 0;
    final oldDislikeCount = comment?.dislikeCount ?? 0;
    if (comment != null) {
      if (reaction == 'LIKE') {
        if (comment.myReaction == 'LIKE') {
          comment.myReaction = null;
          comment.likeCount = (comment.likeCount - 1).clamp(0, 1 << 31);
        } else {
          if (comment.myReaction == 'DISLIKE') {
            comment.dislikeCount = (comment.dislikeCount - 1).clamp(0, 1 << 31);
          }
          comment.myReaction = 'LIKE';
          comment.likeCount += 1;
        }
      } else {
        if (comment.myReaction == 'DISLIKE') {
          comment.myReaction = null;
          comment.dislikeCount = (comment.dislikeCount - 1).clamp(0, 1 << 31);
        } else {
          if (comment.myReaction == 'LIKE') {
            comment.likeCount = (comment.likeCount - 1).clamp(0, 1 << 31);
          }
          comment.myReaction = 'DISLIKE';
          comment.dislikeCount += 1;
        }
      }
      notifyListeners();
    }
    try {
      await api.dio.post(
        '/comments/$commentId/${reaction == 'LIKE' ? 'like' : 'dislike'}',
      );
      unawaited(syncPollComments(pollId).catchError((_) {}));
      unawaited(syncNotifications());
    } catch (_) {
      if (comment != null) {
        comment
          ..myReaction = oldReaction
          ..likeCount = oldLikeCount
          ..dislikeCount = oldDislikeCount;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> likePoll(int pollId) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('互动已关闭', '该内容已禁止互动', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    final oldLiked = poll.isLiked;
    final oldDisliked = poll.isDisliked;
    final oldLikeCount = poll.likeCount;
    final oldDislikeCount = poll.dislikeCount;
    if (poll.isLiked) {
      poll.isLiked = false;
      poll.likeCount = (poll.likeCount - 1).clamp(0, 1 << 31);
    } else {
      poll.isLiked = true;
      poll.likeCount += 1;
      if (poll.isDisliked) {
        poll.isDisliked = false;
        poll.dislikeCount = (poll.dislikeCount - 1).clamp(0, 1 << 31);
      }
    }
    notifyListeners();
    try {
      final response = poll.isLiked
          ? await api.dio.post<Map<String, dynamic>>('/polls/$pollId/like')
          : await api.dio.delete<Map<String, dynamic>>('/polls/$pollId/like');
      final data = response.data?['data'] as Map<String, dynamic>?;
      poll.likeCount = data?['likeCount'] as int? ?? poll.likeCount;
      poll.dislikeCount = data?['dislikeCount'] as int? ?? poll.dislikeCount;
    } catch (_) {
      poll
        ..isLiked = oldLiked
        ..isDisliked = oldDisliked
        ..likeCount = oldLikeCount
        ..dislikeCount = oldDislikeCount;
      notifyListeners();
      rethrow;
    }
    await syncProfileStats(notify: true);
    unawaited(syncNotifications());
    notifyListeners();
  }

  Future<void> favoritePoll(int pollId) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('互动已关闭', '该内容已禁止互动', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    final oldFavorited = poll.isFavorited;
    final oldFavoriteCount = poll.favoriteCount;
    if (poll.isFavorited) {
      poll.isFavorited = false;
      poll.favoriteCount = (poll.favoriteCount - 1).clamp(0, 1 << 31);
    } else {
      poll.isFavorited = true;
      poll.favoriteCount += 1;
    }
    notifyListeners();
    try {
      final response = poll.isFavorited
          ? await api.dio.post<Map<String, dynamic>>('/polls/$pollId/favorite')
          : await api.dio.delete<Map<String, dynamic>>(
              '/polls/$pollId/favorite',
            );
      final data = response.data?['data'] as Map<String, dynamic>?;
      poll.favoriteCount = data?['favoriteCount'] as int? ?? poll.favoriteCount;
    } catch (_) {
      poll
        ..isFavorited = oldFavorited
        ..favoriteCount = oldFavoriteCount;
      notifyListeners();
      rethrow;
    }
    await syncProfileStats(notify: true);
    unawaited(syncNotifications());
    notifyListeners();
  }

  Future<void> dislikePoll(int pollId) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('互动已关闭', '该内容已禁止互动', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    final oldLiked = poll.isLiked;
    final oldDisliked = poll.isDisliked;
    final oldLikeCount = poll.likeCount;
    final oldDislikeCount = poll.dislikeCount;
    if (poll.isDisliked) {
      poll.isDisliked = false;
      poll.dislikeCount = (poll.dislikeCount - 1).clamp(0, 1 << 31);
    } else {
      poll.isDisliked = true;
      poll.dislikeCount += 1;
      if (poll.isLiked) {
        poll.isLiked = false;
        poll.likeCount = (poll.likeCount - 1).clamp(0, 1 << 31);
      }
    }
    notifyListeners();
    try {
      final response = poll.isDisliked
          ? await api.dio.post<Map<String, dynamic>>('/polls/$pollId/dislike')
          : await api.dio.delete<Map<String, dynamic>>(
              '/polls/$pollId/dislike',
            );
      final data = response.data?['data'] as Map<String, dynamic>?;
      poll.likeCount = data?['likeCount'] as int? ?? poll.likeCount;
      poll.dislikeCount = data?['dislikeCount'] as int? ?? poll.dislikeCount;
    } catch (_) {
      poll
        ..isLiked = oldLiked
        ..isDisliked = oldDisliked
        ..likeCount = oldLikeCount
        ..dislikeCount = oldDislikeCount;
      notifyListeners();
      rethrow;
    }
    unawaited(syncNotifications());
    notifyListeners();
  }

  Future<void> deletePoll(int pollId) async {
    final poll = pollById(pollId);
    if (!canManagePoll(poll)) return;
    await api.dio.patch(
      '/admin/polls/$pollId/moderation',
      data: {'status': 'DELETED', 'result': '该投票已被删除'},
    );
    polls.removeWhere((item) => item.id == pollId);
    await syncNotifications();
    notifyListeners();
  }

  Future<void> lockPollComments(int pollId) async {
    final poll = pollById(pollId);
    if (!canManagePoll(poll)) return;
    await api.dio.patch(
      '/admin/polls/$pollId/moderation',
      data: {'status': 'COMMENT_LOCKED', 'result': '该投票已被禁止互动'},
    );
    poll.allowComment = false;
    poll.allowLike = false;
    poll.allowShare = false;
    await syncNotifications();
    notifyListeners();
  }

  bool canManagePoll(Poll poll) {
    return currentUser.canAdmin || poll.author.id == currentUser.id;
  }

  Future<void> report(String targetType, int targetId, String reason) async {
    final response = await api.dio.post<Map<String, dynamic>>(
      '/reports',
      data: {'targetType': targetType, 'targetId': targetId, 'reason': reason},
    );
    final created = response.data!['data'] as Map<String, dynamic>;
    reports.insert(
      0,
      ReportItem.fromJson({
        ...created,
        'reporter': {'uid': currentUser.uid, 'nickname': currentUser.nickname},
      }),
    );
    await syncNotifications();
    notifyListeners();
  }

  void resolveReport(int id) {
    reports.firstWhere((report) => report.id == id).status = 'RESOLVED';
    notifyListeners();
  }

  Future<void> updateAvatar(String filePath) async {
    final url = await uploadImage(filePath);
    await api.dio.patch('/users/me', data: {'avatarUrl': url});
    currentUser.avatarUrl = url;
    notifications.insert(
      0,
      AppNotification('头像已更新', '新的头像已经保存到你的个人资料', DateTime.now()),
    );
    notifyListeners();
  }

  Future<String> uploadImage(String filePath) async {
    final filename = filePath.split(RegExp(r'[\\/]')).last;
    final response = await api.dio.post<Map<String, dynamic>>(
      '/uploads/image',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      }),
    );
    final upload = response.data!['data'] as Map<String, dynamic>;
    final rawUrl = upload['url'] as String;
    if (rawUrl.startsWith('http')) return rawUrl;
    return '$apiBaseUrl$rawUrl';
  }

  Future<void> updateProfile(String nickname, String bio) async {
    return updateAccountProfile(
      username: currentUser.username,
      nickname: nickname,
      bio: bio,
    );
  }

  Future<void> updateAccountProfile({
    required String username,
    required String nickname,
    required String bio,
  }) async {
    final nextUsername = username.trim();
    final nextNickname = nickname.trim().isEmpty
        ? currentUser.nickname
        : nickname.trim();
    final nextBio = bio.trim();
    if (!_validUsername(nextUsername)) {
      throw Exception('账号至少 5 位，不能纯数字，不能以符号开头，只能包含字母、数字、下划线');
    }
    if (nextNickname.length < 2 || nextNickname.length > 8) {
      throw Exception('昵称必须为 2-8 个字');
    }
    await api.dio.patch(
      '/users/me',
      data: {
        'username': nextUsername,
        'nickname': nextNickname,
        'bio': nextBio,
      },
    );
    currentUser.username = nextUsername;
    currentUser.nickname = nextNickname;
    currentUser.bio = nextBio;
    notifyListeners();
  }

  Future<void> createHousekeeperRole() async {
    await api.dio.post(
      '/admin/roles',
      data: {
        'name': '管家',
        'badge': '社区管家',
        'badgeColor': '#DCFCE7',
        'permissions': [
          'AD_MANAGE',
          'ANNOUNCEMENT_MANAGE',
          'USER_BAN',
          'COMMENT_MODERATE',
        ],
      },
    );
    notifications.insert(
      0,
      AppNotification('权限头衔已创建', '已创建“管家”头衔和对应管理权限', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> createHomeAd() async {
    await api.dio.post(
      '/admin/ads',
      data: {
        'key': 'home_top',
        'title': '首页顶部广告位',
        'body': '用于活动、公告和商业合作展示',
        'enabled': true,
        'sortOrder': 1,
      },
    );
    notifications.insert(
      0,
      AppNotification('广告位已保存', '首页顶部广告配置已经写入后台', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> adminUserAction(
    DemoUser user,
    String action, {
    int? muteDays,
  }) async {
    final actor = currentUser;
    if (user.id == actor.id) return;
    if (user.isCreatorAdmin) return;
    final protectedUser = user.canAdmin || user.showBadge;
    if (action == 'delete' && (!actor.isCreatorAdmin || protectedUser)) return;
    if (action == 'role' && !actor.isCreatorAdmin) return;
    if (action == 'ban') {
      await api.dio.patch(
        '/admin/users/${user.id}/status',
        data: {
          'status': 'BANNED',
          ...?(muteDays == null ? null : {'muteDays': muteDays}),
        },
      );
      user.muted = true;
      user.mutedUntil = muteDays == null
          ? null
          : DateTime.now().add(Duration(days: muteDays));
      notifications.insert(
        0,
        AppNotification(
          '用户已禁言',
          '${user.nickname} ${muteDays == null ? '已被永久禁言' : '已被禁言 $muteDays 天'}',
          DateTime.now(),
        ),
      );
    } else if (action == 'unban') {
      await api.dio.patch(
        '/admin/users/${user.id}/status',
        data: {'status': 'ACTIVE'},
      );
      user.muted = false;
      user.mutedUntil = null;
      notifications.insert(
        0,
        AppNotification('用户已解禁', '${user.nickname} 已恢复发布和评论权限', DateTime.now()),
      );
    } else if (action == 'delete') {
      await api.dio.delete('/admin/users/${user.id}');
      users.removeWhere((item) => item.id == user.id);
      notifications.insert(
        0,
        AppNotification('用户已删除', '${user.nickname} 已被标记删除', DateTime.now()),
      );
    } else if (action == 'role') {
      await api.dio.patch(
        '/admin/users/${user.id}/role',
        data: {'role': 'ADMIN', 'badge': '管理员'},
      );
      user.role = UserRole.admin;
      notifications.insert(
        0,
        AppNotification('权限已提升', '${user.nickname} 已授予管理员权限', DateTime.now()),
      );
    }
    notifyListeners();
  }

  Future<void> handleReport(ReportItem report, String action) async {
    if (report.targetType == 'COMMENT') {
      if (action == 'delete') {
        await deleteCommentById(report.targetId);
        report.status = 'RESOLVED';
      } else {
        report.status = 'REJECTED';
      }
    } else if (action == 'delete') {
      await deletePoll(report.targetId);
      report.status = 'RESOLVED';
    } else if (action == 'lock') {
      await lockPollComments(report.targetId);
      report.status = 'RESOLVED';
    } else {
      report.status = 'REJECTED';
    }
    try {
      await api.dio.patch(
        '/admin/reports/${report.id}',
        data: {
          'status': action == 'reject' ? 'REJECTED' : 'RESOLVED',
          'result': action == 'reject' ? '举报已驳回，内容保持正常显示' : '举报已受理，内容已处理',
        },
      );
    } catch (_) {}
    await syncReports();
    await syncNotifications();
    notifyListeners();
  }

  Future<void> createCustomPermissionUser({
    required String title,
    required bool userOps,
    required bool postOps,
    required bool audit,
    required bool ads,
  }) async {
    final permissions = <String>[
      if (userOps) 'USER_BAN',
      if (postOps) 'POLL_MODERATE',
      if (postOps) 'COMMENT_MODERATE',
      if (audit) 'REPORT_MANAGE',
      if (ads) 'AD_MANAGE',
    ];
    await api.dio.post(
      '/admin/roles',
      data: {
        'name': title,
        'badge': title,
        'badgeColor': '#E0F2FE',
        'permissions': permissions,
      },
    );
    notifications.insert(
      0,
      AppNotification('权限用户已创建', '已创建“$title”并保存权限包', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> saveAd({
    required String key,
    required String title,
    required String body,
    required bool enabled,
  }) async {
    await api.dio.post(
      '/admin/ads',
      data: {
        'key': key,
        'title': title,
        'body': body,
        'enabled': enabled,
        'sortOrder': 1,
      },
    );
    notifications.insert(
      0,
      AppNotification('广告已保存', '$title 已更新到广告位', DateTime.now()),
    );
    notifyListeners();
  }

  PermissionTitle? titleForUser(DemoUser user) {
    for (final title in titles) {
      if (title.userIds.contains(user.id)) return title;
    }
    if (user.role == UserRole.superAdmin) {
      return titles.first;
    }
    if (user.role == UserRole.admin) {
      return PermissionTitle(
        id: 900,
        name: '管理员',
        color: const Color(0xFF2563EB),
        permissions: {
          AppPermission.userMute,
          AppPermission.reportHandle,
          AppPermission.auditReview,
          AppPermission.pollLock,
        },
        userIds: {user.id},
      );
    }
    if (user.role == UserRole.adManager) {
      return PermissionTitle(
        id: 901,
        name: '广告管理',
        color: const Color(0xFF0891B2),
        permissions: {AppPermission.adManage, AppPermission.announcementManage},
        userIds: {user.id},
      );
    }
    if (user.role == UserRole.reviewer) {
      return PermissionTitle(
        id: 902,
        name: '审核员',
        color: const Color(0xFF059669),
        permissions: {AppPermission.auditReview, AppPermission.reportHandle},
        userIds: {user.id},
      );
    }
    return null;
  }

  bool hasPermission(AppPermission permission) {
    if (currentUser.isCreatorAdmin) return true;
    return titleForUser(currentUser)?.permissions.contains(permission) ?? false;
  }

  List<DemoUser> searchUsersByUid(String query) {
    final value = query.trim();
    if (value.isEmpty) return users;
    return users.where((user) => user.uid.toString().contains(value)).toList();
  }

  void assignTitleToUser(PermissionTitle title, DemoUser user) {
    if (!currentUser.isCreatorAdmin) return;
    if (user.isCreatorAdmin) return;
    for (final item in titles) {
      item.userIds.remove(user.id);
    }
    title.userIds.add(user.id);
    user.role = UserRole.admin;
    _syncAssignTitle(title, user);
    notifyListeners();
  }

  void removeTitleFromUser(DemoUser user) {
    if (!currentUser.isCreatorAdmin) return;
    if (user.isCreatorAdmin) return;
    for (final item in titles) {
      item.userIds.remove(user.id);
    }
    user.role = UserRole.user;
    _syncRemoveTitle(user);
    notifyListeners();
  }

  void addTitle(String name) {
    if (!currentUser.isCreatorAdmin || name.trim().isEmpty) return;
    final title = PermissionTitle(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name.trim(),
      color: titleColorForIndex(titles.length),
      permissions: {},
      userIds: {},
    );
    titles.add(title);
    _syncCreateTitle(title);
    notifyListeners();
  }

  void deleteTitle(PermissionTitle title) {
    if (!currentUser.isCreatorAdmin || title.id == 1) return;
    for (final user in users) {
      if (title.userIds.contains(user.id)) user.role = UserRole.user;
    }
    titles.removeWhere((item) => item.id == title.id);
    _syncDeleteTitle(title.id);
    notifyListeners();
  }

  void toggleTitlePermission(
    PermissionTitle title,
    AppPermission permission,
    bool enabled,
  ) {
    if (!currentUser.isCreatorAdmin) return;
    enabled
        ? title.permissions.add(permission)
        : title.permissions.remove(permission);
    _syncUpdateTitle(title);
    notifyListeners();
  }

  Future<void> _syncCreateTitle(PermissionTitle title) async {
    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/admin/roles',
        data: {
          'name': title.name,
          'badge': title.name,
          'badgeColor': title.hexColor,
          'permissions': <String>[],
        },
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        title.id = data['id'] as int? ?? title.id;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _syncUpdateTitle(PermissionTitle title) async {
    try {
      await api.dio.patch(
        '/admin/roles/${title.id}',
        data: {
          'name': title.name,
          'badge': title.name,
          'badgeColor': title.hexColor,
          'permissions': title.permissions.map(_serverPermissionName).toList(),
        },
      );
    } catch (_) {}
  }

  Future<void> _syncDeleteTitle(int titleId) async {
    try {
      await api.dio.delete('/admin/roles/$titleId');
    } catch (_) {}
  }

  Future<void> _syncAssignTitle(PermissionTitle title, DemoUser user) async {
    try {
      await api.dio.patch(
        '/admin/users/${user.id}/role',
        data: {'role': 'ADMIN', 'customRoleId': title.id, 'badge': title.name},
      );
    } catch (_) {}
  }

  Future<void> _syncRemoveTitle(DemoUser user) async {
    try {
      await api.dio.patch(
        '/admin/users/${user.id}/role',
        data: {'role': 'USER', 'customRoleId': null, 'badge': null},
      );
    } catch (_) {}
  }

  Future<void> unlockPollComments(int pollId) async {
    final poll = pollById(pollId);
    if (!canManagePoll(poll) && !hasPermission(AppPermission.pollUnlock)) {
      return;
    }
    try {
      await api.dio.patch(
        '/admin/polls/$pollId/moderation',
        data: {'status': 'PUBLISHED', 'result': '该投票已解除禁止互动'},
      );
    } catch (_) {}
    poll.allowComment = true;
    poll.allowLike = true;
    poll.allowShare = true;
    await syncNotifications();
    notifyListeners();
  }

  void updateAd(
    HomeAd ad, {
    String? title,
    String? body,
    String? imageUrl,
    bool? enabled,
  }) {
    if (!hasPermission(AppPermission.adManage)) return;
    ad.title = title ?? ad.title;
    ad.body = body ?? ad.body;
    ad.imageUrl = imageUrl ?? ad.imageUrl;
    ad.enabled = enabled ?? ad.enabled;
    notifyListeners();
  }

  void requestPollEdit(Poll poll) {
    if (poll.author.id != currentUser.id) return;
    poll.editRequested = true;
    notifications.insert(
      0,
      AppNotification('编辑申请已提交', '管理员审核通过后可以编辑“${poll.title}”', DateTime.now()),
    );
    notifyListeners();
  }

  void approvePollEdit(Poll poll) {
    poll.editApproved = true;
    poll.editRequested = false;
    notifications.insert(
      0,
      AppNotification(
        '编辑申请已通过',
        '“${poll.title}”现在可以由发布者编辑标题和描述',
        DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void editPollContent(Poll poll, String title, String description) {
    if (poll.author.id != currentUser.id || !poll.editApproved) return;
    poll.title = title.trim().isEmpty ? poll.title : title.trim();
    poll.description = description.trim();
    poll.editApproved = false;
    notifications.insert(
      0,
      AppNotification('帖子已更新', '“${poll.title}”的标题和描述已更新', DateTime.now()),
    );
    notifyListeners();
  }

  void addAd(HomeAd ad) {
    if (!hasPermission(AppPermission.adManage)) return;
    ads.add(ad);
    notifyListeners();
  }

  void updateAnnouncement(
    AppAnnouncement item, {
    String? title,
    String? body,
    bool? enabled,
    bool? showEveryLaunch,
  }) {
    if (!hasPermission(AppPermission.announcementManage)) return;
    item.title = title ?? item.title;
    item.body = body ?? item.body;
    item.enabled = enabled ?? item.enabled;
    item.showEveryLaunch = showEveryLaunch ?? item.showEveryLaunch;
    notifyListeners();
  }

  Poll pollById(int id) => polls.firstWhere((poll) => poll.id == id);
  Poll? maybePollById(int id) {
    for (final poll in polls) {
      if (poll.id == id) return poll;
    }
    return null;
  }

  Poll cachePoll(Poll poll, {bool? liked, bool? favorited, bool? voted}) {
    if (liked != null) poll.isLiked = liked;
    if (favorited != null) poll.isFavorited = favorited;
    if (voted == true) poll.votedUserIds.add(currentUser.id);
    final existing = maybePollById(poll.id);
    if (existing == null) {
      polls.insert(0, poll);
      return poll;
    }
    existing
      ..shareCode = poll.shareCode
      ..title = poll.title
      ..description = poll.description
      ..allowComment = poll.allowComment
      ..allowLike = poll.allowLike
      ..allowShare = poll.allowShare
      ..viewCount = poll.viewCount
      ..likeCount = poll.likeCount
      ..dislikeCount = poll.dislikeCount
      ..favoriteCount = poll.favoriteCount
      ..commentCount = poll.commentCount
      ..myOptionId = poll.myOptionId
      ..isLiked =
          liked ?? (poll.viewerStateKnown ? poll.isLiked : existing.isLiked)
      ..isDisliked = poll.viewerStateKnown
          ? poll.isDisliked
          : existing.isDisliked
      ..isFavorited =
          favorited ??
          (poll.viewerStateKnown ? poll.isFavorited : existing.isFavorited)
      ..viewerStateKnown = existing.viewerStateKnown || poll.viewerStateKnown;
    existing.imageUrls
      ..clear()
      ..addAll(poll.imageUrls);
    existing.options
      ..clear()
      ..addAll(poll.options);
    if (poll.comments.isNotEmpty || poll.commentCount == 0) {
      existing.comments
        ..clear()
        ..addAll(poll.comments);
    }
    if (voted == true) existing.votedUserIds.add(currentUser.id);
    return existing;
  }

  Future<void> sharePoll(BuildContext context, Poll poll) async {
    if (poll.interactionLocked || !poll.allowShare) {
      showAppToast(
        context,
        title: '\u5206\u4EAB\u4E0D\u53EF\u7528',
        message: lockedInteractionMessage,
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFDC2626),
      );
      return;
    }
    final image = await _buildSharePoster(poll);
    final text =
        '\u6211\u5728\u7AD9\u961F\u53D1\u73B0\u4E00\u4E2A\u5F88\u6709\u4E89\u8BAE\u611F\u7684\u6295\u7968\uFF1A${poll.title}\n\n\u6253\u5F00\u7AD9\u961F App\uFF0C\u641C\u7D22\u5B89\u5168\u7801 ${poll.safeShareCode} \u53C2\u4E0E\u8BA8\u8BBA\u3002';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '\u7AD9\u961F\u6295\u7968\uFF1A${poll.title}',
        files: [
          XFile.fromData(
            image,
            mimeType: 'image/png',
            name: 'zhandui-${poll.safeShareCode}.png',
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildSharePoster(Poll poll) async {
    const width = 1080.0;
    const height = 1440.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    final total = poll.voteCount == 0 ? 1 : poll.voteCount;
    final sorted = [...poll.options]
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    final leader = sorted.isEmpty ? null : sorted.first;
    final runner = sorted.length > 1 ? sorted[1] : null;
    final leaderPercent = leader == null
        ? 0
        : (leader.voteCount / total * 100).round();
    final comebackGap = leader == null || runner == null
        ? 0
        : (leader.voteCount - runner.voteCount + 1).clamp(0, 9999);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF080B16), Color(0xFF111827), Color(0xFF12133A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, width, height)),
    );
    canvas.drawCircle(
      const Offset(900, 150),
      235,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.24),
    );
    canvas.drawCircle(
      const Offset(80, 1150),
      280,
      Paint()..color = const Color(0xFFDB2777).withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      const Offset(250, 1290),
      210,
      Paint()..color = const Color(0xFF7C3AED).withValues(alpha: 0.16),
    );

    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(64, 72, width - 128, height - 144),
      const Radius.circular(46),
    );
    canvas.drawRRect(
      card,
      Paint()..color = const Color(0xFF1F2937).withValues(alpha: 0.78),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.20),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 126, 238, 56),
        const Radius.circular(999),
      ),
      Paint()..color = const Color(0xFFFFEDD5),
    );
    _drawPosterText(
      canvas,
      '\u70ED\u8BAE\u7AD9\u961F',
      const Offset(150, 140),
      maxWidth: 180,
      fontSize: 25,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFEA580C),
    );
    _drawPosterText(
      canvas,
      '\u7AD9\u961F',
      const Offset(780, 132),
      maxWidth: 160,
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );

    _drawPosterText(
      canvas,
      poll.title,
      const Offset(112, 238),
      maxWidth: 856,
      maxLines: 3,
      fontSize: 58,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    );
    _drawPosterText(
      canvas,
      '\u522B\u5148\u7AD9\u961F\uFF0C\u5148\u770B\u6570\u636E\uFF1A\u4F60\u4F1A\u8DDF\u5927\u591A\u6570\u4E00\u8D77\u5417\uFF1F',
      const Offset(112, 520),
      maxWidth: 856,
      maxLines: 2,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFE5E7EB),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 588, 856, 132),
        const Radius.circular(30),
      ),
      Paint()..color = const Color(0xFF111827).withValues(alpha: 0.62),
    );
    final stats = [
      (
        '${poll.voteCount}',
        '\u4EBA\u5DF2\u7AD9\u961F',
        const Color(0xFF93C5FD),
      ),
      (
        '$leaderPercent%',
        '\u9886\u5148\u65B9\u6B63\u5728\u538B\u5236',
        const Color(0xFFFACC15),
      ),
      ('+$comebackGap', '\u53CD\u8D85\u8FD8\u5DEE', const Color(0xFFF472B6)),
    ];
    for (var i = 0; i < stats.length; i++) {
      final x = 150.0 + i * 280.0;
      _drawPosterText(
        canvas,
        stats[i].$1,
        Offset(x, 620),
        maxWidth: 190,
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: stats[i].$3,
      );
      _drawPosterText(
        canvas,
        stats[i].$2,
        Offset(x, 674),
        maxWidth: 220,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFE5E7EB),
      );
    }

    var y = 800.0;
    for (final option in poll.options.take(4)) {
      final percent = option.voteCount / total;
      final optionRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(112, y, 856, 92),
        const Radius.circular(24),
      );
      canvas.drawRRect(
        optionRect,
        Paint()..color = const Color(0xFF374151).withValues(alpha: 0.72),
      );
      canvas.save();
      canvas.clipRRect(optionRect);
      canvas.drawRect(
        Rect.fromLTWH(112, y, (856 * percent).clamp(10, 856), 92),
        Paint()
          ..shader = LinearGradient(
            colors: [option.color, option.color.withValues(alpha: 0.72)],
          ).createShader(Rect.fromLTWH(112, y, 856, 92)),
      );
      canvas.restore();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(112, y, 34, 92),
          const Radius.circular(18),
        ),
        Paint()..color = option.color,
      );
      _drawPosterText(
        canvas,
        option.text,
        Offset(148, y + 28),
        maxWidth: 560,
        maxLines: 1,
        fontSize: 29,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      );
      _drawPosterText(
        canvas,
        '${(percent * 100).round()}%',
        Offset(810, y + 28),
        maxWidth: 120,
        maxLines: 1,
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        textAlign: TextAlign.right,
      );
      y += 112;
    }
    if (poll.options.length > 4) {
      _drawPosterText(
        canvas,
        '\u8FD8\u6709 ${poll.options.length - 4} \u4E2A\u9009\u9879\uFF0C\u6253\u5F00 App \u770B\u5B8C\u6574\u6570\u636E',
        Offset(128, y + 6),
        maxWidth: 820,
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: const Color(0xFFCBD5E1),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 1220, 856, 86),
        const Radius.circular(24),
      ),
      Paint()..color = Colors.white,
    );
    _drawPosterText(
      canvas,
      '\u641C\u7D22\u5B89\u5168\u7801 ${poll.safeShareCode} \u53C2\u4E0E\u8BA8\u8BBA',
      const Offset(154, 1242),
      maxWidth: 590,
      maxLines: 1,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF111827),
    );

    final qrRect = Rect.fromLTWH(792, 1228, 62, 62);
    final qr = QrPainter(
      data:
          'https://example.com/download?from=share&code=${poll.safeShareCode}',
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF111827),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF111827),
      ),
    );
    canvas.save();
    canvas.translate(qrRect.left, qrRect.top);
    qr.paint(canvas, qrRect.size);
    canvas.restore();
    _drawPosterText(
      canvas,
      '\u7AD9\u961F\uFF1A\u7528\u6295\u7968\u8868\u8FBE\u7ACB\u573A\uFF0C\u7406\u6027\u770B\u89C1\u4E0D\u540C\u89C2\u70B9',
      const Offset(112, 1330),
      maxWidth: 856,
      maxLines: 1,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFCBD5E1),
      textAlign: TextAlign.center,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void _drawPosterText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    int? maxLines,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.18,
        ),
      ),
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '...',
      textAlign: textAlign,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  PollComment? maybeCommentById(int id) {
    for (final poll in polls) {
      for (final comment in poll.comments) {
        if (comment.id == id) return comment;
      }
    }
    return null;
  }

  Poll? maybePollForComment(int commentId) {
    for (final poll in polls) {
      if (poll.comments.any((comment) => comment.id == commentId)) return poll;
    }
    return null;
  }

  Future<void> deleteCommentById(int commentId) async {
    final poll = maybePollForComment(commentId);
    if (poll == null) return;
    try {
      await api.dio.delete('/comments/$commentId');
    } catch (_) {}
    poll.comments.removeWhere((comment) => comment.id == commentId);
    poll.commentCount = poll.commentCount > 0 ? poll.commentCount - 1 : 0;
    notifyListeners();
  }

  List<Poll> searchPolls(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return [];
    return polls
        .where(
          (poll) =>
              poll.title.toLowerCase().contains(value) ||
              poll.description.toLowerCase().contains(value),
        )
        .toList();
  }

  List<DemoUser> searchUsers(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return [];
    return users
        .where(
          (user) =>
              user.nickname.toLowerCase().contains(value) ||
              user.uid.toString().contains(value),
        )
        .toList();
  }

  Future<List<Poll>> fetchMyPolls() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/${currentUser.uid}/polls',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map((item) => cachePoll(Poll.fromJson(item))).toList();
  }

  Future<DemoUser> fetchUserProfile(int uid) async {
    final response = await api.dio.get<Map<String, dynamic>>('/users/$uid');
    final user = DemoUser.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
    _upsertUser(user);
    return user;
  }

  Future<List<Poll>> fetchUserPolls(int uid) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/$uid/polls',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map((item) => cachePoll(Poll.fromJson(item))).toList();
  }

  Future<List<Poll>> fetchVotedPolls() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/voted-polls',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map((item) {
      final poll = Poll.fromJson(item['poll'] as Map<String, dynamic>);
      poll.myOptionId = item['optionId'] as int?;
      return cachePoll(poll, voted: true);
    }).toList();
  }

  Future<List<Poll>> fetchFavoritePolls() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/favorites',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items
        .map(
          (item) => cachePoll(
            Poll.fromJson(item['poll'] as Map<String, dynamic>),
            favorited: true,
          ),
        )
        .toList();
  }

  Future<List<Poll>> fetchLikedPolls() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/liked-polls',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items
        .map((item) => cachePoll(Poll.fromJson(item), liked: true))
        .toList();
  }

  Future<List<Poll>> fetchReceivedLikePolls() async {
    final items = await fetchMyPolls();
    items.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return items.where((poll) => poll.likeCount > 0).toList();
  }

  Future<List<Poll>> fetchHotPolls() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls',
      queryParameters: {'tab': 'hot', 'page': 1, 'pageSize': 10},
    );
    final data = response.data!['data'];
    final rawItems = data is Map<String, dynamic> ? data['items'] : data;
    final items = (rawItems as List<dynamic>).cast<Map<String, dynamic>>();
    return items.map((item) => cachePoll(Poll.fromJson(item))).toList();
  }

  Future<List<DiscoverTopic>> fetchDiscoverTopics() async {
    final response = await api.dio.get<Map<String, dynamic>>('/topics');
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map(DiscoverTopic.fromJson).toList();
  }

  Future<List<VoteParticipant>> fetchPollParticipants(int pollId) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls/$pollId/participants',
    );
    final data = response.data?['data'];
    final rawItems = data is Map<String, dynamic> ? data['items'] : data;
    final items = (rawItems as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    return items.map(VoteParticipant.fromJson).toList();
  }

  Future<List<DemoUser>> fetchFollowing() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/following',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items
        .map(
          (item) =>
              DemoUser.fromJson(item['following'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<DemoUser>> fetchFollowers() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/followers',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items
        .map(
          (item) => DemoUser.fromJson(item['follower'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<DemoUser>> fetchBlockedUsers() async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/users/me/blocks',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items
        .map(
          (item) => DemoUser.fromJson(item['blocked'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> unblockUser(DemoUser user) async {
    await api.dio.delete('/users/${user.uid}/block');
    user.isBlocked = false;
    notifyListeners();
  }

  Future<void> blockUser(DemoUser user) async {
    if (user.uid == currentUser.uid) return;
    await api.dio.post('/users/${user.uid}/block');
    user.isBlocked = true;
    polls.removeWhere((poll) => poll.author.id == user.id);
    await syncProfileStats();
    notifyListeners();
  }

  Future<void> followUser(DemoUser user) async {
    await api.dio.post('/users/${user.uid}/follow');
    user.isFollowing = true;
    currentUser.followingCount += 1;
    user.followerCount += 1;
    notifications.insert(
      0,
      AppNotification('关注成功', '你已关注 ${user.nickname}', DateTime.now()),
    );
    await syncProfileStats();
    notifyListeners();
  }

  Future<void> unfollowUser(DemoUser user) async {
    await api.dio.delete('/users/${user.uid}/follow');
    user.isFollowing = false;
    currentUser.followingCount = (currentUser.followingCount - 1).clamp(
      0,
      1 << 31,
    );
    user.followerCount = (user.followerCount - 1).clamp(0, 1 << 31);
    await syncProfileStats();
    notifyListeners();
  }

  Future<SearchBundle> remoteSearch(String query) async {
    final value = query.trim();
    if (value.isEmpty) return const SearchBundle(polls: [], users: []);
    final response = await api.dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {'q': value},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final pollItems = (data['polls'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final userItems = (data['users'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return SearchBundle(
      polls: pollItems.map(Poll.fromJson).toList(),
      users: userItems.map(DemoUser.fromJson).toList(),
    );
  }
}

enum UserRole { user, reviewer, reportHandler, adManager, admin, superAdmin }

enum AppPermission {
  userMute,
  userRoleManage,
  userDelete,
  pollDelete,
  pollLock,
  pollUnlock,
  reportHandle,
  auditReview,
  adManage,
  announcementManage,
  titleManage,
}

class PermissionTitle {
  PermissionTitle({
    required this.id,
    required this.name,
    required this.color,
    required this.permissions,
    required this.userIds,
  });

  int id;
  String name;
  Color color;
  Set<AppPermission> permissions;
  Set<int> userIds;

  String get hexColor =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Map<String, dynamic> toStored() => {
    'id': id,
    'name': name,
    'badge': name,
    'badgeColor': hexColor,
    'color': color.toARGB32(),
    'permissions': permissions.map((permission) => permission.name).toList(),
    'userIds': userIds.toList(),
  };

  factory PermissionTitle.fromStored(
    Map<String, dynamic> json, {
    Color? fallbackColor,
  }) {
    final permissions = <AppPermission>{};
    for (final value in ((json['permissions'] as List<dynamic>?) ?? [])) {
      final name = value.toString();
      for (final permission in AppPermission.values) {
        if (permission.name == name ||
            permissionLabel(permission) == name ||
            _serverPermissionName(permission) == name) {
          permissions.add(permission);
        }
      }
    }
    return PermissionTitle(
      id: json['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      name: json['name'] as String? ?? json['badge'] as String? ?? '权限用户',
      color: _storedColor(
        json['color'] ?? json['badgeColor'],
        fallbackColor ?? const Color(0xFF2563EB),
      ),
      permissions: permissions,
      userIds: ((json['userIds'] as List<dynamic>?) ?? [])
          .map((id) => int.tryParse('$id'))
          .whereType<int>()
          .toSet(),
    );
  }
}

class HomeAd {
  HomeAd(this.title, this.body, this.imageUrl, this.enabled);
  String title;
  String body;
  String imageUrl;
  bool enabled;
}

class AppAnnouncement {
  AppAnnouncement({
    required this.title,
    required this.body,
    required this.enabled,
    required this.showEveryLaunch,
  });
  String title;
  String body;
  bool enabled;
  bool showEveryLaunch;
}

class DemoUser {
  DemoUser({
    required this.id,
    required this.uid,
    required this.username,
    required this.nickname,
    required this.role,
    required this.bio,
    this.avatarUrl,
  });

  final int id;
  final int uid;
  String username;
  String nickname;
  UserRole role;
  String bio;
  String? avatarUrl;
  bool muted = false;
  DateTime? mutedUntil;
  String? mutedReason;
  bool deleted = false;
  int pollCount = 0;
  int receivedLikes = 0;
  int followingCount = 0;
  int followerCount = 0;
  bool isFollowing = false;
  bool isBlocked = false;

  bool get canAdmin => role != UserRole.user;
  bool get isCreatorAdmin => role == UserRole.superAdmin;
  bool get canAudit =>
      role == UserRole.reviewer ||
      role == UserRole.admin ||
      role == UserRole.superAdmin;
  bool get canManageAds =>
      role == UserRole.adManager ||
      role == UserRole.admin ||
      role == UserRole.superAdmin;
  bool get canManageRoles => isCreatorAdmin;
  bool get showBadge => role != UserRole.user;
  bool get isCurrentlyMuted =>
      muted && (mutedUntil == null || mutedUntil!.isAfter(DateTime.now()));
  String get muteLabel {
    if (!isCurrentlyMuted) return '';
    if (mutedUntil == null) return '永久禁言';
    final days = mutedUntil!.difference(DateTime.now()).inDays + 1;
    return '禁言剩余 $days 天';
  }

  String get badgeLabel => switch (role) {
    UserRole.admin => '管理员',
    UserRole.superAdmin => '创建管理员',
    UserRole.reviewer => '审核员',
    UserRole.reportHandler => '举报处理',
    UserRole.adManager => '广告管理',
    UserRole.user => '',
  };
  factory DemoUser.fromJson(Map<String, dynamic> json) {
    final roleName = (json['role'] as String? ?? 'USER').toLowerCase();
    final role = switch (roleName) {
      'admin' => UserRole.admin,
      'super_admin' => UserRole.superAdmin,
      'reviewer' => UserRole.reviewer,
      'report_handler' => UserRole.reportHandler,
      'ad_manager' => UserRole.adManager,
      _ => UserRole.user,
    };
    final user = DemoUser(
      id: json['id'] as int? ?? 0,
      uid: json['uid'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '匿名用户',
      role: role,
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
    user
      ..pollCount = json['pollCount'] as int? ?? 0
      ..receivedLikes = json['receivedLikes'] as int? ?? 0
      ..followingCount = json['followingCount'] as int? ?? 0
      ..followerCount = json['followerCount'] as int? ?? 0
      ..muted = json['isMuted'] as bool? ?? json['muted'] as bool? ?? false
      ..mutedUntil = json['mutedUntil'] == null
          ? null
          : DateTime.tryParse(json['mutedUntil'].toString())
      ..mutedReason = json['mutedReason']?.toString();
    return user;
  }
}

class UserSettings {
  UserSettings({
    this.darkMode = false,
    this.notifyComments = true,
    this.notifyLikes = true,
    this.notifyFollows = true,
    this.notifyReports = true,
    this.screenshotShareHint = true,
  });

  bool darkMode;
  bool notifyComments;
  bool notifyLikes;
  bool notifyFollows;
  bool notifyReports;
  bool screenshotShareHint;

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    darkMode: json['darkMode'] as bool? ?? false,
    notifyComments: json['notifyComments'] as bool? ?? true,
    notifyLikes: json['notifyLikes'] as bool? ?? true,
    notifyFollows: json['notifyFollows'] as bool? ?? true,
    notifyReports: json['notifyReports'] as bool? ?? true,
    screenshotShareHint: json['screenshotShareHint'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'notifyComments': notifyComments,
    'notifyLikes': notifyLikes,
    'notifyFollows': notifyFollows,
    'notifyReports': notifyReports,
    'screenshotShareHint': screenshotShareHint,
  };
}

class SearchBundle {
  const SearchBundle({required this.polls, required this.users});
  final List<Poll> polls;
  final List<DemoUser> users;
}

class DiscoverTopic {
  const DiscoverTopic({
    required this.id,
    required this.name,
    this.category,
    this.pollCount = 0,
    this.heat = 0,
  });

  final int id;
  final String name;
  final String? category;
  final int pollCount;
  final int heat;

  factory DiscoverTopic.fromJson(Map<String, dynamic> json) => DiscoverTopic(
    id: json['id'] as int? ?? 0,
    name: json['name']?.toString() ?? '',
    category: json['category']?.toString(),
    pollCount: json['pollCount'] as int? ?? 0,
    heat: json['heat'] as int? ?? 0,
  );
}

class ProfileStats {
  const ProfileStats({
    this.pollCount = 0,
    this.followingCount = 0,
    this.followerCount = 0,
    this.receivedLikes = 0,
    this.likedCount = 0,
    this.votedCount = 0,
    this.favoriteCount = 0,
  });

  final int pollCount;
  final int followingCount;
  final int followerCount;
  final int receivedLikes;
  final int likedCount;
  final int votedCount;
  final int favoriteCount;

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
    pollCount: json['pollCount'] as int? ?? 0,
    followingCount: json['followingCount'] as int? ?? 0,
    followerCount: json['followerCount'] as int? ?? 0,
    receivedLikes: json['receivedLikes'] as int? ?? 0,
    likedCount: json['likedCount'] as int? ?? 0,
    votedCount: json['votedCount'] as int? ?? 0,
    favoriteCount: json['favoriteCount'] as int? ?? 0,
  );
}

class Poll {
  Poll({
    required this.id,
    this.shareCode,
    required this.title,
    required this.description,
    required this.author,
    required this.isAnonymous,
    required this.allowAnonymousVote,
    required this.allowAnonymousComment,
    required this.allowComment,
    required this.allowLike,
    required this.allowShare,
    required this.endAt,
    required this.options,
    required this.comments,
    this.viewCount = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.favoriteCount = 0,
    this.commentCount = 0,
    List<String>? imageUrls,
    this.topicName,
  }) : imageUrls = imageUrls ?? [];

  int id;
  String? shareCode;
  String title;
  String description;
  final DemoUser author;
  final bool isAnonymous;
  final bool allowAnonymousVote;
  final bool allowAnonymousComment;
  bool allowComment;
  bool allowLike;
  bool allowShare;
  final DateTime? endAt;
  final List<PollOption> options;
  final List<PollComment> comments;
  final Set<int> votedUserIds = {};
  int viewCount;
  int likeCount;
  int dislikeCount;
  int favoriteCount;
  int commentCount;
  final List<String> imageUrls;
  String? topicName;
  int? myOptionId;
  bool isLiked = false;
  bool isDisliked = false;
  bool isFavorited = false;
  bool viewerStateKnown = false;
  bool editApproved = false;
  bool editRequested = false;

  int get voteCount => options.fold(0, (sum, option) => sum + option.voteCount);
  String get safeShareCode => shareCode?.trim().isNotEmpty == true
      ? shareCode!.trim()
      : 'ZD-${id.toRadixString(36).toUpperCase()}';
  bool get hasEnded => endAt != null && endAt!.isBefore(DateTime.now());
  bool get interactionLocked => !allowComment || !allowLike || !allowShare;
  List<String> get tags {
    final items = <String>[];
    final serverTopic = topicName?.trim().replaceFirst(RegExp(r'^#+'), '');
    if (serverTopic != null && serverTopic.isNotEmpty) items.add(serverTopic);
    items.addAll(extractTopicNames(description));
    return LinkedHashSet<String>.from(
      items.where((item) => item.isNotEmpty),
    ).take(5).toList();
  }

  String get authorName => isAnonymous ? '匿名用户' : author.nickname;
  String displayAuthorName({required bool revealAnonymous}) =>
      isAnonymous && !revealAnonymous ? '匿名用户' : author.nickname;
  String? anonymousRevealLabel({required bool revealAnonymous}) =>
      isAnonymous && revealAnonymous
      ? '匿名发布者：${author.nickname} · UID ${author.uid}'
      : null;

  factory Poll.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    final viewerState = json['viewerState'] as Map<String, dynamic>?;
    final poll = Poll(
      id: json['id'] as int,
      shareCode: json['shareCode']?.toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: authorJson == null
          ? DemoUser(
              id: json['authorId'] as int? ?? 0,
              uid: 0,
              username: '',
              nickname: '匿名用户',
              role: UserRole.user,
              bio: '',
            )
          : DemoUser.fromJson({
              ...authorJson,
              'id': json['authorId'] as int? ?? authorJson['id'],
            }),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      allowAnonymousVote: json['allowAnonymousVote'] as bool? ?? true,
      allowAnonymousComment: json['allowAnonymousComment'] as bool? ?? true,
      allowComment: json['allowComment'] as bool? ?? true,
      allowLike: json['allowLike'] as bool? ?? true,
      allowShare: json['allowShare'] as bool? ?? true,
      endAt: json['endAt'] == null
          ? null
          : DateTime.parse(json['endAt'] as String),
      options: ((json['options'] as List<dynamic>?) ?? [])
          .map((item) => PollOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      comments: ((json['comments'] as List<dynamic>?) ?? [])
          .map((item) => PollComment.fromJson(item as Map<String, dynamic>))
          .toList(),
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      favoriteCount: json['favoriteCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      imageUrls: ((json['imageUrls'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      topicName:
          (json['topic'] as Map<String, dynamic>?)?['name']?.toString() ??
          json['topicName']?.toString(),
    );
    poll
      ..myOptionId = viewerState?['myOptionId'] as int?
      ..isLiked = viewerState?['isLiked'] as bool? ?? false
      ..isFavorited = viewerState?['isFavorited'] as bool? ?? false
      ..isDisliked = viewerState?['isDisliked'] as bool? ?? false
      ..viewerStateKnown = viewerState != null;
    return poll;
  }
}

class PollOption {
  PollOption({
    required this.id,
    required this.text,
    required this.color,
    this.voteCount = 0,
  });

  final int id;
  final String text;
  final Color color;
  int voteCount;

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      color: parseColor(json['color'] as String?),
      voteCount: json['voteCount'] as int? ?? 0,
    );
  }
}

class VoteParticipant {
  VoteParticipant({
    required this.id,
    required this.isAnonymous,
    required this.revealedByAdmin,
    required this.anonymousId,
    required this.optionText,
    required this.optionColor,
    required this.createdAt,
    this.user,
  });

  final int id;
  final bool isAnonymous;
  final bool revealedByAdmin;
  final String anonymousId;
  final String optionText;
  final Color optionColor;
  final DateTime createdAt;
  final DemoUser? user;

  bool get maskedAnonymous => isAnonymous && !revealedByAdmin;
  String get displayName =>
      maskedAnonymous ? anonymousId : (user?.nickname ?? anonymousId);
  String get uidLabel => maskedAnonymous
      ? anonymousId
      : 'UID ${user?.uid ?? 0}${isAnonymous ? ' · 匿名投票' : ''}';
  String? get avatarUrl => maskedAnonymous ? null : user?.avatarUrl;

  factory VoteParticipant.fromJson(Map<String, dynamic> json) {
    final option = json['option'] as Map<String, dynamic>? ?? {};
    final userJson = json['user'] as Map<String, dynamic>?;
    return VoteParticipant(
      id: json['id'] as int? ?? 0,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      revealedByAdmin: json['revealedByAdmin'] as bool? ?? false,
      anonymousId: json['anonymousId'] as String? ?? '匿名#0000',
      optionText: option['text'] as String? ?? '',
      optionColor: parseColor(option['color'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      user: userJson == null ? null : DemoUser.fromJson(userJson),
    );
  }
}

class PollComment {
  PollComment({
    required this.id,
    required this.author,
    required this.content,
    required this.isAnonymous,
    required this.revealedByAdmin,
    required this.createdAt,
    this.stanceColor,
    this.stanceText,
    this.myReaction,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.canDelete = false,
  });

  final int id;
  final DemoUser author;
  final String content;
  final bool isAnonymous;
  final bool revealedByAdmin;
  final DateTime createdAt;
  final Color? stanceColor;
  final String? stanceText;
  String? myReaction;
  int likeCount;
  int dislikeCount;
  final bool canDelete;

  String get authorName => isAnonymous ? '匿名用户' : author.nickname;
  String displayAuthorName({required bool revealAnonymous}) =>
      isAnonymous && !(revealAnonymous && revealedByAdmin)
      ? '匿名用户'
      : author.nickname;
  String? anonymousRevealLabel({required bool revealAnonymous}) =>
      isAnonymous && revealAnonymous && revealedByAdmin
      ? '匿名评论者：${author.nickname} · UID ${author.uid}'
      : null;

  factory PollComment.fromJson(
    Map<String, dynamic> json, {
    DemoUser? fallbackAuthor,
  }) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    final stanceJson = json['stance'] as Map<String, dynamic>?;
    return PollComment(
      id: json['id'] as int,
      author: authorJson == null
          ? fallbackAuthor ??
                DemoUser(
                  id: json['authorId'] as int? ?? 0,
                  uid: 0,
                  username: '',
                  nickname: '匿名评论者',
                  role: UserRole.user,
                  bio: '',
                )
          : DemoUser.fromJson(authorJson),
      content: json['content'] as String? ?? '',
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      revealedByAdmin: json['revealedByAdmin'] as bool? ?? false,
      stanceColor: stanceJson == null
          ? null
          : parseColor(stanceJson['color'] as String?),
      stanceText: stanceJson == null ? null : stanceJson['text'] as String?,
      myReaction: json['myReaction'] as String?,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      dislikeCount: json['dislikeCount'] as int? ?? 0,
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }
}

Color parseColor(String? value) {
  final normalized = (value ?? '#4F46E5').replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}

Color _storedColor(Object? value, Color fallback) {
  if (value is int) return Color(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      return parseColor(value);
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}

String _serverPermissionName(AppPermission permission) => switch (permission) {
  AppPermission.userMute => 'USER_BAN',
  AppPermission.userRoleManage => 'ROLE_MANAGE',
  AppPermission.userDelete => 'USER_DELETE',
  AppPermission.pollDelete => 'POLL_MODERATE',
  AppPermission.pollLock => 'POLL_MODERATE',
  AppPermission.pollUnlock => 'POLL_MODERATE',
  AppPermission.reportHandle => 'REPORT_MANAGE',
  AppPermission.auditReview => 'COMMENT_MODERATE',
  AppPermission.adManage => 'AD_MANAGE',
  AppPermission.announcementManage => 'ANNOUNCEMENT_MANAGE',
  AppPermission.titleManage => 'ROLE_MANAGE',
};

class AppNotification {
  AppNotification(
    this.title,
    this.body,
    this.createdAt, {
    this.id,
    this.type = '',
    this.targetType,
    this.targetId,
    this.targetPollId,
  });
  final int? id;
  final String type;
  final String? targetType;
  final int? targetId;
  final int? targetPollId;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead = false;

  bool get isInteraction {
    if (type.endsWith('_SELF') ||
        type == 'REPORT_CREATED' ||
        type == 'VOTE_CREATED') {
      return false;
    }
    return type.contains('COMMENT') ||
        type.contains('REPLY') ||
        type.contains('LIKED') ||
        type.contains('FOLLOW') ||
        type == 'POLL_VOTED';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final normalized = _normalizeNotificationText(
      type,
      json['title'] as String?,
      json['body'] as String?,
    );
    final item = AppNotification(
      normalized.$1,
      normalized.$2,
      DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      id: json['id'] as int?,
      type: type,
      targetType: json['targetType'] as String?,
      targetId: json['targetId'] as int?,
      targetPollId: json['targetPollId'] as int?,
    );
    item.isRead = json['isRead'] as bool? ?? false;
    return item;
  }
}

(String, String) _normalizeNotificationText(
  String type,
  String? title,
  String? body,
) {
  final fallbackTitle = title ?? '\u7CFB\u7EDF\u901A\u77E5';
  final fallbackBody = (body ?? '')
      .replaceAll(
        'comments locked from app',
        '\u8BE5\u6295\u7968\u5DF2\u88AB\u7981\u6B62\u4E92\u52A8',
      )
      .replaceAll(
        'comments unlocked from app',
        '\u8BE5\u6295\u7968\u5DF2\u89E3\u9664\u7981\u6B62\u4E92\u52A8',
      )
      .replaceAll(
        'deleted from app',
        '\u8BE5\u6295\u7968\u5DF2\u88AB\u5220\u9664',
      )
      .replaceAll(
        RegExp(r'COMMENT#(\d+)|COMMENTS#(\d+)|POLL#(\d+)', caseSensitive: false),
        '\u4E00\u6761\u88AB\u4E3E\u62A5\u7684\u8BC4\u8BBA',
      );
  return switch (type) {
    'REPORT_PENDING' => (
      '\u6536\u5230\u65B0\u7684\u4E3E\u62A5',
      fallbackBody.isEmpty
          ? '\u6709\u5185\u5BB9\u7B49\u5F85\u4F60\u5904\u7406'
          : fallbackBody,
    ),
    'REPORT_CREATED' => (
      '\u4E3E\u62A5\u5DF2\u63D0\u4EA4',
      '\u6211\u4EEC\u4F1A\u5C3D\u5FEB\u5BA1\u6838\u4F60\u63D0\u4EA4\u7684\u4E3E\u62A5',
    ),
    'REPORT_RESULT' => ('\u4E3E\u62A5\u5904\u7406\u5B8C\u6210', fallbackBody),
    'POLL_COMMENTED' => (
      '\u4F60\u7684\u6295\u7968\u6536\u5230\u65B0\u8BC4\u8BBA',
      fallbackBody,
    ),
    'COMMENT_REPLIED' => (
      '\u4F60\u7684\u8BC4\u8BBA\u6536\u5230\u56DE\u590D',
      fallbackBody,
    ),
    'POLL_LIKED' => (
      '\u4F60\u7684\u6295\u7968\u88AB\u70B9\u8D5E',
      fallbackBody,
    ),
    'POLL_VOTED' => (
      '\u6709\u4EBA\u53C2\u4E0E\u4E86\u4F60\u7684\u6295\u7968',
      fallbackBody,
    ),
    'COMMENT_LIKED' => (
      '\u4F60\u7684\u8BC4\u8BBA\u88AB\u70B9\u8D5E',
      fallbackBody,
    ),
    'VOTE_CREATED' => ('\u6295\u7968\u6210\u529F', fallbackBody),
    'COMMENT_CREATED_SELF' => (
      '\u8BC4\u8BBA\u53D1\u5E03\u6210\u529F',
      fallbackBody,
    ),
    'COMMENT_LIKED_SELF' => ('\u70B9\u8D5E\u6210\u529F', fallbackBody),
    'POLL_LIKED_SELF' => ('\u70B9\u8D5E\u6210\u529F', fallbackBody),
    _ => (fallbackTitle, fallbackBody),
  };
}

class ReportItem {
  ReportItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.reporter,
    required this.createdAt,
  });

  final int id;
  final String targetType;
  final int targetId;
  final String reason;
  final DemoUser reporter;
  final DateTime createdAt;
  String status = 'PENDING';

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final reporterJson = json['reporter'] as Map<String, dynamic>? ?? {};
    final reporter = DemoUser(
      id: reporterJson['id'] as int? ?? json['reporterId'] as int? ?? 0,
      uid: reporterJson['uid'] as int? ?? 0,
      username: reporterJson['username'] as String? ?? '',
      nickname: reporterJson['nickname'] as String? ?? '举报用户',
      role: UserRole.user,
      bio: '',
    );
    final item = ReportItem(
      id: json['id'] as int? ?? 0,
      targetType: json['targetType'] as String? ?? 'POLL',
      targetId: json['targetId'] as int? ?? 0,
      reason: json['reason'] as String? ?? 'OTHER',
      reporter: reporter,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
    item.status = json['status'] as String? ?? 'PENDING';
    return item;
  }
}

const optionColors = [
  Color(0xFF4F46E5),
  Color(0xFF059669),
  Color(0xFFEA580C),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFF7C3AED),
  Color(0xFFCA8A04),
  Color(0xFFDC2626),
];

Color titleColorForIndex(int index) {
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFEA580C),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];
  return colors[index % colors.length];
}

String reportReasonLabel(String reason) {
  return switch (reason.toUpperCase()) {
    'SPAM' => '垃圾广告',
    'ILLEGAL' => '违法违规',
    'HARASSMENT' => '骚扰攻击',
    'PORNOGRAPHIC' => '色情低俗',
    'OTHER' => '其他原因',
    _ => reason,
  };
}

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
              '站队',
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
  final username = TextEditingController();
  final password = TextEditingController();
  final nickname = TextEditingController();
  bool registerMode = false;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

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
                      registerMode ? '创建账号' : '站队',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: username,
                      decoration: InputDecoration(
                        labelText: registerMode ? '账号' : '账号或 ID',
                        helperText: registerMode
                            ? '至少 5 位，不能纯数字或符号开头'
                            : '可输入账号或系统分配 ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'),
                    ),
                    if (registerMode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: nickname,
                        decoration: const InputDecoration(
                          labelText: '昵称',
                          helperText: '2-8 个字，仅用于展示',
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
                      label: Text(registerMode ? '注册并进入' : '登录'),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => registerMode = !registerMode),
                      child: Text(registerMode ? '已有账号，去登录' : '没有账号，注册一个'),
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
      setState(() => error = friendlyErrorMessage(e));
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
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
      final update = await state.checkForUpdate().catchError((_) => null);
      if (update != null && mounted) {
        await showUpdateDialog(context, update);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: appPageBackground(context),
        appBar: AppBar(
          backgroundColor: appPageBackground(context),
          surfaceTintColor: Colors.transparent,
          title: const Text('站队'),
          actions: [
            IconButton(
              tooltip: '搜索',
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              tooltip: '消息',
              onPressed: () => context.go('/messages'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '推荐'),
              Tab(text: '最新'),
              Tab(text: '热门'),
              Tab(text: '关注'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeTabFeed(tab: 'recommended', showHeader: true),
            HomeTabFeed(tab: 'latest', showHeader: true),
            HomeTabFeed(tab: 'hot', showHeader: true),
            HomeTabFeed(tab: 'following', showHeader: true),
          ],
        ),
      ),
    );
  }
}

class HomeTabFeed extends ConsumerStatefulWidget {
  const HomeTabFeed({required this.tab, this.showHeader = false, super.key});

  final String tab;
  final bool showHeader;

  @override
  ConsumerState<HomeTabFeed> createState() => _HomeTabFeedState();
}

class _HomeTabFeedState extends ConsumerState<HomeTabFeed>
    with AutomaticKeepAliveClientMixin<HomeTabFeed> {
  late Future<List<Poll>> future;
  List<Poll> polls = const [];
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    final cached = ref.read(appStateProvider).cachedPollFeed(widget.tab);
    polls = cached;
    future = cached.isEmpty ? _load() : Future.value(cached);
    if (cached.isNotEmpty &&
        !ref.read(appStateProvider).isFeedFresh(widget.tab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh(silent: true);
      });
    }
    refreshTimer = Timer.periodic(feedRefreshInterval, (_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<Poll>> _load() async {
    final items = await ref
        .read(appStateProvider)
        .fetchPollFeed(tab: widget.tab);
    if (mounted) {
      setState(() => polls = items);
    } else {
      polls = items;
    }
    return items;
  }

  Future<void> _refresh({bool silent = false}) async {
    final next = _load();
    if (!silent) setState(() { future = next; });
    await next;
    if (silent && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(appStateProvider);
    return FutureBuilder<List<Poll>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? polls;
        if (snapshot.connectionState != ConnectionState.done && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return PollFeed(
          polls: items,
          showHeader: widget.showHeader,
          onRefresh: _refresh,
          emptyText: widget.tab == 'following' ? '关注的人发布投票后会出现在这里' : '暂时没有投票',
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PollFeed extends ConsumerWidget {
  const PollFeed({
    required this.polls,
    this.showHeader = false,
    this.onRefresh,
    this.emptyText = '暂时没有投票',
    super.key,
  });

  final List<Poll> polls;
  final bool showHeader;
  final Future<void> Function()? onRefresh;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final headerCount = showHeader ? 2 : 0;
    return ZhandeRefreshIndicator(
      onRefresh: onRefresh ?? () => ref.read(appStateProvider).refreshPolls(),
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
          if (pollIndex >= polls.length) {
            return EmptyState(
              icon: Icons.how_to_vote_outlined,
              text: emptyText,
            );
          }
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
        itemCount: polls.isEmpty ? headerCount + 1 : polls.length + headerCount,
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
              '站队',
              '把选择交给真实人群',
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
                          '公告',
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
    final dark = isDarkUi(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Color(0xFF2563EB),
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textWidth = constraints.maxWidth + 72;
                return ClipRect(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final dx = -controller.value * textWidth;
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: dx,
                            top: 0,
                            bottom: 0,
                            width: textWidth,
                            child: _MarqueeText(widget.text),
                          ),
                          Positioned(
                            left: dx + textWidth,
                            top: 0,
                            bottom: 0,
                            width: textWidth,
                            child: _MarqueeText(widget.text),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatelessWidget {
  const _MarqueeText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TopicTagStrip extends StatelessWidget {
  const TopicTagStrip({required this.tags, super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Text(
              '#$tag',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
          .toList(),
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
            maxLines: enableVoting ? 8 : 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: enableVoting ? FontWeight.w900 : FontWeight.w700,
              height: enableVoting ? 1.12 : 1.18,
              fontSize: enableVoting ? 25 : 20,
            ),
          ),
          if (poll.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              poll.description,
              maxLines: enableVoting ? null : 4,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: enableVoting
                    ? const Color(0xFF475569)
                    : const Color(0xFF6B7280),
                height: enableVoting ? 1.62 : 1.45,
                fontSize: enableVoting ? 15 : null,
              ),
            ),
          ],
          if (poll.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            PollImageStrip(urls: poll.imageUrls),
          ],
          if (!enableVoting &&
              (poll.isAnonymous ||
                  poll.allowAnonymousVote ||
                  poll.interactionLocked)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (poll.isAnonymous)
                  const StatusPill(
                    label: '匿名发布',
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
                    label: '匿名投票',
                    color: Color(0xFF2563EB),
                    compact: true,
                  ),
                if (poll.interactionLocked)
                  const StatusPill(
                    label: '禁止互动',
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
                              title: '互动已关闭',
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
                maxLines: enableVoting ? 4 : 3,
                overflow: TextOverflow.ellipsis,
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
              if (poll.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                PollImageStrip(urls: poll.imageUrls),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (poll.isAnonymous)
                    const StatusPill(
                      label: '匿名发布',
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
                      label: '匿名投票',
                      color: Color(0xFF2563EB),
                      compact: true,
                    ),
                  if (poll.interactionLocked)
                    const StatusPill(
                      label: '禁止互动',
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
                          poll.myOptionId != null ||
                          poll.votedUserIds.contains(state.currentUser.id),
                      onTap: enableVoting
                          ? () async {
                              if (poll.interactionLocked) {
                                showAppToast(
                                  context,
                                  title: '互动已关闭',
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
                      label: '${poll.voteCount} 人',
                    ),
                    IconLabel(
                      icon: Icons.chat_bubble_outline,
                      label: '${poll.commentCount}',
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
            label: '${poll.commentCount}',
            onTap: () => context.push('/poll/${poll.id}'),
          ),
          _HomeActionButton(
            icon: Icons.ios_share_rounded,
            label: '分享',
            onTap: () {
              state.sharePoll(context, poll);
            },
          ),
          const Spacer(),
          _HomeActionButton(
            icon: Icons.how_to_vote_outlined,
            label: '${poll.voteCount} 人',
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
        '还有 $count 个选项，进入详情查看',
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
            label: '${poll.commentCount}',
            onTap: () => Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            ),
          ),
          _HomeActionButton(
            icon: Icons.ios_share_rounded,
            label: '分享',
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

class PollImageStrip extends StatelessWidget {
  const PollImageStrip({required this.urls, super.key});

  final List<String> urls;

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '\\';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final visible = urls.take(3).toList();
    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => showPollImagePreview(context, _resolveUrl(visible[i])),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    _resolveUrl(visible[i]),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (i != visible.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

void showPollImagePreview(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
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
            active ? '进行中' : '已结束',
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
    final color = option.color;
    final canTap = onTap != null && !disabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _NoSplashTap(
        enabled: canTap,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: framed
              ? const EdgeInsets.all(12)
              : const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: framed
                ? (selected
                      ? option.color.withValues(alpha: 0.075)
                      : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: framed
                ? Border.all(
                    color: selected
                        ? option.color.withValues(alpha: 0.34)
                        : const Color(0xFFE2E8F0),
                  )
                : null,
            boxShadow: framed && selected
                ? [
                    BoxShadow(
                      color: option.color.withValues(alpha: 0.12),
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
                            '占比',
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
                          Icon(
                            Icons.check_circle_rounded,
                            size: 17,
                            color: color,
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
                          label: option.voteCount == 0
                              ? '\u6682\u65E0\u9009\u62E9'
                              : '\u5171 ${option.voteCount} \u4EBA',
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
    );
  }
}

class _NoSplashTap extends StatefulWidget {
  const _NoSplashTap({required this.child, this.onTap, this.enabled = true});

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_NoSplashTap> createState() => _NoSplashTapState();
}

class _NoSplashTapState extends State<_NoSplashTap> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => pressed = true) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => pressed = false)
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => pressed = false);
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
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
  bool loadingDetail = true;
  bool refreshingDetail = false;
  Timer? detailRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(appStateProvider).syncPollDetail(widget.pollId);
      } finally {
        if (mounted) setState(() => loadingDetail = false);
      }
    });
    detailRefreshTimer = Timer.periodic(detailRefreshInterval, (_) {
      if (!mounted || refreshingDetail) return;
      refreshingDetail = true;
      ref
          .read(appStateProvider)
          .syncPollDetail(widget.pollId)
          .catchError((_) => ref.read(appStateProvider).pollById(widget.pollId))
          .whenComplete(() => refreshingDetail = false);
    });
  }

  @override
  void dispose() {
    detailRefreshTimer?.cancel();
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final poll = state.maybePollById(widget.pollId);
    if (poll == null && loadingDetail) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(title: const Text('投票详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (poll == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(title: const Text('投票详情')),
        body: const EmptyState(icon: Icons.delete_outline, text: '投票已删除或不可见'),
      );
    }
    final canManage = state.canManagePoll(poll);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('投票详情'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_horiz_rounded),
            color: Colors.white,
            elevation: 14,
            surfaceTintColor: Colors.transparent,
            position: PopupMenuPosition.under,
            offset: const Offset(-8, 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            constraints: const BoxConstraints(minWidth: 190),
            onSelected: (value) async {
              if (value == 'report') {
                await showModernReportSheet(context, ref, 'POLL', poll.id);
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
                      title: '申请已提交',
                      message: '审核通过后可以编辑标题和描述',
                      icon: Icons.edit_note_rounded,
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Text('\u4E3E\u62A5')),
              if (poll.author.id == state.currentUser.id)
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    poll.editApproved
                        ? '\u7F16\u8F91\u5E16\u5B50'
                        : '\u7533\u8BF7\u7F16\u8F91',
                  ),
                ),
              if (canManage && !poll.interactionLocked)
                const PopupMenuItem(
                  value: 'lock',
                  child: Text('\u7981\u6B62\u4E92\u52A8'),
                ),
              if (canManage && poll.interactionLocked)
                const PopupMenuItem(
                  value: 'unlock',
                  child: Text('\u89E3\u9664\u7981\u6B62\u4E92\u52A8'),
                ),
              if (canManage)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('\u5220\u9664\u6295\u7968'),
                ),
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
                  '讨论',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                _CommentComposer(
                  controller: comment,
                  user: state.currentUser,
                  anonymousEnabled: poll.allowAnonymousComment,
                  anonymous: anonymousComment,
                  interactionLocked: poll.interactionLocked,
                  onToggleAnonymous: () =>
                      setState(() => anonymousComment = !anonymousComment),
                  onSend: () async {
                    if (poll.interactionLocked) {
                      showAppToast(
                        context,
                        title: '\u4E92\u52A8\u5DF2\u5173\u95ED',
                        message: lockedInteractionMessage,
                        icon: Icons.lock_outline_rounded,
                        color: const Color(0xFFDC2626),
                      );
                      return;
                    }
                    await state.addComment(
                      poll.id,
                      comment.text,
                      anonymous: poll.allowAnonymousComment && anonymousComment,
                    );
                    comment.clear();
                  },
                ),
                const Divider(
                  height: 30,
                  thickness: 1,
                  color: Color(0xFFE2E8F0),
                ),
                if (poll.comments.isEmpty &&
                    poll.commentCount > 0 &&
                    loadingDetail)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (poll.comments.isEmpty)
                  const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    text: '还没有评论',
                  )
                else
                  for (final item in poll.comments)
                    _OpenCommentItem(
                      pollId: poll.id,
                      item: item,
                      revealAnonymous: state.currentUser.isCreatorAdmin,
                      onReport: () => showModernReportSheet(
                        context,
                        ref,
                        'COMMENT',
                        item.id,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.user,
    required this.anonymousEnabled,
    required this.anonymous,
    required this.interactionLocked,
    required this.onToggleAnonymous,
    required this.onSend,
  });

  final TextEditingController controller;
  final DemoUser user;
  final bool anonymousEnabled;
  final bool anonymous;
  final bool interactionLocked;
  final VoidCallback onToggleAnonymous;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF16A34A);
    final sendColor = interactionLocked
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF2563EB);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: AppAvatar(
                    key: ValueKey(anonymous),
                    name: anonymous
                        ? '\u533F\u540D\u7528\u6237'
                        : user.nickname,
                    avatarUrl: anonymous ? null : user.avatarUrl,
                    anonymous: anonymous,
                    size: 40,
                  ),
                ),
                if (anonymousEnabled)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Tooltip(
                      message: anonymous
                          ? '\u5DF2\u5F00\u542F\u533F\u540D\u8BC4\u8BBA'
                          : '\u533F\u540D\u8BC4\u8BBA',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onToggleAnonymous,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: anonymous
                                ? activeColor
                                : const Color(0xFFE5E7EB),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '\u533F',
                            style: TextStyle(
                              color: anonymous
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.only(left: 1, right: 1, bottom: 3),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8EDF4))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !interactionLocked,
                      cursorColor: const Color(0xFF2563EB),
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 15,
                        height: 1.22,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: interactionLocked
                            ? lockedInteractionMessage
                            : '\u8BF4\u70B9\u4EC0\u4E48...',
                        hintStyle: const TextStyle(
                          color: Color(0xFFADB5C2),
                          fontWeight: FontWeight.w700,
                        ),
                        isDense: true,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final canSend =
                          !interactionLocked && value.text.trim().isNotEmpty;
                      return AnimatedScale(
                        scale: canSend ? 1 : 0.9,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        child: Tooltip(
                          message: canSend ? '\u53D1\u9001\u8BC4\u8BBA' : '',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: canSend ? onSend : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: canSend
                                      ? const Color(0xFF111827)
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 20,
                                  color: canSend
                                      ? Colors.white
                                      : sendColor.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
                                ? '已参与投票'
                                : '立场：${item.stanceText}',
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
                          tooltip: '\u4E3E\u62A5\u8BC4\u8BBA',
                          onPressed: onReport,
                          icon: const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (item.canDelete)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: '\u5220\u9664\u8BC4\u8BBA',
                            onPressed: () => ref
                                .read(appStateProvider)
                                .deleteCommentById(item.id),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
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
    return _NoSplashTap(
      enabled: onTap != null,
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

class _ParticipantPreview extends ConsumerStatefulWidget {
  const _ParticipantPreview({required this.pollId, required this.voteCount});

  final int pollId;
  final int voteCount;

  @override
  ConsumerState<_ParticipantPreview> createState() =>
      _ParticipantPreviewState();
}

class _ParticipantPreviewState extends ConsumerState<_ParticipantPreview> {
  late Future<List<VoteParticipant>> participantsFuture;

  @override
  void initState() {
    super.initState();
    participantsFuture = ref
        .read(appStateProvider)
        .fetchPollParticipants(widget.pollId);
  }

  @override
  void didUpdateWidget(covariant _ParticipantPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pollId != widget.pollId) {
      participantsFuture = ref
          .read(appStateProvider)
          .fetchPollParticipants(widget.pollId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VoteParticipant>>(
      future: participantsFuture,
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];
        final preview = participants.take(3).toList();
        final remaining = participants.length > 3 ? participants.length - 3 : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.voteCount <= 0
                  ? null
                  : () => showParticipantsSheet(context, ref, widget.pollId),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                            '${participants.isEmpty ? widget.voteCount : participants.length} \u4EBA\u5DF2\u7AD9\u961F',
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            '\u67E5\u770B\u53C2\u4E0E\u8005\u548C\u7ACB\u573A\u5206\u5E03',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1),
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
                    '参与投票用户',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${participants.length} 人',
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
                  text: '参与用户加载失败',
                )
              else if (participants.isEmpty)
                const EmptyState(icon: Icons.group_outlined, text: '还没有用户参与投票')
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
  final List<String> imageUrls = [];
  DateTime? endAt = DateTime.now().add(const Duration(days: 7));
  bool isAnonymous = false;
  bool allowAnonymousVote = false;
  bool allowAnonymousComment = false;
  bool allowComment = true;
  bool allowLike = true;
  bool allowShare = true;
  bool publishing = false;
  bool uploadingImage = false;

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
        title: const Text('创建投票'),
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
              label: Text(publishing ? '发布中...' : '发布投票'),
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
                    '先写问题和选项，高级匿名设置已折叠；互动开关发布后在详情页管理。',
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
                    '投票内容',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '补充描述'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '可在描述中输入 #话题，带标签更容易被看到',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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
                  Row(
                    children: [
                      Text(
                        '投票配图',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '/3',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (imageUrls.isNotEmpty) ...[
                    Row(
                      children: [
                        for (final url in imageUrls)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => imageUrls.remove(url)),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        for (var i = imageUrls.length; i < 3; i++)
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: uploadingImage || imageUrls.length >= 3
                        ? null
                        : pickPollImage,
                    icon: uploadingImage
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(uploadingImage ? '上传中...' : '添加图片（最多 3 张）'),
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
                    '投票选项',
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
                          labelText: '选项 ${i + 1}',
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
                        label: const Text('添加选项'),
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
                        label: const Text('移除'),
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
                    title: const Text('截止时间'),
                    subtitle: Text(
                      endAt == null
                          ? '长期有效'
                          : DateFormat('yyyy-MM-dd HH:mm').format(endAt!),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: pickEndTime,
                  ),
                  const Divider(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text('高级设置'),
                    subtitle: const Text('匿名发布、匿名投票与匿名评论'),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isAnonymous,
                        onChanged: (value) =>
                            setState(() => isAnonymous = value),
                        title: const Text('匿名发布'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: allowAnonymousVote,
                        onChanged: (value) =>
                            setState(() => allowAnonymousVote = value),
                        title: const Text('允许匿名投票'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: allowAnonymousComment,
                        onChanged: (value) =>
                            setState(() => allowAnonymousComment = value),
                        title: const Text('允许匿名评论'),
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
        title: '还差一步',
        message: '请填写标题，并至少提供 2 个选项',
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
            topicNames: extractTopicNames(description.text),
            isAnonymous: isAnonymous,
            allowAnonymousVote: allowAnonymousVote,
            allowAnonymousComment: allowAnonymousComment,
            allowComment: allowComment,
            allowLike: allowLike,
            allowShare: allowShare,
            imageUrls: imageUrls,
            endAt: endAt,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => publishing = false);
      showAppToast(
        context,
        title: '发布失败',
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
      title: '发布成功',
      message: '你的投票已进入首页',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF16A34A),
    );
    context.go('/home');
  }

  Future<void> pickPollImage() async {
    if (imageUrls.length >= 3 || uploadingImage) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => uploadingImage = true);
    try {
      final url = await ref.read(appStateProvider).uploadImage(picked.path);
      if (!mounted) return;
      setState(() => imageUrls.add(url));
      showAppToast(
        context,
        title: '图片已上传',
        message: '发布后会随投票一起展示',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      );
    } catch (error) {
      if (!mounted) return;
      showAppToast(
        context,
        title: '图片上传失败',
        message: '$error'.replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFDC2626),
      );
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
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
  late Future<List<DiscoverTopic>> topicsFuture;
  late Future<List<Poll>> hotPollsFuture;

  @override
  void initState() {
    super.initState();
    topicsFuture = ref.read(appStateProvider).fetchDiscoverTopics();
    hotPollsFuture = ref.read(appStateProvider).fetchHotPolls();
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = query.text.trim().isNotEmpty;
    return PopScope(
      canPop: !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && searching) {
          query.clear();
          FocusScope.of(context).unfocus();
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: appPageBackground(context),
        appBar: AppBar(
          backgroundColor: appPageBackground(context),
          surfaceTintColor: Colors.transparent,
          title: const Text('发现'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            TextField(
              controller: query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: '搜投票、搜用户',
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
                        title: '投票结果',
                        action: '${result.polls.length} 条',
                      ),
                      if (result.polls.isEmpty)
                        const EmptyState(
                          icon: Icons.search_off,
                          text: '没有找到相关投票',
                        )
                      else
                        ...result.polls.map(
                          (poll) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PollCard(poll: poll, homeFeed: true),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _DiscoverSectionTitle(
                        title: '用户结果',
                        action: '${result.users.length} 位',
                      ),
                      if (result.users.isEmpty)
                        const EmptyState(
                          icon: Icons.person_search_outlined,
                          text: '没有找到相关用户',
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
              const _DiscoverSectionTitle(title: '热门话题', action: '实时'),
              FutureBuilder<List<DiscoverTopic>>(
                future: topicsFuture,
                builder: (context, snapshot) {
                  const fallbackTopics = [
                    '世界杯',
                    '苹果vs安卓',
                    '动漫角色',
                    '职场选择',
                    '恋爱观点',
                    '毕业季',
                    '周末去哪',
                    '游戏阵营',
                  ];
                  final topics = snapshot.data
                      ?.map((topic) => topic.name)
                      .where((name) => name.trim().isNotEmpty)
                      .take(12)
                      .toList();
                  return _TopicCloud(
                    topics: topics == null || topics.isEmpty
                        ? fallbackTopics
                        : topics,
                    onSelected: (topic) => setState(() => query.text = topic),
                  );
                },
              ),
              const SizedBox(height: 22),
              const _DiscoverSectionTitle(title: '分类', action: '探索'),
              _CategoryGrid(
                onSelected: (category) => setState(() => query.text = category),
              ),
              const SizedBox(height: 22),
              const _DiscoverSectionTitle(title: '排行榜', action: '高热度'),
              FutureBuilder<List<Poll>>(
                future: hotPollsFuture,
                builder: (context, snapshot) {
                  final ranking = snapshot.data ?? const <Poll>[];
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (ranking.isEmpty) {
                    return const EmptyState(
                      icon: Icons.local_fire_department_outlined,
                      text: '暂无真实热榜数据',
                    );
                  }
                  return Column(
                    children: ranking
                        .take(5)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => _RankingTile(
                            rank: entry.key + 1,
                            poll: entry.value,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
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
    (Icons.memory_rounded, '科技', Color(0xFF2563EB)),
    (Icons.sports_esports_rounded, '游戏', Color(0xFF7C3AED)),
    (Icons.emoji_events_rounded, '体育', Color(0xFF16A34A)),
    (Icons.movie_filter_rounded, '娱乐', Color(0xFFDB2777)),
    (Icons.local_cafe_rounded, '生活', Color(0xFFF59E0B)),
    (Icons.favorite_rounded, '情感', Color(0xFFEF4444)),
    (Icons.public_rounded, '社会', Color(0xFF0F766E)),
    (Icons.directions_car_rounded, '汽车', Color(0xFF475569)),
    (Icons.school_rounded, '校园', Color(0xFF0891B2)),
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
    final heat = poll.voteCount + poll.likeCount + poll.commentCount;
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
                        '${poll.voteCount} 人参与 · ${poll.commentCount} 评论 · 热度 $heat',
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
                label: const Text('关注'),
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
  Timer? notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(appStateProvider);
      await state.syncNotifications();
    });
    notificationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.read(appStateProvider).syncNotifications();
    });
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final settings = appState.userSettings;
    final notifications = appState.notifications.where((item) {
      if (!settings.notifyLikes && item.type.contains('LIKED')) return false;
      if (!settings.notifyComments &&
          (item.type.contains('COMMENT') || item.type.contains('REPLY'))) {
        return false;
      }
      if (!settings.notifyFollows && item.type.contains('FOLLOW')) return false;
      if (!settings.notifyReports && item.type.contains('REPORT')) return false;
      return true;
    }).toList();
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
        title: const Text('通知中心'),
        actions: [
          TextButton(
            onPressed: () => ref.read(appStateProvider).markNotificationsRead(),
            child: const Text('全部已读'),
          ),
        ],
      ),
      body: ZhandeRefreshIndicator(
        onRefresh: () => ref.read(appStateProvider).syncNotifications(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
          children: [
            Row(
              children: [
                Expanded(
                  child: _NotificationTab(
                    label: '系统消息',
                    count: unreadSystem,
                    selected: tab == 0,
                    onTap: () => setState(() => tab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NotificationTab(
                    label: '互动消息',
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
                text: tab == 0 ? '暂无系统消息' : '暂无互动消息',
              )
            else
              ...currentItems.map(
                (item) => _NotificationTile(
                  item: item,
                  system: tab == 0,
                  onTap: () => _openNotification(item),
                  onLongPress: () => _muteNotificationType(item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(AppNotification item) async {
    await ref.read(appStateProvider).markNotificationRead(item);
    final pollId = item.targetType == 'POLL'
        ? item.targetId
        : item.targetPollId;
    if (pollId != null && mounted) {
      context.push('/poll/$pollId');
      return;
    }
    if (item.targetType == 'USER' && item.targetId != null && mounted) {
      DemoUser? user;
      for (final candidate in ref.read(appStateProvider).users) {
        if (candidate.id == item.targetId) {
          user = candidate;
          break;
        }
      }
      if (user != null) context.push('/user/${user.uid}');
    }
  }

  Future<void> _muteNotificationType(AppNotification item) async {
    final state = ref.read(appStateProvider);
    String? key;
    String label = '\u8FD9\u7C7B\u901A\u77E5';
    if (item.type.contains('LIKED')) {
      key = 'notifyLikes';
      label = '\u70B9\u8D5E\u901A\u77E5';
    } else if (item.type.contains('COMMENT') || item.type.contains('REPLY')) {
      key = 'notifyComments';
      label = '\u8BC4\u8BBA\u901A\u77E5';
    } else if (item.type.contains('FOLLOW')) {
      key = 'notifyFollows';
      label = '\u5173\u6CE8\u901A\u77E5';
    } else if (item.type.contains('REPORT')) {
      key = 'notifyReports';
      label = '\u4E3E\u62A5\u901A\u77E5';
    }
    if (key == null) return;
    await state.updateUserSettings({key: false});
    if (!mounted) return;
    showAppToast(
      context,
      title: '\u5DF2\u5173\u95ED$label',
      message:
          '\u53EF\u5728\u8BBE\u7F6E-\u901A\u77E5\u4E2D\u91CD\u65B0\u5F00\u542F',
      icon: Icons.notifications_off_rounded,
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
    required this.onLongPress,
  });

  final AppNotification item;
  final bool system;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
          onLongPress: onLongPress,
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
    if (text.contains('评论') || text.contains('回复')) {
      return Icons.mode_comment_rounded;
    }
    if (text.contains('点赞')) return Icons.thumb_up_alt_rounded;
    if (text.contains('关注')) return Icons.person_add_alt_1_rounded;
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
        value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}万' : '$value';
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('我的'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          // Profile info section - tap to edit
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/settings/edit-profile'),
              child: _ProfilePanel(
                child: Row(
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
                          Text(
                            state.currentUser.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dark ? const Color(0xFFFAFAFA) : const Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            state.currentUser.bio.isEmpty ? '还没有个人简介' : state.currentUser.bio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UID: ${state.currentUser.uid}',
                            style: TextStyle(
                              color: dark ? const Color(0xFF52525B) : const Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Stats row
          _ProfilePanel(
            child: Row(
              children: [
                Expanded(child: _ProfileStat(
                  label: '发布',
                  value: compactCount(stats.pollCount),
                  onTap: () => showPollListSheet(context, ref, '我的投票', ref.read(appStateProvider).fetchMyPolls),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ProfileStat(
                  label: '关注',
                  value: compactCount(stats.followingCount),
                  onTap: () => showUserListSheet(context, ref, '我关注的人', ref.read(appStateProvider).fetchFollowing),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ProfileStat(
                  label: '粉丝',
                  value: compactCount(stats.followerCount),
                  onTap: () => showUserListSheet(context, ref, '我的粉丝', ref.read(appStateProvider).fetchFollowers),
                )),
                const SizedBox(width: 8),
                Expanded(child: _ProfileStat(
                  label: '获赞',
                  value: compactCount(stats.receivedLikes),
                  onTap: () => showLikeRecognitionDialog(context, stats.receivedLikes),
                )),
              ],
            ),
          ),
          if (state.currentUser.canAdmin) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.push('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('进入管理后台'),
            ),
          ],
          const SizedBox(height: 14),
          // Menu section 1
          _ProfilePanel(
            child: Column(
              children: [
                _ProfileActionTile(
                  icon: Icons.how_to_vote_outlined,
                  title: '我的投票',
                  subtitle: '${stats.pollCount} 条已发布',
                  onTap: () => showPollListSheet(context, ref, '我的投票', ref.read(appStateProvider).fetchMyPolls),
                ),
                _ProfileActionTile(
                  icon: Icons.bookmark_border_rounded,
                  title: '我的收藏',
                  subtitle: '${stats.favoriteCount} 条收藏内容',
                  onTap: () => showPollListSheet(context, ref, '收藏', ref.read(appStateProvider).fetchFavoritePolls),
                ),
                _ProfileActionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  title: '我的关注',
                  subtitle: '${stats.followingCount} 位关注',
                  onTap: () => showUserListSheet(context, ref, '关注列表', ref.read(appStateProvider).fetchFollowing),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Menu section 2
          _ProfilePanel(
            child: Column(
              children: [
                _ProfileActionTile(
                  icon: Icons.block_outlined,
                  title: '黑名单',
                  subtitle: '查看和移除屏蔽用户',
                  onTap: () => showUserListSheet(context, ref, '黑名单', ref.read(appStateProvider).fetchBlockedUsers, allowUnblock: true),
                ),
                _ProfileActionTile(
                  icon: Icons.feedback_outlined,
                  title: '问题反馈',
                  subtitle: '提交 Bug、建议或体验问题',
                  onTap: () => showFeedbackDialog(context, ref),
                ),
                _ProfileActionTile(
                  icon: Icons.rule_rounded,
                  title: '站队规则中心',
                  subtitle: '了解社区规则和注意事项',
                  onTap: () => context.push('/rules'),
                ),
                _ProfileActionTile(
                  icon: Icons.info_outline_rounded,
                  title: '关于站队',
                  subtitle: '版本、联系与更多信息',
                  onTap: () => context.push('/about'),
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
    if (user.uid != state.currentUser.uid) {
      try {
        final following = await state.fetchFollowing();
        user.isFollowing = following.any((item) => item.uid == user.uid);
      } catch (_) {}
      try {
        final blocked = await state.fetchBlockedUsers();
        user.isBlocked = blocked.any((item) => item.uid == user.uid);
      } catch (_) {}
    }
    final polls = user.isBlocked
        ? <Poll>[]
        : await state.fetchUserPolls(widget.uid);
    return (user, polls);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() { future = next; });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final dark = isDarkUi(context);
    String compactCount(int value) =>
        value >= 10000 ? '${(value / 10000).toStringAsFixed(1)}万' : '$value';
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('用户主页'),
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
              text: '用户主页加载失败',
            );
          }
          final user = snapshot.data!.$1;
          final userPolls = snapshot.data!.$2;
          final title = state.titleForUser(user);
          final isSelf = user.uid == state.currentUser.uid;
          return ZhandeRefreshIndicator(
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
                                  user.bio.isEmpty ? '还没有个性签名' : user.bio,
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
                              label: '发布',
                              value: compactCount(user.pollCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '关注',
                              value: compactCount(user.followingCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '粉丝',
                              value: compactCount(user.followerCount),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ProfileStat(
                              label: '获赞',
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
                                  if (user.isFollowing) {
                                    await state.unfollowUser(user);
                                  } else {
                                    await state.followUser(user);
                                  }
                                  if (context.mounted) {
                                    showAppToast(
                                      context,
                                      title: user.isFollowing ? '已关注' : '已取消关注',
                                      message: user.isFollowing
                                          ? '你已关注 '
                                          : '已取消关注',
                                      icon: user.isFollowing
                                          ? Icons.check_circle_rounded
                                          : Icons.person_remove_alt_1_rounded,
                                    );
                                  }
                                  setState(() {});
                                },
                                icon: Icon(
                                  user.isFollowing
                                      ? Icons.check_circle_rounded
                                      : Icons.person_add_alt_1_rounded,
                                ),
                                label: Text(user.isFollowing ? '已关注' : '关注'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: user.isBlocked
                                    ? null
                                    : () async {
                                        await state.blockUser(user);
                                        if (context.mounted) {
                                          showAppToast(
                                            context,
                                            title: '已加入黑名单',
                                            message: '你将减少看到该用户内容',
                                            icon: Icons.block_outlined,
                                            color: const Color(0xFFDC2626),
                                          );
                                        }
                                        setState(() {});
                                      },
                                icon: const Icon(Icons.block_outlined),
                                label: Text(user.isBlocked ? '已拉黑' : '拉黑'),
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
                  '发布的站队',
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
                    text: '还没有发布投票',
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
  const _ProfileStat({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
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
                  color: dark
                      ? const Color(0xFFFAFAFA)
                      : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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

Future<void> showUpdateDialog(
  BuildContext context,
  Map<String, dynamic> update,
) async {
  final force = update['forceUpdate'] == true;
  final title = update['title']?.toString().trim().isNotEmpty == true
      ? update['title'].toString()
      : '\u53D1\u73B0\u65B0\u7248\u672C';
  final notes = update['releaseNotes']?.toString() ?? '';
  final url = update['updateUrl']?.toString() ?? '';
  await showDialog<void>(
    context: context,
    barrierDismissible: !force,
    builder: (dialogContext) => PopScope(
      canPop: !force,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          notes.isEmpty
              ? '\u65B0\u7248\u672C\u5DF2\u51C6\u5907\u597D\uFF0C\u5EFA\u8BAE\u5C3D\u5FEB\u66F4\u65B0\u4F53\u9A8C\u3002'
              : notes,
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('\u7A0D\u540E\u518D\u8BF4'),
            ),
          FilledButton(
            onPressed: () async {
              if (url.isNotEmpty) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
              if (!force && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(
              force ? '\u7ACB\u5373\u66F4\u65B0' : '\u53BB\u66F4\u65B0',
            ),
          ),
        ],
      ),
    ),
  );
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
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 132),
        children: [
          // 账号与安全
          _SectionHeader(text: '账号与安全'),
          const SizedBox(height: 8),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: '个人资料',
                  subtitle: '头像、昵称、账号与简介',
                  onTap: () => context.push('/settings/edit-profile'),
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: '修改密码',
                  subtitle: '验证旧密码后更新登录密码',
                  onTap: () => showPasswordDialog(context, ref),
                ),
                SettingsTile(
                  icon: Icons.block_outlined,
                  title: '黑名单管理',
                  subtitle: '查看和移除已屏蔽用户',
                  onTap: () => showUserListSheet(context, ref, '黑名单管理', ref.read(appStateProvider).fetchBlockedUsers, allowUnblock: true),
                ),
                SettingsTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '清除缓存',
                  subtitle: '清理本地缓存数据',
                  onTap: () {
                    showAppToast(context, title: '缓存已清除', message: '本地缓存已清理', icon: Icons.check_circle_rounded, color: Color(0xFF16A34A));
                  },
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 通用
          _SectionHeader(text: '通用'),
          const SizedBox(height: 8),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: '深色模式',
                  subtitle: state.userSettings.darkMode ? '已开启' : '已关闭',
                  onTap: () => state.updateUserSettings({'darkMode': !state.userSettings.darkMode}),
                ),
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: '通知设置',
                  subtitle: '点赞、评论、关注、举报处理通知',
                  onTap: () => showNotificationSettings(context, ref),
                ),
                SettingsTile(
                  icon: Icons.screenshot_monitor_outlined,
                  title: '截图分享文案',
                  subtitle: state.userSettings.screenshotShareHint ? '检测截图后显示分享提示' : '已关闭截图提示',
                  onTap: () => state.updateUserSettings({'screenshotShareHint': !state.userSettings.screenshotShareHint}),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 社区与规则
          _SectionHeader(text: '社区与规则'),
          const SizedBox(height: 8),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.rule_rounded,
                  title: '站队规则中心',
                  subtitle: '了解社区规则和注意事项',
                  onTap: () => context.push('/rules'),
                ),
                SettingsTile(
                  icon: Icons.feedback_outlined,
                  title: '举报与反馈',
                  subtitle: '提交 Bug、建议或举报违规内容',
                  onTap: () => showFeedbackDialog(context, ref),
                ),
                SettingsTile(
                  icon: Icons.warning_amber_rounded,
                  title: '防诈骗提示',
                  subtitle: '保护财产安全，警惕网络诈骗',
                  onTap: () => context.push('/rules'),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 法律与协议
          _SectionHeader(text: '法律与协议'),
          const SizedBox(height: 8),
          _ProfilePanel(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: '用户服务协议',
                  subtitle: '查看服务条款与使用规则',
                  onTap: () => showSimpleSheet(context, '用户服务协议', agreementText),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私政策',
                  subtitle: '了解我们如何保护你的数据',
                  onTap: () => showSimpleSheet(context, '隐私政策', aboutText),
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: '关于站队',
                  subtitle: '版本、联系与更多信息',
                  onTap: () => context.push('/about'),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // 退出登录
          _ProfilePanel(
            child: SettingsTile(
              icon: Icons.logout_rounded,
              title: '退出登录',
              subtitle: '退出当前账号并返回登录页',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

const aboutText = '''
站队是一款围绕观点、选择和匿名表达的投票社区 App。

当前版本定位为 MVP 1.0：支持发布投票、参与投票、评论互动、关注收藏、通知中心、举报审核、权限后台、广告与公告等核心闭环。

我们希望它既能保留匿名表达的轻松感，也能通过举报、审核、封禁、禁止互动等机制维持社区秩序。

版本：1.0.0 本地测试版
技术栈：Flutter + NestJS + Prisma + PostgreSQL
''';

const agreementText = '''
欢迎使用站队。使用本应用即表示你理解并同意以下规则：

1. 账号与安全
你需要对自己的账号行为负责。请勿共享账号、盗用他人账号、恶意注册或绕过平台限制。

2. 内容发布
你可以围绕观点、选择和公共话题发布投票，但不得发布违法违规、暴力恐吓、色情低俗、诈骗引流、恶意攻击、侵犯隐私、侵犯知识产权或诱导刷票的内容。

3. 匿名功能
匿名发布、匿名投票和匿名评论仅用于降低表达压力，不代表可以逃避社区规则。平台仍会保留必要的审核和风控能力。

4. 互动规则
请尊重不同观点。禁止辱骂、人身攻击、骚扰、恶意刷赞、刷票、批量举报或利用漏洞影响社区秩序。

5. 举报与管理
用户可以举报投票、评论或用户。管理员可根据规则删除内容、禁止互动、封禁或禁言账号，并向相关用户发送处理通知。

6. 数据与隐私
平台会保存账号资料、投票记录、关注收藏、通知和必要的操作日志，用于提供服务、保障安全和处理争议。头像、昵称、简介等公开资料会在相应页面展示。

7. 服务变更
应用仍处于第一版测试阶段，功能、规则和展示方式可能持续调整。重大变化会通过公告或系统消息提示。

请理性表达，认真站队。
''';

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
        title: '头像已更新',
        message: '个人资料已同步保存',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
      );
    }
  } catch (error) {
    if (context.mounted) {
      showAppToast(
        context,
        title: '上传失败',
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
  final nickname = TextEditingController();
  final bio = TextEditingController(text: state.currentUser.bio);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('修改资料'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: username,
            decoration: const InputDecoration(
              labelText: '账号',
              helperText: '至少 5 位，不能纯数字或符号开头',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nickname,
            decoration: const InputDecoration(
              labelText: '昵称',
              helperText: '2-8 个字，仅用于展示',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bio,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '简介'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('\u53D6\u6D88'),
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
                  title: '保存失败',
                  message: '$error',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                );
              }
            }
          },
          child: const Text('保存'),
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
      title: const Text('修改密码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: '旧密码'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: '新密码'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('\u53D6\u6D88'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              final state = ref.read(appStateProvider);
              if (oldPassword.text.isEmpty) {
                throw const UserFacingException('请输入旧密码');
              }
              if (newPassword.text.length < 6) {
                throw const UserFacingException('新密码长度至少 6 位');
              }
              await state.api.dio.patch(
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
                  title: '密码已更新',
                  message: '为了账号安全，请使用新密码重新登录',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                );
              }
              await state.clearLocalSession();
              if (context.mounted) context.go('/login');
            } catch (error) {
              if (context.mounted) {
                showAppToast(
                  context,
                  title: '修改失败',
                  message: friendlyErrorMessage(error),
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                );
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

Future<void> showFeedbackDialog(BuildContext context, WidgetRef ref) async {
  final content = TextEditingController();
  final contact = TextEditingController();
  var category = 'bug';
  var includeLogs = true;
  var submitting = false;
  final rootContext = context;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        final maxHeight = MediaQuery.of(context).size.height * 0.78;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.feedback_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '问题反馈',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '告诉我们你遇到的问题或希望改进的地方',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '反馈类型',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(
                            hintText: '选择反馈类型',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'bug', child: Text('问题/Bug 报告')),
                            DropdownMenuItem(value: 'feature', child: Text('功能建议')),
                            DropdownMenuItem(value: 'experience', child: Text('体验反馈')),
                            DropdownMenuItem(value: 'other', child: Text('其他')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => category = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '描述你的反馈',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: content,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: '请详细描述你遇到的问题或建议...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '联系方式（选填）',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contact,
                          decoration: const InputDecoration(
                            hintText: '邮箱或微信号，方便我们联系你',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: includeLogs,
                                onChanged: (v) => setState(() => includeLogs = v ?? true),
                                activeColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                '同时提交运行日志，帮助定位问题',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: submitting
                            ? null
                            : () async {
                                setState(() => submitting = true);
                                try {
                                  await ref.read(appStateProvider).submitFeedback(
                                    content: content.text,
                                    contact: contact.text,
                                    category: category,
                                    includeLogs: includeLogs,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (rootContext.mounted) {
                                    showAppToast(
                                      rootContext,
                                      title: '反馈已提交',
                                      message: '感谢你的反馈，我们会认真处理',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF16A34A),
                                    );
                                  }
                                } catch (e) {
                                  setState(() => submitting = false);
                                  if (rootContext.mounted) {
                                    showAppToast(
                                      rootContext,
                                      title: '提交失败',
                                      message: '$e',
                                      icon: Icons.error_outline_rounded,
                                      color: const Color(0xFFDC2626),
                                    );
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(submitting ? '提交中...' : '提交反馈'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              '通知设置',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: settings.notifyLikes,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyLikes': value}),
              title: const Text('点赞通知'),
            ),
            SwitchListTile(
              value: settings.notifyComments,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyComments': value}),
              title: const Text('评论与回复通知'),
            ),
            SwitchListTile(
              value: settings.notifyFollows,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyFollows': value}),
              title: const Text('关注通知'),
            ),
            SwitchListTile(
              value: settings.notifyReports,
              onChanged: (value) =>
                  state.updateUserSettings({'notifyReports': value}),
              title: const Text('举报处理通知'),
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
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (pageContext) => Scaffold(
        backgroundColor: appPageBackground(pageContext),
        appBar: AppBar(
          backgroundColor: appPageBackground(pageContext),
          surfaceTintColor: Colors.transparent,
          title: Text(title),
        ),
        body: FutureBuilder<List<Poll>>(
          future: loader(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                icon: Icons.error_outline_rounded,
                text: '加载失败，请稍后重试',
              );
            }
            if (items.isEmpty) {
              return const EmptyState(icon: Icons.inbox_outlined, text: '暂无内容');
            }
            return ZhandeRefreshIndicator(
              onRefresh: () async {
                await loader();
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PollCard(poll: items[index], homeFeed: true),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Future<void> showLikeRecognitionDialog(BuildContext context, int count) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFE4E6), Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFE11D48),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '\u4F60\u6536\u5230\u7684\u8BA4\u53EF',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFFE11D48),
                fontSize: 42,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count == 0
                  ? '\u6682\u65F6\u8FD8\u6CA1\u6709\u6536\u5230\u70B9\u8D5E\uFF0C\u53D1\u5E03\u4E00\u4E2A\u6709\u4E89\u8BAE\u7684\u7AD9\u961F\u8BD5\u8BD5\u3002'
                  : '\u4F60\u7684\u5185\u5BB9\u5DF2\u7ECF\u83B7\u5F97 $count \u6B21\u70B9\u8D5E\uFF0C\u8BF4\u660E\u6709\u4EBA\u8BA4\u540C\u6216\u88AB\u4F60\u7684\u95EE\u9898\u6253\u52A8\u3002',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('\u77E5\u9053\u4E86'),
              ),
            ),
          ],
        ),
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
                const EmptyState(icon: Icons.people_outline, text: '暂无用户')
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
                              child: const Text('移除'),
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
      title: const Text('编辑帖子'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '描述'),
          ),
          const SizedBox(height: 8),
          const Text(
            '选项不可编辑',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('\u53D6\u6D88'),
        ),
        FilledButton(
          onPressed: () {
            ref
                .read(appStateProvider)
                .editPollContent(poll, title.text, description.text);
            Navigator.pop(dialogContext);
          },
          child: const Text('保存'),
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
    final tabs = <Tab>[const Tab(text: '举报'), const Tab(text: '用户')];
    final views = <Widget>[const _ReportsAdminView(), const _UsersAdminView()];
    if (state.currentUser.canAudit) {
      tabs.add(const Tab(text: '审核'));
      views.add(const _ReviewAdminView());
    }
    if (state.currentUser.canManageAds) {
      tabs.add(const Tab(text: '广告'));
      views.add(const _AdsAdminView());
    }
    if (state.currentUser.canManageRoles) {
      tabs.add(const Tab(text: '权限用户'));
      views.add(const _RolesAdminView());
    }
    if (state.currentUser.isCreatorAdmin) {
      tabs.add(const Tab(text: '\u7CFB\u7EDF'));
      views.add(const _SystemAdminView());
    }
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F9FC),
          surfaceTintColor: Colors.transparent,
          title: const Text('管理控制台'),
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
      return const EmptyState(icon: Icons.flag_outlined, text: '暂无举报');
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
            ? (comment == null ? '评论已删除' : '评论：${comment.content}')
            : (poll?.title ?? '帖子已删除');
        return SoftPanel(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: handled ? '已处理' : '未处理',
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
                    '所属帖子：${poll.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '原因：${reportReasonLabel(report.reason)} · 举报人：${report.reporter.nickname}',
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
                      label: const Text('打开帖子'),
                    ),
                    if (isCommentReport) ...[
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'delete'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('删除评论'),
                      ),
                      TextButton(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'reject'),
                        child: const Text('驳回'),
                      ),
                    ] else ...[
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'lock'),
                        icon: const Icon(Icons.lock_outline, size: 16),
                        label: const Text('受理禁止互动'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'delete'),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('受理删除'),
                      ),
                      TextButton(
                        onPressed: handled
                            ? null
                            : () => state.handleReport(report, 'reject'),
                        child: const Text('驳回'),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider).syncAdminUsers();
    });
  }

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
            onChanged: (value) {
              setState(() {});
              ref.read(appStateProvider).syncAdminUsers(search: value);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '搜索用户 ID',
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
        final canMute =
            state.hasPermission(AppPermission.userMute) &&
            !user.isCreatorAdmin &&
            user.id != state.currentUser.id;
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
                      label: user.isCurrentlyMuted
                          ? user.muteLabel
                          : '\u6B63\u5E38',
                      color: user.isCurrentlyMuted
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
                    if (user.isCurrentlyMuted)
                      OutlinedButton(
                        onPressed: canMute
                            ? () => state.adminUserAction(user, 'unban')
                            : null,
                        child: const Text('\u89E3\u7981'),
                      )
                    else
                      PopupMenuButton<int>(
                        enabled: canMute,
                        tooltip: '\u7981\u8A00',
                        onSelected: (days) => state.adminUserAction(
                          user,
                          'ban',
                          muteDays: days == 0 ? null : days,
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 1,
                            child: Text('\u7981\u8A00 1 \u5929'),
                          ),
                          PopupMenuItem(
                            value: 3,
                            child: Text('\u7981\u8A00 3 \u5929'),
                          ),
                          PopupMenuItem(
                            value: 7,
                            child: Text('\u7981\u8A00 7 \u5929'),
                          ),
                          PopupMenuItem(
                            value: 30,
                            child: Text('\u7981\u8A00 1 \u4E2A\u6708'),
                          ),
                          PopupMenuItem(
                            value: 365,
                            child: Text('\u7981\u8A00 1 \u5E74'),
                          ),
                          PopupMenuItem(
                            value: 0,
                            child: Text('\u6C38\u4E45\u7981\u8A00'),
                          ),
                        ],
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: canMute
                                ? const Color(0xFFFFF1F2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: canMute
                                  ? const Color(0xFFFDA4AF)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            '\u7981\u8A00',
                            style: TextStyle(
                              color: canMute
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    if (state.currentUser.isCreatorAdmin)
                      OutlinedButton(
                        onPressed: canChangeRole
                            ? () => showAssignTitleDialog(context, ref, user)
                            : null,
                        child: Text(title == null ? '设权限' : '改权限'),
                      ),
                    if (state.currentUser.isCreatorAdmin && title != null)
                      OutlinedButton(
                        onPressed: canChangeRole
                            ? () => state.removeTitleFromUser(user)
                            : null,
                        child: const Text('解除权限'),
                      ),
                    if (canDelete)
                      TextButton(
                        onPressed: () => state.adminUserAction(user, 'delete'),
                        child: const Text('删除'),
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
      title: Text('设置 ${user.nickname} 的权限'),
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
                Text('${title.permissions.length} 项权限'),
              ],
            ),
          ),
        SimpleDialogOption(
          onPressed: () {
            state.removeTitleFromUser(user);
            Navigator.pop(dialogContext);
          },
          child: const Text('变为普通用户'),
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
      return const EmptyState(icon: Icons.fact_check_outlined, text: '暂无审核事项');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '审核处理',
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
                          label: poll.editRequested ? '未处理' : '已处理',
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
                      '${poll.voteCount} 人参与 · ${poll.commentCount} 条评论 · ${poll.interactionLocked ? '已禁止互动' : '可互动'}',
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
                          label: const Text('打开'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.interactionLocked
                              ? null
                              : () => state.lockPollComments(poll.id),
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text('禁止互动'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.interactionLocked
                              ? () => state.unlockPollComments(poll.id)
                              : null,
                          icon: const Icon(Icons.lock_open, size: 16),
                          label: const Text('解除禁互'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: poll.editRequested
                              ? () => state.approvePollEdit(poll)
                              : null,
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('通过编辑申请'),
                        ),
                        TextButton(
                          onPressed: () => state.deletePoll(poll.id),
                          child: const Text('删除'),
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
          label: const Text('新建/修改广告'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => showAnnouncementDialog(
            context,
            ref,
            state.startupAnnouncement,
            '进入 App 弹窗公告',
          ),
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('设置弹窗公告'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () => showAnnouncementDialog(
            context,
            ref,
            state.marqueeAnnouncement,
            '主页跑马灯公告',
            marquee: true,
          ),
          icon: const Icon(Icons.view_stream_outlined),
          label: const Text('设置跑马灯公告'),
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

class _SystemAdminView extends ConsumerStatefulWidget {
  const _SystemAdminView();

  @override
  ConsumerState<_SystemAdminView> createState() => _SystemAdminViewState();
}

class _SystemAdminViewState extends ConsumerState<_SystemAdminView> {
  late Future<Map<String, dynamic>> configFuture;
  late Future<List<Map<String, dynamic>>> feedbackFuture;

  @override
  void initState() {
    super.initState();
    configFuture = ref.read(appStateProvider).fetchUpdateConfig();
    feedbackFuture = ref.read(appStateProvider).fetchAdminFeedback();
  }

  void reload() {
    setState(() {
      configFuture = ref.read(appStateProvider).fetchUpdateConfig();
      feedbackFuture = ref.read(appStateProvider).fetchAdminFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: configFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final data = snapshot.data!;
            return SoftPanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u7248\u672C\u66F4\u65B0',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\u5F53\u524D\u6700\u65B0\u7248\u672C\uFF1A${data['latestVersion'] ?? '-'}  build ${data['latestBuild'] ?? '-'}',
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () async {
                        await showUpdateConfigDialog(context, ref, data);
                        reload();
                      },
                      icon: const Icon(Icons.system_update_rounded),
                      label: const Text(
                        '\u521B\u5EFA/\u4FEE\u6539\u66F4\u65B0',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: feedbackFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            return SoftPanel(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u7528\u6237\u53CD\u9988',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.connectionState != ConnectionState.done)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (items.isEmpty)
                      const EmptyState(
                        icon: Icons.feedback_outlined,
                        text: '\u6682\u65E0\u53CD\u9988',
                      )
                    else
                      ...items.take(30).map((item) {
                        final user =
                            item['user'] as Map<String, dynamic>? ?? const {};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['category'] ?? 'feedback'} · ${user['nickname'] ?? '用户'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text('${item['content'] ?? ''}'),
                                if ((item['contact'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    '\u8054\u7CFB\u65B9\u5F0F\uFF1A${item['contact']}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> showUpdateConfigDialog(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> data,
) async {
  final latestVersion = TextEditingController(
    text: data['latestVersion']?.toString() ?? appVersionName,
  );
  final latestBuild = TextEditingController(
    text: data['latestBuild']?.toString() ?? '$appBuildNumber',
  );
  final minBuild = TextEditingController(
    text: data['minBuild']?.toString() ?? '$appBuildNumber',
  );
  final title = TextEditingController(
    text: data['title']?.toString() ?? '\u53D1\u73B0\u65B0\u7248\u672C',
  );
  final notes = TextEditingController(
    text: data['releaseNotes']?.toString() ?? '',
  );
  final url = TextEditingController(text: data['updateUrl']?.toString() ?? '');
  var enabled = data['enabled'] == true;
  var force = data['forceUpdate'] == true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('\u7248\u672C\u66F4\u65B0\u914D\u7F6E'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
                title: const Text('\u542F\u7528\u66F4\u65B0\u5F39\u7A97'),
              ),
              SwitchListTile(
                value: force,
                onChanged: (value) => setState(() => force = value),
                title: const Text('\u5F3A\u5236\u66F4\u65B0'),
              ),
              TextField(
                controller: latestVersion,
                decoration: const InputDecoration(
                  labelText: '\u6700\u65B0\u7248\u672C',
                ),
              ),
              TextField(
                controller: latestBuild,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '\u6700\u65B0 Build',
                ),
              ),
              TextField(
                controller: minBuild,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '\u6700\u4F4E Build',
                ),
              ),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: '\u5F39\u7A97\u6807\u9898',
                ),
              ),
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '\u66F4\u65B0\u5185\u5BB9',
                ),
              ),
              TextField(
                controller: url,
                decoration: const InputDecoration(
                  labelText:
                      '\u66F4\u65B0\u94FE\u63A5/\u4E0B\u8F7D\u76F4\u94FE',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('\u53D6\u6D88'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(appStateProvider).saveUpdateConfig({
                'platform': 'android',
                'latestVersion': latestVersion.text.trim(),
                'latestBuild': int.tryParse(latestBuild.text.trim()) ?? 1,
                'minBuild': int.tryParse(minBuild.text.trim()) ?? 1,
                'forceUpdate': force,
                'enabled': enabled,
                'title': title.text.trim(),
                'releaseNotes': notes.text.trim(),
                'updateUrl': url.text.trim(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              final update = await ref
                  .read(appStateProvider)
                  .checkForUpdate()
                  .catchError((_) => null);
              if (context.mounted) {
                if (update != null) {
                  await showUpdateDialog(context, update);
                } else {
                  showAppToast(
                    context,
                    title: '\u66F4\u65B0\u914D\u7F6E\u5DF2\u4FDD\u5B58',
                    message: enabled
                        ? '\u5F53\u524D\u7248\u672C\u672A\u547D\u4E2D\u66F4\u65B0\u6761\u4EF6'
                        : '\u672A\u542F\u7528\u66F4\u65B0\u5F39\u7A97\uFF0C\u524D\u53F0\u4E0D\u4F1A\u63D0\u793A',
                    icon: Icons.system_update_alt_rounded,
                  );
                }
              }
            },
            child: const Text('\u4FDD\u5B58'),
          ),
        ],
      ),
    ),
  );
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
          label: const Text('添加头衔'),
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
                  '${title.userIds.length} 名用户',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  title.permissions.map(permissionLabel).join('、').isEmpty
                      ? '暂无权限'
                      : title.permissions.map(permissionLabel).join('、'),
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
                          label: const Text('添加用户'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showPermissionPackageDialog(context, ref, title),
                          icon: const Icon(
                            Icons.rule_folder_outlined,
                            size: 16,
                          ),
                          label: const Text('权限包'),
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
                        child: const Text('移除'),
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
  AppPermission.userMute => '禁言解禁',
  AppPermission.userRoleManage => '权限分配',
  AppPermission.userDelete => '删除用户',
  AppPermission.pollDelete => '删除帖子',
  AppPermission.pollLock => '禁止互动',
  AppPermission.pollUnlock => '解除禁互',
  AppPermission.reportHandle => '举报处理',
  AppPermission.auditReview => '内容审核',
  AppPermission.adManage => '广告管理',
  AppPermission.announcementManage => '公告管理',
  AppPermission.titleManage => '头衔管理',
};

Future<void> showCreateTitleDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('添加头衔'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: '头衔名称，例如：版主'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('\u53D6\u6D88'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(appStateProvider).addTitle(controller.text);
            Navigator.pop(dialogContext);
          },
          child: const Text('创建'),
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
      title: Text('添加用户到 ${title.name}'),
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
          title: Text('${title.name} 权限包'),
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
              child: const Text('完成'),
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
  final title = TextEditingController(text: ad?.title ?? '首页顶部广告');
  final body = TextEditingController(text: ad?.body ?? '新的社区活动正在进行');
  final image = TextEditingController(
    text: ad?.imageUrl ?? 'https://picsum.photos/seed/new-vote-ad/900/320',
  );
  var enabled = ad?.enabled ?? true;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('广告设置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '广告标题'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: body,
                decoration: const InputDecoration(labelText: '广告说明'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: image,
                decoration: const InputDecoration(labelText: '图片直连 URL'),
              ),
              SwitchListTile(
                value: enabled,
                onChanged: (value) => setState(() => enabled = value),
                title: const Text('启用显示'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('\u53D6\u6D88'),
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
            child: const Text('保存'),
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
              decoration: const InputDecoration(labelText: '公告标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '公告内容'),
            ),
            SwitchListTile(
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
              title: const Text('开启'),
            ),
            if (!marquee)
              SwitchListTile(
                value: every,
                onChanged: (value) => setState(() => every = value),
                title: const Text('每次进入都弹出'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('\u53D6\u6D88'),
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
            child: const Text('保存'),
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
        title: const Text('创建新权限用户'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: '头衔名称'),
              ),
              CheckboxListTile(
                value: userOps,
                onChanged: (v) => setState(() => userOps = v ?? false),
                title: const Text('用户操作：禁言/解禁'),
              ),
              CheckboxListTile(
                value: postOps,
                onChanged: (v) => setState(() => postOps = v ?? false),
                title: const Text('帖子操作：删除、禁止互动'),
              ),
              CheckboxListTile(
                value: audit,
                onChanged: (v) => setState(() => audit = v ?? false),
                title: const Text('审核权限'),
              ),
              CheckboxListTile(
                value: ads,
                onChanged: (v) => setState(() => ads = v ?? false),
                title: const Text('广告权限'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('\u53D6\u6D88'),
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
            child: const Text('创建'),
          ),
        ],
      ),
    ),
  );
}

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





class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _accountController = TextEditingController();
  bool _saving = false;
  String? _newAvatarPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(appStateProvider).currentUser;
      _nicknameController.text = user.nickname;
      _bioController.text = user.bio;
      _accountController.text = user.username;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked != null) {
      setState(() => _newAvatarPath = picked.path);
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final account = _accountController.text.trim();
    final bio = _bioController.text.trim();

    if (nickname.isEmpty) {
      showAppToast(context, title: '请输入昵称', message: '昵称不能为空', icon: Icons.error_outline_rounded, color: Color(0xFFDC2626));
      return;
    }
    if (account.length < 5) {
      showAppToast(context, title: '账号过短', message: '账号至少需要5位字符', icon: Icons.error_outline_rounded, color: Color(0xFFDC2626));
      return;
    }

    setState(() => _saving = true);
    try {
      final state = ref.read(appStateProvider);
      if (_newAvatarPath != null) {
        await state.updateAvatar(_newAvatarPath!);
      }
      await state.updateAccountProfile(
        username: account,
        nickname: nickname,
        bio: bio,
      );
      if (mounted) {
        showAppToast(context, title: '保存成功', message: '个人资料已更新', icon: Icons.check_circle_rounded, color: Color(0xFF16A34A));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, title: '保存失败', message: '$e', icon: Icons.error_outline_rounded, color: Color(0xFFDC2626));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    final user = ref.watch(appStateProvider).currentUser;

    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('编辑个人资料'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('保存'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // 头像区
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  AppAvatar(
                    name: _newAvatarPath != null ? '新头像' : user.nickname,
                    avatarUrl: _newAvatarPath ?? user.avatarUrl,
                    size: 96,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 表单卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appPanelColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: appPanelBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(text: '账号'),
                const SizedBox(height: 6),
                TextField(
                  controller: _accountController,
                  decoration: const InputDecoration(hintText: '至少5位字符'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: '昵称'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(hintText: '你的公开昵称'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: '个人简介'),
                const SizedBox(height: 6),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(hintText: '一句话介绍自己'),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // UID
          Center(
            child: Text(
              'UID: ${user.uid}',
              style: TextStyle(
                color: dark ? Color(0xFFA1A1AA) : Color(0xFF9CA3AF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}




class RulesCenterScreen extends StatelessWidget {
  const RulesCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('站队规则中心'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _RuleSection(
            title: '平等讨论原则',
            items: [
              '理性表达观点',
              '尊重不同立场',
              '基于事实进行讨论',
              '友善交流',
            ],
            cautionItems: [
              '情绪煽动',
              '群体对立',
              '刻意制造争端',
            ],
            caution: true,
          ),
          const SizedBox(height: 14),
          _RuleSection(
            title: '禁止恶意行为',
            items: [],
            forbidItems: [
              '人身攻击、侮辱、谩骂',
              '恶意挑衅、网络暴力',
              '骚扰他人',
              '造谣传谣',
              '发布违法违规内容',
              '冒充他人身份',
            ],
          ),
          const SizedBox(height: 14),
          _RuleSection(
            title: '防止诈骗与交易风险',
            warning: true,
            items: [],
            forbidItems: [
              '随意添加陌生人的微信、QQ、Telegram 等联系方式进行资金往来',
              '向陌生人转账',
              '参与任何形式的投资、赌博、刷单、代练、兼职返利等可疑活动',
              '轻信高收益、低风险等诱导信息',
            ],
            extra: '站队不提供私下交易担保。发现诈骗内容请立即举报。',
          ),
          const SizedBox(height: 14),
          _RuleSection(
            title: '隐私保护',
            items: [],
            forbidItems: [
              '发布他人真实姓名、电话、身份证、地址等隐私信息',
              '未经允许公开他人聊天记录、照片、视频',
            ],
          ),
          const SizedBox(height: 14),
          _RuleSection(
            title: '未成年人保护',
            items: [],
            forbidItems: [
              '诱导未成年人消费',
              '传播不适合未成年人内容',
              '对未成年人实施骚扰、欺骗、伤害',
            ],
          ),
          const SizedBox(height: 14),
          _RuleSection(
            title: '内容治理措施',
            items: [],
            actionItems: [
              '内容删除',
              '限制展示',
              '功能限制',
              '临时封禁',
              '永久封禁',
              '配合有关部门依法处理',
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD4A8)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\uD83D\uDCA1', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '不同的观点值得被听见，但请始终保持尊重与友善。\n\n在法律法规允许范围内，尊重用户表达不同观点的权利。',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.title,
    this.items = const [],
    this.cautionItems = const [],
    this.forbidItems = const [],
    this.actionItems = const [],
    this.caution = false,
    this.warning = false,
    this.extra,
  });

  final String title;
  final List<String> items;
  final List<String> cautionItems;
  final List<String> forbidItems;
  final List<String> actionItems;
  final bool caution;
  final bool warning;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appPanelColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appPanelBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: warning ? const Color(0xFFDC2626) : caution ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: dark ? const Color(0xFFFAFAFA) : const Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.map((item) => _buildItem(item, Icons.check_circle_outline, const Color(0xFF16A34A))),
          ],
          if (cautionItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...cautionItems.map((item) => _buildItem(item, Icons.info_outline_rounded, const Color(0xFFF59E0B))),
          ],
          if (forbidItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...forbidItems.map((item) => _buildItem(item, Icons.block_outlined, const Color(0xFFDC2626))),
          ],
          if (actionItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...actionItems.map((item) => _buildItem(item, Icons.arrow_forward_ios_rounded, const Color(0xFF6B7280))),
          ],
          if (extra != null) ...[
            const SizedBox(height: 12),
            Text(
              extra!,
              style: TextStyle(
                color: warning ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Scaffold(
      backgroundColor: appPageBackground(context),
      appBar: AppBar(
        backgroundColor: appPageBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('关于站队'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Logo + 名称
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '站',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '站队',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v$appVersionName (build $appBuildNumber)',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 信息卡片
          _AboutCard(
            icon: Icons.info_outline_rounded,
            title: '应用简介',
            subtitle: '站队是一款围绕观点、选择和匿名表达的投票社区 App。允许用户匿名发布投票、参与讨论，同时通过举报审核机制维护社区秩序。',
          ),
          const SizedBox(height: 10),
          _AboutCard(
            icon: Icons.language_rounded,
            title: '官方网站',
            subtitle: 'www.example.com',
            onTap: () async {
              final uri = Uri.parse('https://www.example.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 10),
          _AboutCard(
            icon: Icons.email_outlined,
            title: '联系邮箱',
            subtitle: 'support@example.com',
            onTap: () async {
              final uri = Uri.parse('mailto:support@example.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const SizedBox(height: 10),
          _AboutCard(
            icon: Icons.code_rounded,
            title: '技术栈',
            subtitle: 'Flutter · NestJS · Prisma · MySQL',
          ),
          const SizedBox(height: 28),

          // 底部
          Center(
            child: Text(
              '\u00A9 2026 站队团队 保留所有权利',
              style: TextStyle(
                color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = isDarkUi(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appPanelColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appPanelBorder(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
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
                        color: dark ? const Color(0xFFFAFAFA) : const Color(0xFF111827),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
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
  if (value == null) return '长期';
  final now = DateTime.now();
  final diff = value.difference(now);
  if (diff.isNegative) return '已结束';
  if (diff.inDays > 0) return '${diff.inDays}天后';
  if (diff.inHours > 0) return '${diff.inHours}小时后';
  return '${diff.inMinutes.clamp(1, 59)}分钟后';
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
          '匿',
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
      title: const Text('\u4E3E\u62A5\u5185\u5BB9'),
      content: DropdownButtonFormField<String>(
        initialValue: reason,
        items: const [
          DropdownMenuItem(value: 'SPAM', child: Text('垃圾广告')),
          DropdownMenuItem(value: 'ILLEGAL', child: Text('违法违规')),
          DropdownMenuItem(value: 'HARASSMENT', child: Text('人身攻击')),
          DropdownMenuItem(value: 'PORNOGRAPHIC', child: Text('色情低俗')),
          DropdownMenuItem(value: 'OTHER', child: Text('其他')),
        ],
        onChanged: (value) => reason = value ?? reason,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\u53D6\u6D88'),
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
              title: '\u4E3E\u62A5\u5DF2\u63D0\u4EA4',
              message:
                  '\u7BA1\u7406\u5458\u4F1A\u5728\u540E\u53F0\u5904\u7406\u8FD9\u6761\u4E3E\u62A5',
              icon: Icons.flag_rounded,
              color: const Color(0xFF7C3AED),
            );
          },
          child: const Text('提交'),
        ),
      ],
    ),
  );
}

Future<void> showModernReportSheet(
  BuildContext context,
  WidgetRef ref,
  String targetType,
  int targetId,
) {
  final rootContext = context;
  var reason = 'SPAM';
  const reasons = [
    (
      'SPAM',
      '\u5783\u573E\u5E7F\u544A',
      '\u5E7F\u544A\u3001\u5237\u5C4F\u3001\u5F15\u6D41\u6216\u91CD\u590D\u5185\u5BB9',
    ),
    (
      'ILLEGAL',
      '\u8FDD\u6CD5\u8FDD\u89C4',
      '\u7591\u4F3C\u8FDD\u6CD5\u3001\u8FDD\u89C4\u4EA4\u6613\u6216\u5371\u9669\u4FE1\u606F',
    ),
    (
      'HARASSMENT',
      '\u653B\u51FB\u9A9A\u6270',
      '\u8FB1\u9A82\u3001\u9A9A\u6270\u3001\u4EBA\u8EAB\u653B\u51FB\u6216\u5F15\u6218',
    ),
    (
      'PORNOGRAPHIC',
      '\u8272\u60C5\u4F4E\u4FD7',
      '\u4F4E\u4FD7\u3001\u8272\u60C5\u6216\u4E0D\u9002\u5B9C\u5185\u5BB9',
    ),
    (
      'OTHER',
      '\u5176\u4ED6\u95EE\u9898',
      '\u4EE5\u4E0A\u7C7B\u578B\u4E4B\u5916\u7684\u793E\u533A\u95EE\u9898',
    ),
  ];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final maxHeight = MediaQuery.of(context).size.height * 0.82;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFFE11D48),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u4E3E\u62A5\u5185\u5BB9',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '\u8BF7\u9009\u62E9\u6700\u63A5\u8FD1\u7684\u539F\u56E0\uFF0C\u7BA1\u7406\u5458\u4F1A\u5BA1\u6838\u5904\u7406',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: reasons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = reasons[index];
                      return _ReportReasonTile(
                        title: item.$2,
                        subtitle: item.$3,
                        selected: reason == item.$1,
                        onTap: () => setSheetState(() => reason = item.$1),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '\u53D6\u6D88',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(appStateProvider)
                              .report(targetType, targetId, reason);
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (!rootContext.mounted) return;
                          showAppToast(
                            rootContext,
                            title: '\u4E3E\u62A5\u5DF2\u63D0\u4EA4',
                            message:
                                '\u7BA1\u7406\u5458\u4F1A\u5728\u540E\u53F0\u5904\u7406\u8FD9\u6761\u4E3E\u62A5',
                            icon: Icons.flag_rounded,
                            color: const Color(0xFF7C3AED),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('\u63D0\u4EA4\u4E3E\u62A5'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ReportReasonTile extends StatelessWidget {
  const _ReportReasonTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFFE8EDF4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF2563EB) : Colors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD7DEE8),
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


















