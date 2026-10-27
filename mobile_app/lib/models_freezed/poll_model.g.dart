// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PollModel _$PollModelFromJson(Map<String, dynamic> json) => _PollModel(
  id: (json['id'] as num).toInt(),
  shareCode: json['shareCode'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  author: DemoUserModel.fromJson(json['author'] as Map<String, dynamic>),
  isAnonymous: json['isAnonymous'] as bool? ?? false,
  allowAnonymousVote: json['allowAnonymousVote'] as bool? ?? true,
  allowAnonymousComment: json['allowAnonymousComment'] as bool? ?? true,
  allowComment: json['allowComment'] as bool? ?? true,
  allowLike: json['allowLike'] as bool? ?? true,
  allowShare: json['allowShare'] as bool? ?? true,
  endAt: json['endAt'] == null ? null : DateTime.parse(json['endAt'] as String),
  options: (json['options'] as List<dynamic>)
      .map((e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  comments:
      (json['comments'] as List<dynamic>?)
          ?.map((e) => PollCommentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
  favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  imageUrls:
      (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  topicName: json['topicName'] as String?,
  topicId: (json['topicId'] as num?)?.toInt(),
  status: json['status'] as String?,
  editRequested: json['editRequested'] as bool? ?? false,
  editApproved: json['editApproved'] as bool? ?? false,
  reviewReason: json['reviewReason'] as String?,
  votedOptionId: (json['votedOptionId'] as num?)?.toInt(),
  liked: json['liked'] as bool? ?? false,
  disliked: json['disliked'] as bool? ?? false,
  favorited: json['favorited'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PollModelToJson(_PollModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shareCode': instance.shareCode,
      'title': instance.title,
      'description': instance.description,
      'author': instance.author,
      'isAnonymous': instance.isAnonymous,
      'allowAnonymousVote': instance.allowAnonymousVote,
      'allowAnonymousComment': instance.allowAnonymousComment,
      'allowComment': instance.allowComment,
      'allowLike': instance.allowLike,
      'allowShare': instance.allowShare,
      'endAt': instance.endAt?.toIso8601String(),
      'options': instance.options,
      'comments': instance.comments,
      'voteCount': instance.voteCount,
      'commentCount': instance.commentCount,
      'likeCount': instance.likeCount,
      'dislikeCount': instance.dislikeCount,
      'favoriteCount': instance.favoriteCount,
      'viewCount': instance.viewCount,
      'imageUrls': instance.imageUrls,
      'topicName': instance.topicName,
      'topicId': instance.topicId,
      'status': instance.status,
      'editRequested': instance.editRequested,
      'editApproved': instance.editApproved,
      'reviewReason': instance.reviewReason,
      'votedOptionId': instance.votedOptionId,
      'liked': instance.liked,
      'disliked': instance.disliked,
      'favorited': instance.favorited,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
