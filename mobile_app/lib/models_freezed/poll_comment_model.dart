import 'package:freezed_annotation/freezed_annotation.dart';

import 'demo_user_model.dart';

part 'poll_comment_model.freezed.dart';
part 'poll_comment_model.g.dart';

@freezed
abstract class PollCommentModel with _$PollCommentModel {
  const factory PollCommentModel({
    required int id,
    required int pollId,
    required int authorId,
    required String content,
    @Default(false) bool isAnonymous,
    @Default(false) bool isFolded,
    @Default(0) int likeCount,
    @Default(0) int dislikeCount,
    int? parentId,
    DateTime? deletedAt,
    DateTime? createdAt,
    DemoUserModel? author,
    String? myReaction,
    String? stance,
  }) = _PollCommentModel;

  factory PollCommentModel.fromJson(Map<String, dynamic> json) => _$PollCommentModelFromJson(json);
}
