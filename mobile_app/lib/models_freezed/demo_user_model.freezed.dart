// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'demo_user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DemoUserModel {

 int get id; int get uid; String get username; String get nickname; String? get avatarUrl; String? get bio; String? get badge; String? get role; int? get customRoleId;
/// Create a copy of DemoUserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DemoUserModelCopyWith<DemoUserModel> get copyWith => _$DemoUserModelCopyWithImpl<DemoUserModel>(this as DemoUserModel, _$identity);

  /// Serializes this DemoUserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DemoUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.role, role) || other.role == role)&&(identical(other.customRoleId, customRoleId) || other.customRoleId == customRoleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,uid,username,nickname,avatarUrl,bio,badge,role,customRoleId);

@override
String toString() {
  return 'DemoUserModel(id: $id, uid: $uid, username: $username, nickname: $nickname, avatarUrl: $avatarUrl, bio: $bio, badge: $badge, role: $role, customRoleId: $customRoleId)';
}


}

/// @nodoc
abstract mixin class $DemoUserModelCopyWith<$Res>  {
  factory $DemoUserModelCopyWith(DemoUserModel value, $Res Function(DemoUserModel) _then) = _$DemoUserModelCopyWithImpl;
@useResult
$Res call({
 int id, int uid, String username, String nickname, String? avatarUrl, String? bio, String? badge, String? role, int? customRoleId
});




}
/// @nodoc
class _$DemoUserModelCopyWithImpl<$Res>
    implements $DemoUserModelCopyWith<$Res> {
  _$DemoUserModelCopyWithImpl(this._self, this._then);

  final DemoUserModel _self;
  final $Res Function(DemoUserModel) _then;

/// Create a copy of DemoUserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? badge = freezed,Object? role = freezed,Object? customRoleId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,customRoleId: freezed == customRoleId ? _self.customRoleId : customRoleId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DemoUserModel].
extension DemoUserModelPatterns on DemoUserModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DemoUserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DemoUserModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DemoUserModel value)  $default,){
final _that = this;
switch (_that) {
case _DemoUserModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DemoUserModel value)?  $default,){
final _that = this;
switch (_that) {
case _DemoUserModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int uid,  String username,  String nickname,  String? avatarUrl,  String? bio,  String? badge,  String? role,  int? customRoleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DemoUserModel() when $default != null:
return $default(_that.id,_that.uid,_that.username,_that.nickname,_that.avatarUrl,_that.bio,_that.badge,_that.role,_that.customRoleId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int uid,  String username,  String nickname,  String? avatarUrl,  String? bio,  String? badge,  String? role,  int? customRoleId)  $default,) {final _that = this;
switch (_that) {
case _DemoUserModel():
return $default(_that.id,_that.uid,_that.username,_that.nickname,_that.avatarUrl,_that.bio,_that.badge,_that.role,_that.customRoleId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int uid,  String username,  String nickname,  String? avatarUrl,  String? bio,  String? badge,  String? role,  int? customRoleId)?  $default,) {final _that = this;
switch (_that) {
case _DemoUserModel() when $default != null:
return $default(_that.id,_that.uid,_that.username,_that.nickname,_that.avatarUrl,_that.bio,_that.badge,_that.role,_that.customRoleId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DemoUserModel implements DemoUserModel {
  const _DemoUserModel({required this.id, required this.uid, required this.username, required this.nickname, this.avatarUrl, this.bio, this.badge, this.role, this.customRoleId});
  factory _DemoUserModel.fromJson(Map<String, dynamic> json) => _$DemoUserModelFromJson(json);

@override final  int id;
@override final  int uid;
@override final  String username;
@override final  String nickname;
@override final  String? avatarUrl;
@override final  String? bio;
@override final  String? badge;
@override final  String? role;
@override final  int? customRoleId;

/// Create a copy of DemoUserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DemoUserModelCopyWith<_DemoUserModel> get copyWith => __$DemoUserModelCopyWithImpl<_DemoUserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DemoUserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DemoUserModel&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.role, role) || other.role == role)&&(identical(other.customRoleId, customRoleId) || other.customRoleId == customRoleId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,uid,username,nickname,avatarUrl,bio,badge,role,customRoleId);

@override
String toString() {
  return 'DemoUserModel(id: $id, uid: $uid, username: $username, nickname: $nickname, avatarUrl: $avatarUrl, bio: $bio, badge: $badge, role: $role, customRoleId: $customRoleId)';
}


}

/// @nodoc
abstract mixin class _$DemoUserModelCopyWith<$Res> implements $DemoUserModelCopyWith<$Res> {
  factory _$DemoUserModelCopyWith(_DemoUserModel value, $Res Function(_DemoUserModel) _then) = __$DemoUserModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int uid, String username, String nickname, String? avatarUrl, String? bio, String? badge, String? role, int? customRoleId
});




}
/// @nodoc
class __$DemoUserModelCopyWithImpl<$Res>
    implements _$DemoUserModelCopyWith<$Res> {
  __$DemoUserModelCopyWithImpl(this._self, this._then);

  final _DemoUserModel _self;
  final $Res Function(_DemoUserModel) _then;

/// Create a copy of DemoUserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? avatarUrl = freezed,Object? bio = freezed,Object? badge = freezed,Object? role = freezed,Object? customRoleId = freezed,}) {
  return _then(_DemoUserModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,badge: freezed == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,customRoleId: freezed == customRoleId ? _self.customRoleId : customRoleId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
