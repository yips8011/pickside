part of 'main.dart';

class AppState extends ChangeNotifier {
  final api = ApiClient();
  final users = <DemoUser>[
    DemoUser(
      id: 1,
      uid: 100001,
      username: 'admin',
      nickname: '绀惧尯绠＄悊鍛?,
      role: UserRole.admin,
      bio: '璐熻矗缁存姢涓€涓共鍑€銆佸ソ鐜╃殑鎶曠エ绀惧尯銆?,
    ),
    DemoUser(
      id: 2,
      uid: 100002,
      username: 'river',
      nickname: '鍖垮悕娌虫祦',
      role: UserRole.user,
      bio: '鍠滄鐢ㄦ暟鎹湅瑙佷汉缇ょ殑閫夋嫨銆?,
    ),
  ];

  late DemoUser currentUser = users.first;
  bool isBootstrapping = true;
  bool isLoggedIn = false;
  final List<Poll> polls = [];
  final List<AppNotification> notifications = [];
  final List<ReportItem> reports = [];
  UserSettings userSettings = UserSettings();
  ProfileStats profileStats = const ProfileStats();
  final Map<int, bool> pollInteractionOverrides = {};
  final List<PermissionTitle> titles = [
    PermissionTitle(
      id: 1,
      name: '瓒呯骇绠＄悊鍛?,
      color: const Color(0xFF7C3AED),
      permissions: AppPermission.values.toSet(),
      userIds: {1},
    ),
    PermissionTitle(
      id: 2,
      name: '骞垮憡杩愯惀',
      color: const Color(0xFF0891B2),
      permissions: {AppPermission.adManage, AppPermission.announcementManage},
      userIds: {},
    ),
  ];
  final List<HomeAd> ads = [
    HomeAd(
      '榛樿鎺ㄥ箍',
      '鍙備笌鍖垮悕鎶曠エ锛岀湅鐪嬪ぇ瀹剁湡瀹為€夋嫨',
      'https://picsum.photos/seed/vote-community/900/320',
      true,
    ),
    HomeAd(
      '鏂颁汉娲诲姩',
      '鍙戝竷绗竴鏉℃姇绁紝鏀惰幏浣犵殑绗竴鎵硅鐐?,
      'https://picsum.photos/seed/poll-event/900/320',
      true,
    ),
  ];
  final AppAnnouncement startupAnnouncement = AppAnnouncement(
    title: '娆㈣繋鏉ュ埌绔欓槦',
    body: '杩欓噷鍙互鍖垮悕琛ㄨ揪锛屼篃鍙互鎶婄儹闂ㄨ鐐瑰垎浜粰鏈嬪弸銆?,
    enabled: true,
    showEveryLaunch: false,
  );
  final AppAnnouncement marqueeAnnouncement = AppAnnouncement(
    title: '绀惧尯鍏憡',
    body: '鏂囨槑璁ㄨ锛屾伓鎰忓埛绁ㄥ拰鏀诲嚮鍐呭浼氳澶勭悊銆?,
    enabled: true,
    showEveryLaunch: true,
  );
  bool startupAnnouncementShown = false;

