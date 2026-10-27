part of 'main.dart';

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
      name: json['name'] as String? ?? json['badge'] as String? ?? '鏉冮檺鐢ㄦ埛',
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
  bool deleted = false;
  int pollCount = 0;
  int receivedLikes = 0;
  int followingCount = 0;
  int followerCount = 0;

  bool get canAdmin => role != UserRole.user;
  bool get isCreatorAdmin => role == UserRole.superAdmin || username == 'admin';
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
  String get badgeLabel => switch (role) {
    UserRole.admin => '绠＄悊鍛?,
    UserRole.superAdmin => '鍒涘缓绠＄悊鍛?,
    UserRole.reviewer => '瀹℃牳鍛?,
    UserRole.reportHandler => '涓炬姤澶勭悊',
    UserRole.adManager => '骞垮憡绠＄悊',
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
      nickname: json['nickname'] as String? ?? '鍖垮悕鐢ㄦ埛',
      role: role,
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
    user
      ..pollCount = json['pollCount'] as int? ?? 0
      ..receivedLikes = json['receivedLikes'] as int? ?? 0
      ..followingCount = json['followingCount'] as int? ?? 0
      ..followerCount = json['followerCount'] as int? ?? 0;
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
    this.favoriteCount = 0,
  });

  int id;
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
  int favoriteCount;
  int? myOptionId;
  bool isLiked = false;
  bool isDisliked = false;
  bool isFavorited = false;
  bool editApproved = false;
  bool editRequested = false;

  int get voteCount => options.fold(0, (sum, option) => sum + option.voteCount);
  bool get hasEnded => endAt != null && endAt!.isBefore(DateTime.now());
  bool get interactionLocked => !allowComment || !allowLike || !allowShare;
  String get authorName => isAnonymous ? '鍖垮悕鐢ㄦ埛' : author.nickname;
  String displayAuthorName({required bool revealAnonymous}) =>
      isAnonymous && !revealAnonymous ? '鍖垮悕鐢ㄦ埛' : author.nickname;
  String? anonymousRevealLabel({required bool revealAnonymous}) =>
      isAnonymous && revealAnonymous
      ? '鍖垮悕鍙戝竷鑰咃細${author.nickname} 路 UID ${author.uid}'
      : null;

  factory Poll.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>?;
    return Poll(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: authorJson == null
          ? DemoUser(
              id: json['authorId'] as int? ?? 0,
              uid: 0,
              username: '',
              nickname: '鍖垮悕鐢ㄦ埛',
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
      favoriteCount: json['favoriteCount'] as int? ?? 0,
    );
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
      : 'UID ${user?.uid ?? 0}${isAnonymous ? ' 路 鍖垮悕鎶曠エ' : ''}';
  String? get avatarUrl => maskedAnonymous ? null : user?.avatarUrl;

  factory VoteParticipant.fromJson(Map<String, dynamic> json) {
    final option = json['option'] as Map<String, dynamic>? ?? {};
    final userJson = json['user'] as Map<String, dynamic>?;
    return VoteParticipant(
      id: json['id'] as int? ?? 0,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      revealedByAdmin: json['revealedByAdmin'] as bool? ?? false,
      anonymousId: json['anonymousId'] as String? ?? '鍖垮悕#0000',
      optionText: option['text'] as String? ?? '',
      optionColor: parseColor(option['color'] as String?),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
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

  String get authorName => isAnonymous ? '鍖垮悕鐢ㄦ埛' : author.nickname;
  String displayAuthorName({required bool revealAnonymous}) =>
      isAnonymous && !(revealAnonymous && revealedByAdmin)
      ? '鍖垮悕鐢ㄦ埛'
      : author.nickname;
  String? anonymousRevealLabel({required bool revealAnonymous}) =>
      isAnonymous && revealAnonymous && revealedByAdmin
      ? '鍖垮悕璇勮鑰咃細${author.nickname} 路 UID ${author.uid}'
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
                  nickname: '鍖垮悕璇勮鑰?,
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
  });
  final int? id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead = false;

  bool get isInteraction {
    return type.contains('COMMENT') ||
        type.contains('REPLY') ||
        type.contains('LIKED') ||
        type.contains('FOLLOW') ||
        type == 'POLL_VOTED' ||
        type == 'VOTE_CREATED';
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'] as String? ?? '';
    final body = rawBody
        .replaceAll('comments locked from app', '璇ユ姇绁ㄥ凡琚姝簰鍔?)
        .replaceAll('comments unlocked from app', '璇ユ姇绁ㄥ凡瑙ｉ櫎绂佹浜掑姩')
        .replaceAll('deleted from app', '璇ユ姇绁ㄥ凡琚垹闄?);
    final item = AppNotification(
      json['title'] as String? ?? '绯荤粺閫氱煡',
      body,
      json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
      id: json['id'] as int?,
      type: json['type'] as String? ?? '',
    );
    item.isRead = json['isRead'] as bool? ?? false;
    return item;
  }
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
      nickname: reporterJson['nickname'] as String? ?? '涓炬姤鐢ㄦ埛',
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
    'SPAM' => '鍨冨溇骞垮憡',
    'ILLEGAL' => '杩濇硶杩濊',
    'HARASSMENT' => '楠氭壈鏀诲嚮',
    'PORNOGRAPHIC' => '鑹叉儏浣庝織',
    'OTHER' => '鍏朵粬鍘熷洜',
    _ => reason,
  };
}

List<Poll> seedPolls() {
  final admin = DemoUser(
    id: 1,
    uid: 100001,
    username: 'admin',
    nickname: '绀惧尯绠＄悊鍛?,
    role: UserRole.admin,
    bio: '',
  );
  final river = DemoUser(
    id: 2,
    uid: 100002,
    username: 'river',
    nickname: '鍖垮悕娌虫祦',
    role: UserRole.user,
    bio: '',
  );
  return [
    Poll(
      id: 1,
      title: '绗竴鐗堢ぞ鍖哄簲璇ヤ紭鍏堜紭鍖栦粈涔堬紵',
      description: '灏忚妯′笂绾挎祴璇曟椂锛屽摢涓€椤规渶褰卞搷浣犳槸鍚︽効鎰忕暀涓嬫潵锛?,
      author: admin,
      isAnonymous: false,
      allowAnonymousVote: true,
      allowAnonymousComment: true,
      allowComment: true,
      allowLike: true,
      allowShare: true,
      endAt: DateTime.now().add(const Duration(days: 3)),
      options: [
        PollOption(id: 11, text: '鎶曠エ浣撻獙', color: optionColors[0], voteCount: 42),
        PollOption(id: 12, text: '璇勮姘涘洿', color: optionColors[1], voteCount: 31),
        PollOption(id: 13, text: '鎺ㄨ崘璐ㄩ噺', color: optionColors[2], voteCount: 18),
      ],
      comments: [
        PollComment(
          id: 1,
          author: river,
          content: '鎶曞畬椹笂鐪嬪埌姣斾緥浼氬緢鐖斤紝浣嗚瘎璁哄尯涔熻骞插噣銆?,
          isAnonymous: false,
          revealedByAdmin: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
          likeCount: 8,
        ),
      ],
      likeCount: 19,
      favoriteCount: 7,
      viewCount: 328,
    ),
    Poll(
      id: 2,
      title: '鐑偣璇濋鏄惁搴旇榛樿寮€鍚尶鍚嶈瘎璁猴紵',
      description: '鍖垮悕鑳介檷浣庤〃杈鹃棬妲涳紝涔熷彲鑳芥彁楂樼鐞嗘垚鏈€?,
      author: river,
      isAnonymous: true,
      allowAnonymousVote: true,
      allowAnonymousComment: true,
      allowComment: true,
      allowLike: true,
      allowShare: false,
      endAt: DateTime.now().add(const Duration(hours: 20)),
      options: [
        PollOption(
          id: 21,
          text: '搴旇榛樿寮€鍚?,
          color: optionColors[3],
          voteCount: 64,
        ),
        PollOption(
          id: 22,
          text: '搴旇鎵嬪姩寮€鍚?,
          color: optionColors[4],
          voteCount: 57,
        ),
      ],
      comments: [],
      likeCount: 33,
      favoriteCount: 11,
      viewCount: 592,
    ),
  ];
}
