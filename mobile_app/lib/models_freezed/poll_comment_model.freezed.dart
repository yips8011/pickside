// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll_comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PollCommentModel {

 int get id; int get pollId; int get authorId; String get content; bool get isAnonymous; bool get isFolded; int get likeCount; int get dislikeCount; int? get parentId; DateTime? get deletedAt; DateTime? get createdAt; DemoUserModel? get author; String? get myReaction; String? get stance;
/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollCommentModelCopyWith<PollCommentModel> get copyWith => _$PollCommentModelCopyWithImpl<PollCommentModel>(this as PollCommentModel, _$identity);

  /// Serializes this PollCommentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.content, content) || other.content == content)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFolded, isFolded) || other.isFolded == isFolded)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.dislikeCount, dislikeCount) || other.dislikeCount == dislikeCount)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.stance, stance) || other.stance == stance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,authorId,content,isAnonymous,isFolded,likeCount,dislikeCount,parentId,deletedAt,createdAt,author,myReaction,stance);

@override
String toString() {
  return 'PollCommentModel(id: $id, pollId: $pollId, authorId: $authorId, content: $content, isAnonymous: $isAnonymous, isFolded: $isFolded, likeCount: $likeCount, dislikeCount: $dislikeCount, parentId: $parentId, deletedAt: $deletedAt, createdAt: $createdAt, author: $author, myReaction: $myReaction, stance: $stance)';
}


}

/// @nodoc
abstract mixin class $PollCommentModelCopyWith<$Res>  {
  factory $PollCommentModelCopyWith(PollCommentModel value, $Res Function(PollCommentModel) _then) = _$PollCommentModelCopyWithImpl;
@useResult
$Res call({
 int id, int pollId, int authorId, String content, bool isAnonymous, bool isFolded, int likeCount, int dislikeCount, int? parentId, DateTime? deletedAt, DateTime? createdAt, DemoUserModel? author, String? myReaction, String? stance
});


$DemoUserModelCopyWith<$Res>? get author;

}
/// @nodoc
class _$PollCommentModelCopyWithImpl<$Res>
    implements $PollCommentModelCopyWith<$Res> {
  _$PollCommentModelCopyWithImpl(this._self, this._then);

  final PollCommentModel _self;
  final $Res Function(PollCommentModel) _then;

/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pollId = null,Object? authorId = null,Object? content = null,Object? isAnonymous = null,Object? isFolded = null,Object? likeCount = null,Object? dislikeCount = null,Object? parentId = freezed,Object? deletedAt = freezed,Object? createdAt = freezed,Object? author = freezed,Object? myReaction = freezed,Object? stance = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,pollId: null == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as int,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFolded: null == isFolded ? _self.isFolded : isFolded // ignore: cast_nullable_to_non_nullable
as bool,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,dislikeCount: null == dislikeCount ? _self.dislikeCount : dislikeCount // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as DemoUserModel?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,stance: freezed == stance ? _self.stance : stance // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemoUserModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $DemoUserModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [PollCommentModel].
extension PollCommentModelPatterns on PollCommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollCommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollCommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollCommentModel value)  $default,){
final _that = this;
switch (_that) {
case _PollCommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollCommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _PollCommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int pollId,  int authorId,  String content,  bool isAnonymous,  bool isFolded,  int likeCount,  int dislikeCount,  int? parentId,  DateTime? deletedAt,  DateTime? createdAt,  DemoUserModel? author,  String? myReaction,  String? stance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollCommentModel() when $default != null:
return $default(_that.id,_that.pollId,_that.authorId,_that.content,_that.isAnonymous,_that.isFolded,_that.likeCount,_that.dislikeCount,_that.parentId,_that.deletedAt,_that.createdAt,_that.author,_that.myReaction,_that.stance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int pollId,  int authorId,  String content,  bool isAnonymous,  bool isFolded,  int likeCount,  int dislikeCount,  int? parentId,  DateTime? deletedAt,  DateTime? createdAt,  DemoUserModel? author,  String? myReaction,  String? stance)  $default,) {final _that = this;
switch (_that) {
case _PollCommentModel():
return $default(_that.id,_that.pollId,_that.authorId,_that.content,_that.isAnonymous,_that.isFolded,_that.likeCount,_that.dislikeCount,_that.parentId,_that.deletedAt,_that.createdAt,_that.author,_that.myReaction,_that.stance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int pollId,  int authorId,  String content,  bool isAnonymous,  bool isFolded,  int likeCount,  int dislikeCount,  int? parentId,  DateTime? deletedAt,  DateTime? createdAt,  DemoUserModel? author,  String? myReaction,  String? stance)?  $default,) {final _that = this;
switch (_that) {
case _PollCommentModel() when $default != null:
return $default(_that.id,_that.pollId,_that.authorId,_that.content,_that.isAnonymous,_that.isFolded,_that.likeCount,_that.dislikeCount,_that.parentId,_that.deletedAt,_that.createdAt,_that.author,_that.myReaction,_that.stance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollCommentModel implements PollCommentModel {
  const _PollCommentModel({required this.id, required this.pollId, required this.authorId, required this.content, this.isAnonymous = false, this.isFolded = false, this.likeCount = 0, this.dislikeCount = 0, this.parentId, this.deletedAt, this.createdAt, this.author, this.myReaction, this.stance});
  factory _PollCommentModel.fromJson(Map<String, dynamic> json) => _$PollCommentModelFromJson(json);

@override final  int id;
@override final  int pollId;
@override final  int authorId;
@override final  String content;
@override@JsonKey() final  bool isAnonymous;
@override@JsonKey() final  bool isFolded;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int dislikeCount;
@override final  int? parentId;
@override final  DateTime? deletedAt;
@override final  DateTime? createdAt;
@override final  DemoUserModel? author;
@override final  String? myReaction;
@override final  String? stance;

/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollCommentModelCopyWith<_PollCommentModel> get copyWith => __$PollCommentModelCopyWithImpl<_PollCommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollCommentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.pollId, pollId) || other.pollId == pollId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.content, content) || other.content == content)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.isFolded, isFolded) || other.isFolded == isFolded)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.dislikeCount, dislikeCount) || other.dislikeCount == dislikeCount)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.myReaction, myReaction) || other.myReaction == myReaction)&&(identical(other.stance, stance) || other.stance == stance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pollId,authorId,content,isAnonymous,isFolded,likeCount,dislikeCount,parentId,deletedAt,createdAt,author,myReaction,stance);