  AppState() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPersistedTitles();
    await _loadPollInteractionOverrides();
    await _loadStartupAnnouncementSeenState();
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
      // Normal users cannot read admin roles; local persisted titles still keep test state.
    }
  }

  Future<void> _loadPersistedTitles() async {
    final raw = await api.storage.read(key: 'permissionTitles');
    if (raw == null || raw.isEmpty) return;
    try {
      final items = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      titles
        ..removeWhere((title) => title.id != 1)
        ..addAll(items.map((item) => PermissionTitle.fromStored(item)));
    } catch (_) {
      await api.storage.delete(key: 'permissionTitles');
    }
  }

  Future<void> _savePersistedTitles() async {
    final data = titles
        .where((title) => title.id != 1)
        .map((title) => title.toStored())
        .toList();
    await api.storage.write(key: 'permissionTitles', value: jsonEncode(data));
  }

  Future<void> _loadPollInteractionOverrides() async {
    final raw = await api.storage.read(key: 'pollInteractionOverrides');
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      pollInteractionOverrides
        ..clear()
        ..addAll(
          data.map((key, value) => MapEntry(int.parse(key), value == true)),
        );
    } catch (_) {
      await api.storage.delete(key: 'pollInteractionOverrides');
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

  Future<void> _savePollInteractionOverrides() async {
    final data = pollInteractionOverrides.map(
      (key, value) => MapEntry('$key', value),
    );
    await api.storage.write(
      key: 'pollInteractionOverrides',
      value: jsonEncode(data),
    );
  }

  void _applyPollInteractionOverrides() {
    for (final poll in polls) {
      final locked = pollInteractionOverrides[poll.id];
      if (locked == null) continue;
      poll.allowComment = !locked;
      poll.allowLike = !locked;
      poll.allowShare = !locked;
    }
  }

  Future<void> login(String username, String password) async {
    if (username.trim().isEmpty || password.length < 3) {
      throw Exception('璇疯緭鍏ョ敤鎴峰悕鍜屽瘑鐮?);
    }
    final response = await api.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username.trim(), 'password': password},
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
    if (!_validUsername(username.trim()) ||
        password.length < 6 ||
        nickname.trim().length < 2 ||
        nickname.trim().length > 8) {
      throw Exception('璐﹀彿鑷冲皯 5 浣嶏紝涓嶈兘绾暟瀛楁垨绗﹀彿寮€澶达紱鏄电О 2-8 涓瓧锛屽瘑鐮佽嚦灏?6 浣?);
    }
    final response = await api.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username.trim(),
        'password': password,
        'nickname': nickname.trim(),
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

  Future<void> refreshPolls({String tab = 'recommended'}) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls',
      queryParameters: {'tab': tab, 'page': 1, 'pageSize': 20},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    polls
      ..clear()
      ..addAll(
        items.map((item) => Poll.fromJson(item as Map<String, dynamic>)),
      );
    _applyPollInteractionOverrides();
    notifyListeners();
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
    required bool isAnonymous,
    required bool allowAnonymousVote,
    required bool allowAnonymousComment,
    required bool allowComment,
    required bool allowLike,
    required bool allowShare,
    DateTime? endAt,
  }) async {
    await api.dio.post(
      '/polls',
      data: {
        'title': title,
        'description': description,
        'options': options,
        'isAnonymous': isAnonymous,
        'allowAnonymousVote': allowAnonymousVote,
        'allowAnonymousComment': allowAnonymousComment,
        'allowComment': allowComment,
        'allowLike': allowLike,
        'allowShare': allowShare,
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
        AppNotification('浜掑姩宸插叧闂?, '璇ュ唴瀹瑰凡绂佹浜掑姩', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (poll.votedUserIds.contains(currentUser.id) || poll.hasEnded) return;
    await api.dio.post(
      '/polls/$pollId/vote',
      data: {'optionId': optionId, 'isAnonymous': anonymous},
    );
    final option = poll.options.firstWhere((item) => item.id == optionId);
    option.voteCount += 1;
    poll.votedUserIds.add(currentUser.id);
    poll.myOptionId = optionId;
    syncProfileStats(notify: true);
    await syncNotifications();
    notifyListeners();
  }

  Future<void> addComment(
    int pollId,
    String content, {
    bool anonymous = false,
  }) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('浜掑姩宸插叧闂?, '璇ュ唴瀹瑰凡绂佹浜掑姩', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (!poll.allowComment || content.trim().isEmpty) return;
    await api.dio.post<Map<String, dynamic>>(
      '/polls/$pollId/comments',
      data: {'content': content.trim(), 'isAnonymous': anonymous},
    );
    await syncPollComments(pollId);
    await syncNotifications();
    notifyListeners();
  }

  Future<void> syncPollComments(int pollId) async {
    final poll = maybePollById(pollId);
    if (poll == null) return;
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls/$pollId/comments',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    poll.comments
      ..clear()
      ..addAll(items.map(PollComment.fromJson));
    notifyListeners();
  }

  Future<void> reactComment(int pollId, int commentId, String reaction) async {
    await api.dio.post(
      '/comments/$commentId/${reaction == 'LIKE' ? 'like' : 'dislike'}',
    );
    await syncPollComments(pollId);
    await syncNotifications();
  }

  Future<void> likePoll(int pollId) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('浜掑姩宸插叧闂?, '璇ュ唴瀹瑰凡绂佹浜掑姩', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (poll.isLiked) {
      await api.dio.delete('/polls/$pollId/like');
      poll.likeCount = (poll.likeCount - 1).clamp(0, 1 << 31);
      poll.isLiked = false;
    } else {
      await api.dio.post('/polls/$pollId/like');
      poll.likeCount += 1;
      poll.isLiked = true;
      if (poll.isDisliked) poll.isDisliked = false;
    }
    await syncProfileStats(notify: true);
    await syncNotifications();
    notifyListeners();
  }

  Future<void> favoritePoll(int pollId) async {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('浜掑姩宸插叧闂?, '璇ュ唴瀹瑰凡绂佹浜掑姩', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (poll.isFavorited) {
      await api.dio.delete('/polls/$pollId/favorite');
      poll.favoriteCount = (poll.favoriteCount - 1).clamp(0, 1 << 31);
      poll.isFavorited = false;
    } else {
      await api.dio.post('/polls/$pollId/favorite');
      poll.favoriteCount += 1;
      poll.isFavorited = true;
    }
    await syncProfileStats(notify: true);
    await syncNotifications();
    notifyListeners();
  }

  void dislikePoll(int pollId) {
    final poll = pollById(pollId);
    if (poll.interactionLocked) {
      notifications.insert(
        0,
        AppNotification('浜掑姩宸插叧闂?, '璇ュ唴瀹瑰凡绂佹浜掑姩', DateTime.now()),
      );
      notifyListeners();
      return;
    }
    if (poll.isDisliked) {
      poll.isDisliked = false;
    } else {
      poll.isDisliked = true;
      if (poll.isLiked) {
        poll.isLiked = false;
        poll.likeCount = (poll.likeCount - 1).clamp(0, 1 << 31);
      }
    }
    notifications.insert(
      0,
      AppNotification('宸茶褰曞弽棣?, '鎴戜滑浼氬噺灏戠被浼兼姇绁ㄧ殑鎺ㄨ崘鏉冮噸', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> deletePoll(int pollId) async {
    final poll = pollById(pollId);
    if (!canManagePoll(poll)) return;
    await api.dio.patch(
      '/admin/polls/$pollId/moderation',
      data: {'status': 'DELETED', 'result': '璇ユ姇绁ㄥ凡琚垹闄?},
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
      data: {'status': 'COMMENT_LOCKED', 'result': '璇ユ姇绁ㄥ凡琚姝簰鍔?},
    );
    poll.allowComment = false;
    poll.allowLike = false;
    poll.allowShare = false;
    pollInteractionOverrides[pollId] = true;
    await _savePollInteractionOverrides();
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
    final filename = filePath.split(RegExp(r'[\\/]')).last;
    final response = await api.dio.post<Map<String, dynamic>>(
      '/uploads/image',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      }),
    );
    final upload = response.data!['data'] as Map<String, dynamic>;
    final url = '${api.dio.options.baseUrl}${upload['url'] as String}';
    await api.dio.patch('/users/me', data: {'avatarUrl': url});
    currentUser.avatarUrl = url;
    notifications.insert(
      0,
      AppNotification('澶村儚宸叉洿鏂?, '鏂扮殑澶村儚宸茬粡淇濆瓨鍒颁綘鐨勪釜浜鸿祫鏂?, DateTime.now()),
    );
    notifyListeners();
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
      throw Exception('璐﹀彿鑷冲皯 5 浣嶏紝涓嶈兘绾暟瀛楋紝涓嶈兘浠ョ鍙峰紑澶达紝鍙兘鍖呭惈瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎');
    }
    if (nextNickname.length < 2 || nextNickname.length > 8) {
      throw Exception('鏄电О蹇呴』鏄?2-8 涓瓧');
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
        'name': '绠″',
        'badge': '绀惧尯绠″',
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
      AppNotification('鏉冮檺澶磋宸插垱寤?, '宸插垱寤衡€滅瀹垛€濆ご琛斿拰瀵瑰簲绠＄悊鏉冮檺', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> createHomeAd() async {
    await api.dio.post(
      '/admin/ads',
      data: {
        'key': 'home_top',
        'title': '棣栭〉椤堕儴骞垮憡浣?,
        'body': '鐢ㄤ簬娲诲姩銆佸叕鍛婂拰鍟嗕笟鍚堜綔灞曠ず',
        'enabled': true,
        'sortOrder': 1,
      },
    );
    notifications.insert(
      0,
      AppNotification('骞垮憡浣嶅凡淇濆瓨', '棣栭〉椤堕儴骞垮憡閰嶇疆宸茬粡鍐欏叆鍚庡彴', DateTime.now()),
    );
    notifyListeners();
  }

  Future<void> adminUserAction(DemoUser user, String action) async {
    final actor = currentUser;
    if (user.id == actor.id) return;
    if (user.isCreatorAdmin) return;
    final protectedUser = user.canAdmin || user.showBadge;
    if (action == 'delete' && (!actor.isCreatorAdmin || protectedUser)) return;
    if (action == 'role' && !actor.isCreatorAdmin) return;
    if (action == 'ban') {
      user.muted = true;
      notifications.insert(
        0,
        AppNotification('鐢ㄦ埛宸茬瑷€', '${user.nickname} 宸茶绂佹浜掑姩鍙戣█', DateTime.now()),
      );
    } else if (action == 'unban') {
      user.muted = false;
      notifications.insert(
        0,
        AppNotification('鐢ㄦ埛宸茶В绂?, '${user.nickname} 宸叉仮澶嶄簰鍔ㄦ潈闄?, DateTime.now()),
      );
    } else if (action == 'delete') {
      await api.dio.delete('/admin/users/${user.id}');
      users.removeWhere((item) => item.id == user.id);
      notifications.insert(
        0,
        AppNotification('鐢ㄦ埛宸插垹闄?, '${user.nickname} 宸茶鏍囪鍒犻櫎', DateTime.now()),
      );
    } else if (action == 'role') {
      await api.dio.patch(
        '/admin/users/${user.id}/role',
        data: {'role': 'ADMIN', 'badge': '绠＄悊鍛?},
      );
      user.role = UserRole.admin;
      notifications.insert(
        0,
        AppNotification('鏉冮檺宸叉彁鍗?, '${user.nickname} 宸叉巿浜堢鐞嗗憳鏉冮檺', DateTime.now()),
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
          'result': action == 'reject' ? '涓炬姤宸查┏鍥烇紝鍐呭淇濇寔姝ｅ父鏄剧ず' : '涓炬姤宸插彈鐞嗭紝鍐呭宸插鐞?,
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
      AppNotification('鏉冮檺鐢ㄦ埛宸插垱寤?, '宸插垱寤衡€?title鈥濆苟淇濆瓨鏉冮檺鍖?, DateTime.now()),
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
      AppNotification('骞垮憡宸蹭繚瀛?, '$title 宸叉洿鏂板埌骞垮憡浣?, DateTime.now()),
    );
    notifyListeners();
  }

  PermissionTitle? titleForUser(DemoUser user) {
    for (final title in titles) {
      if (title.userIds.contains(user.id)) return title;
    }
    if (user.role == UserRole.superAdmin || user.username == 'admin') {
      return titles.first;
    }
    if (user.role == UserRole.admin) {
      return PermissionTitle(
        id: 900,
        name: '绠＄悊鍛?,
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
        name: '骞垮憡绠＄悊',
        color: const Color(0xFF0891B2),
        permissions: {AppPermission.adManage, AppPermission.announcementManage},
        userIds: {user.id},
      );
    }
    if (user.role == UserRole.reviewer) {
      return PermissionTitle(
        id: 902,
        name: '瀹℃牳鍛?,
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
    _savePersistedTitles();
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
    _savePersistedTitles();
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
    _savePersistedTitles();
    notifyListeners();
  }

  void deleteTitle(PermissionTitle title) {
    if (!currentUser.isCreatorAdmin || title.id == 1) return;
    for (final user in users) {
      if (title.userIds.contains(user.id)) user.role = UserRole.user;
    }
    titles.removeWhere((item) => item.id == title.id);
    _syncDeleteTitle(title.id);
    _savePersistedTitles();
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
    _savePersistedTitles();
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
        await _savePersistedTitles();
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
        data: {'status': 'PUBLISHED', 'result': '璇ユ姇绁ㄥ凡瑙ｉ櫎绂佹浜掑姩'},
      );
    } catch (_) {}
    poll.allowComment = true;
    poll.allowLike = true;
    poll.allowShare = true;
    pollInteractionOverrides[pollId] = false;
    await _savePollInteractionOverrides();
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
      AppNotification('缂栬緫鐢宠宸叉彁浜?, '绠＄悊鍛樺鏍搁€氳繃鍚庡彲浠ョ紪杈戔€?{poll.title}鈥?, DateTime.now()),
    );
    notifyListeners();
  }

  void approvePollEdit(Poll poll) {
    poll.editApproved = true;
    poll.editRequested = false;
    notifications.insert(
      0,
      AppNotification(
        '缂栬緫鐢宠宸查€氳繃',
        '鈥?{poll.title}鈥濈幇鍦ㄥ彲浠ョ敱鍙戝竷鑰呯紪杈戞爣棰樺拰鎻忚堪',
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
      AppNotification('甯栧瓙宸叉洿鏂?, '鈥?{poll.title}鈥濈殑鏍囬鍜屾弿杩板凡鏇存柊', DateTime.now()),
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
      ..title = poll.title
      ..description = poll.description
      ..allowComment = poll.allowComment
      ..allowLike = poll.allowLike
      ..allowShare = poll.allowShare
      ..viewCount = poll.viewCount
      ..likeCount = poll.likeCount
      ..favoriteCount = poll.favoriteCount
      ..myOptionId = poll.myOptionId
      ..isLiked = liked ?? existing.isLiked || poll.isLiked
      ..isFavorited = favorited ?? existing.isFavorited || poll.isFavorited;
    existing.options
      ..clear()
      ..addAll(poll.options);
    existing.comments
      ..clear()
      ..addAll(poll.comments);
    if (voted == true) existing.votedUserIds.add(currentUser.id);
    return existing;
  }

  Future<void> sharePoll(BuildContext context, Poll poll) async {
    if (poll.interactionLocked || !poll.allowShare) {
      showAppToast(
        context,
        title: '鍒嗕韩涓嶅彲鐢?,
        message: lockedInteractionMessage,
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFDC2626),
      );
      return;
    }
    final optionPreview = poll.options
        .take(4)
        .map((option) => '路 ${option.text}')
        .join('\n');
    final moreText = poll.options.length > 4
        ? '\n路 杩樻湁 ${poll.options.length - 4} 涓€夐」'
        : '';
    final url =
        '\n\n$optionPreview$moreText\n\n涓轰繚鎶ゆ姇绁ㄦ暟鎹畨鍏紝鍒嗕韩鍐呭涓嶅寘鍚彲鎶撳彇鎺ュ彛閾炬帴銆傛墦寮€绔欓槦 App 鍚庢悳绱㈡爣棰樺嵆鍙弬涓庛€?;
    final text =
        '鎴戝湪绔欓槦鍙戠幇涓€涓姇绁細${poll.title}\n\n${poll.description.isEmpty ? '鏉ョ湅鐪嬩綘浼氱珯鍝竟銆? : poll.description}\n$url';
    await SharePlus.instance.share(
      ShareParams(text: text, subject: '绔欓槦鎶曠エ锛?{poll.title}'),
    );
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
        .map((item) => cachePoll(
          Poll.fromJson(item['poll'] as Map<String, dynamic>),
          liked: true,
        ))
        .toList();
  }

  Future<List<VoteParticipant>> fetchPollParticipants(int pollId) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls/$pollId/participants',
    );
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
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
    notifyListeners();
  }

  Future<void> blockUser(DemoUser user) async {
    if (user.uid == currentUser.uid) return;
    await api.dio.post('/users/${user.uid}/block');
    await syncProfileStats();
    notifyListeners();
  }

  Future<void> followUser(DemoUser user) async {
    await api.dio.post('/users/${user.uid}/follow');
    currentUser.followingCount += 1;
    notifications.insert(
      0,
      AppNotification('鍏虫敞鎴愬姛', '浣犲凡鍏虫敞 ${user.nickname}', DateTime.now()),
    );
    await syncProfileStats();
    notifyListeners();
  }

  Future<void> unfollowUser(DemoUser user) async {
    await api.dio.delete('/users/${user.uid}/follow');
    currentUser.followingCount = (currentUser.followingCount - 1).clamp(
      0,
      1 << 31,
    );
    await syncProfileStats();
    notifyListeners();
  }

  Future<List<TrendingTopic>> fetchTrendingTopics() async {
    final response = await api.dio.get<Map<String, dynamic>>('/topics');
    final items = (response.data!['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map((item) => TrendingTopic.fromJson(item)).toList();
  }

  Future<List<Poll>> fetchHotPolls({int page = 1, int pageSize = 10}) async {
    final response = await api.dio.get<Map<String, dynamic>>(
      '/polls',
      queryParameters: {'tab': 'hot', 'page': '', 'pageSize': ''},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map((item) => cachePoll(Poll.fromJson(item))).toList();
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
