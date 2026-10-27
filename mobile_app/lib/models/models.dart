import 'dart:collection';
import 'package:flutter/material.dart';
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
List<String> extractTopicNames(String value) {
  final matches = RegExp(r'#([A-Za-z0-9_\-\u4e00-\u9fa5]{1,24})')
      .allMatches(value)
      .map((match) => match.group(1)?.trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList();
  return LinkedHashSet<String>.from(matches).take(5).toList();
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
        RegExp(r'COMMENT#(\d+)|COMMENTS#(\d+)', caseSensitive: false),
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