@override
String toString() {
  return 'PollCommentModel(id: $id, pollId: $pollId, authorId: $authorId, content: $content, isAnonymous: $isAnonymous, isFolded: $isFolded, likeCount: $likeCount, dislikeCount: $dislikeCount, parentId: $parentId, deletedAt: $deletedAt, createdAt: $createdAt, author: $author, myReaction: $myReaction, stance: $stance)';
}


}

/// @nodoc
abstract mixin class _$PollCommentModelCopyWith<$Res> implements $PollCommentModelCopyWith<$Res> {
  factory _$PollCommentModelCopyWith(_PollCommentModel value, $Res Function(_PollCommentModel) _then) = __$PollCommentModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int pollId, int authorId, String content, bool isAnonymous, bool isFolded, int likeCount, int dislikeCount, int? parentId, DateTime? deletedAt, DateTime? createdAt, DemoUserModel? author, String? myReaction, String? stance
});


@override $DemoUserModelCopyWith<$Res>? get author;

}
/// @nodoc
class __$PollCommentModelCopyWithImpl<$Res>
    implements _$PollCommentModelCopyWith<$Res> {
  __$PollCommentModelCopyWithImpl(this._self, this._then);

  final _PollCommentModel _self;
  final $Res Function(_PollCommentModel) _then;

/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pollId = null,Object? authorId = null,Object? content = null,Object? isAnonymous = null,Object? isFolded = null,Object? likeCount = null,Object? dislikeCount = null,Object? parentId = freezed,Object? deletedAt = freezed,Object? createdAt = freezed,Object? author = freezed,Object? myReaction = freezed,Object? stance = freezed,}) {
  return _then(_PollCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,pollId: null == pollId ? _self.pollId : pollId // ignore: cast_nullable_to_non_nullable
as int,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as int,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,isFolded: null == isFolded ? _self.isFolded : isFolded // ignore: cast_nullable_to_non_nullable
as bool,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,dislikeCount: null == dislikeCount ? _self.dislikeCount : dislikeCount // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as DemoUserModel?,myReaction: freezed == myReaction ? _self.myReaction : myReaction // ignore: cast_nullable_to_non_nullable
as String?,stance: freezed == stance ? _self.stance : stance // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PollCommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemoUserModelCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $DemoUserModelCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
