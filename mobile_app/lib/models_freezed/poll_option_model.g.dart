// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PollOptionModel _$PollOptionModelFromJson(Map<String, dynamic> json) =>
    _PollOptionModel(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String,
      pollId: (json['pollId'] as num).toInt(),
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
      color: json['color'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PollOptionModelToJson(_PollOptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'pollId': instance.pollId,
      'voteCount': instance.voteCount,
      'color': instance.color,
      'sortOrder': instance.sortOrder,
    };
