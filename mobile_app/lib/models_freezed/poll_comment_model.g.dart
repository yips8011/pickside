// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PollCommentModel _$PollCommentModelFromJson(Map<String, dynamic> json) =>
    _PollCommentModel(
      id: (json['id'] as num).toInt(),
      pollId: (json['pollId'] as num).toInt(),
      authorId: (json['authorId'] as num).toInt(),
      content: json['content'] as String,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isFolded: json['isFolded'] as bool? ?? false,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      parentId: (json['parentId'] as num?)?.toInt(),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      author: json['author'] == null
          ? null
          : DemoUserModel.fromJson(json['author'] as Map<String, dynamic>),
      myReaction: json['myReaction'] as String?,
      stance: json['stance'] as String?,
    );

Map<String, dynamic> _$PollCommentModelToJson(_PollCommentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pollId': instance.pollId,
      'authorId': instance.authorId,
      'content': instance.content,
      'isAnonymous': instance.isAnonymous,
      'isFolded': instance.isFolded,
      'likeCount': instance.likeCount,
      'dislikeCount': instance.dislikeCount,
      'parentId': instance.parentId,
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'author': instance.author,
      'myReaction': instance.myReaction,
      'stance': instance.stance,
    };
