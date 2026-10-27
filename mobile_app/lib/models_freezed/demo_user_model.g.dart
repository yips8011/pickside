// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DemoUserModel _$DemoUserModelFromJson(Map<String, dynamic> json) =>
    _DemoUserModel(
      id: (json['id'] as num).toInt(),
      uid: (json['uid'] as num).toInt(),
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      badge: json['badge'] as String?,
      role: json['role'] as String?,
      customRoleId: (json['customRoleId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DemoUserModelToJson(_DemoUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'username': instance.username,
      'nickname': instance.nickname,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'badge': instance.badge,
      'role': instance.role,
      'customRoleId': instance.customRoleId,
    };
