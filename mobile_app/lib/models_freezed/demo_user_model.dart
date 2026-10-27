import 'package:freezed_annotation/freezed_annotation.dart';

part 'demo_user_model.freezed.dart';
part 'demo_user_model.g.dart';

@freezed
abstract class DemoUserModel with _$DemoUserModel {
  const factory DemoUserModel({
    required int id,
    required int uid,
    required String username,
    required String nickname,
    String? avatarUrl,
    String? bio,
    String? badge,
    String? role,
    int? customRoleId,
  }) = _DemoUserModel;

  factory DemoUserModel.fromJson(Map<String, dynamic> json) => _$DemoUserModelFromJson(json);
}
