import 'package:freezed_annotation/freezed_annotation.dart';

import 'demo_user_model.dart';
import 'poll_option_model.dart';
import 'poll_comment_model.dart';

part 'poll_model.freezed.dart';
part 'poll_model.g.dart';

@freezed
abstract class PollModel with _$PollModel {
  const factory PollModel({
    required int id,
    String? shareCode,
    required String title,
    String? description,
    required DemoUserModel author,
    @Default(false) bool isAnonymous,
    @Default(true) bool allowAnonymousVote,
    @Default(true) bool allowAnonymousComment,
    @Default(true) bool allowComment,
    @Default(true) bool allowLike,
    @Default(true) bool allowShare,
    DateTime? endAt,
    required List<PollOptionModel> options,
    @Default([]) List<PollCommentModel> comments,
    @Default(0) int voteCount,
    @Default(0) int commentCount,
    @Default(0) int likeCount,
    @Default(0) int dislikeCount,
    @Default(0) int favoriteCount,
    @Default(0) int viewCount,
    @Default([]) List<String> imageUrls,
    String? topicName,
    int? topicId,
    String? status,
    @Default(false) bool editRequested,
    @Default(false) bool editApproved,
    String? reviewReason,
    int? votedOptionId,
    @Default(false) bool liked,
    @Default(false) bool disliked,
    @Default(false) bool favorited,
    DateTime? createdAt,
  }) = _PollModel;

  factory PollModel.fromJson(Map<String, dynamic> json) => _$PollModelFromJson(json);
}
