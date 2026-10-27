import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll_option_model.freezed.dart';
part 'poll_option_model.g.dart';

@freezed
abstract class PollOptionModel with _$PollOptionModel {
  const factory PollOptionModel({
    required int id,
    required String text,
    required int pollId,
    @Default(0) int voteCount,
    String? color,
    @Default(0) int sortOrder,
  }) = _PollOptionModel;

  factory PollOptionModel.fromJson(Map<String, dynamic> json) => _$PollOptionModelFromJson(json);
}
