// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PollModel {

 int get id; String? get shareCode; String get title; String? get description; DemoUserModel get author; bool get isAnonymous; bool get allowAnonymousVote; bool get allowAnonymousComment; bool get allowComment; bool get allowLike; bool get allowShare; DateTime? get endAt; List<PollOptionModel> get options; List<PollCommentModel> get comments; int get voteCount; int get commentCount; int get likeCount; int get dislikeCount; int get favoriteCount; int get viewCount; List<String> get imageUrls; String? get topicName; int? get topicId; String? get status; bool get editRequested; bool get editApproved; String? get reviewReason; int? get votedOptionId; bool get liked; bool get disliked; bool get favorited; DateTime? get createdAt;
/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PollModelCopyWith<PollModel> get copyWith => _$PollModelCopyWithImpl<PollModel>(this as PollModel, _$identity);

  /// Serializes this PollModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PollModel&&(identical(other.id, id) || other.id == id)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.author, author) || other.author == author)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.allowAnonymousVote, allowAnonymousVote) || other.allowAnonymousVote == allowAnonymousVote)&&(identical(other.allowAnonymousComment, allowAnonymousComment) || other.allowAnonymousComment == allowAnonymousComment)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.allowLike, allowLike) || other.allowLike == allowLike)&&(identical(other.allowShare, allowShare) || other.allowShare == allowShare)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&const DeepCollectionEquality().equals(other.options, options)&&const DeepCollectionEquality().equals(other.comments, comments)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.dislikeCount, dislikeCount) || other.dislikeCount == dislikeCount)&&(identical(other.favoriteCount, favoriteCount) || other.favoriteCount == favoriteCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.status, status) || other.status == status)&&(identical(other.editRequested, editRequested) || other.editRequested == editRequested)&&(identical(other.editApproved, editApproved) || other.editApproved == editApproved)&&(identical(other.reviewReason, reviewReason) || other.reviewReason == reviewReason)&&(identical(other.votedOptionId, votedOptionId) || other.votedOptionId == votedOptionId)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.disliked, disliked) || other.disliked == disliked)&&(identical(other.favorited, favorited) || other.favorited == favorited)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,shareCode,title,description,author,isAnonymous,allowAnonymousVote,allowAnonymousComment,allowComment,allowLike,allowShare,endAt,const DeepCollectionEquality().hash(options),const DeepCollectionEquality().hash(comments),voteCount,commentCount,likeCount,dislikeCount,favoriteCount,viewCount,const DeepCollectionEquality().hash(imageUrls),topicName,topicId,status,editRequested,editApproved,reviewReason,votedOptionId,liked,disliked,favorited,createdAt]);

@override
String toString() {
  return 'PollModel(id: $id, shareCode: $shareCode, title: $title, description: $description, author: $author, isAnonymous: $isAnonymous, allowAnonymousVote: $allowAnonymousVote, allowAnonymousComment: $allowAnonymousComment, allowComment: $allowComment, allowLike: $allowLike, allowShare: $allowShare, endAt: $endAt, options: $options, comments: $comments, voteCount: $voteCount, commentCount: $commentCount, likeCount: $likeCount, dislikeCount: $dislikeCount, favoriteCount: $favoriteCount, viewCount: $viewCount, imageUrls: $imageUrls, topicName: $topicName, topicId: $topicId, status: $status, editRequested: $editRequested, editApproved: $editApproved, reviewReason: $reviewReason, votedOptionId: $votedOptionId, liked: $liked, disliked: $disliked, favorited: $favorited, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PollModelCopyWith<$Res>  {
  factory $PollModelCopyWith(PollModel value, $Res Function(PollModel) _then) = _$PollModelCopyWithImpl;
@useResult
$Res call({
 int id, String? shareCode, String title, String? description, DemoUserModel author, bool isAnonymous, bool allowAnonymousVote, bool allowAnonymousComment, bool allowComment, bool allowLike, bool allowShare, DateTime? endAt, List<PollOptionModel> options, List<PollCommentModel> comments, int voteCount, int commentCount, int likeCount, int dislikeCount, int favoriteCount, int viewCount, List<String> imageUrls, String? topicName, int? topicId, String? status, bool editRequested, bool editApproved, String? reviewReason, int? votedOptionId, bool liked, bool disliked, bool favorited, DateTime? createdAt
});


$DemoUserModelCopyWith<$Res> get author;

}
/// @nodoc
class _$PollModelCopyWithImpl<$Res>
    implements $PollModelCopyWith<$Res> {
  _$PollModelCopyWithImpl(this._self, this._then);

  final PollModel _self;
  final $Res Function(PollModel) _then;

/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shareCode = freezed,Object? title = null,Object? description = freezed,Object? author = null,Object? isAnonymous = null,Object? allowAnonymousVote = null,Object? allowAnonymousComment = null,Object? allowComment = null,Object? allowLike = null,Object? allowShare = null,Object? endAt = freezed,Object? options = null,Object? comments = null,Object? voteCount = null,Object? commentCount = null,Object? likeCount = null,Object? dislikeCount = null,Object? favoriteCount = null,Object? viewCount = null,Object? imageUrls = null,Object? topicName = freezed,Object? topicId = freezed,Object? status = freezed,Object? editRequested = null,Object? editApproved = null,Object? reviewReason = freezed,Object? votedOptionId = freezed,Object? liked = null,Object? disliked = null,Object? favorited = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shareCode: freezed == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as DemoUserModel,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,allowAnonymousVote: null == allowAnonymousVote ? _self.allowAnonymousVote : allowAnonymousVote // ignore: cast_nullable_to_non_nullable
as bool,allowAnonymousComment: null == allowAnonymousComment ? _self.allowAnonymousComment : allowAnonymousComment // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,allowLike: null == allowLike ? _self.allowLike : allowLike // ignore: cast_nullable_to_non_nullable
as bool,allowShare: null == allowShare ? _self.allowShare : allowShare // ignore: cast_nullable_to_non_nullable
as bool,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<PollOptionModel>,comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as List<PollCommentModel>,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,dislikeCount: null == dislikeCount ? _self.dislikeCount : dislikeCount // ignore: cast_nullable_to_non_nullable
as int,favoriteCount: null == favoriteCount ? _self.favoriteCount : favoriteCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,topicName: freezed == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String?,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,editRequested: null == editRequested ? _self.editRequested : editRequested // ignore: cast_nullable_to_non_nullable
as bool,editApproved: null == editApproved ? _self.editApproved : editApproved // ignore: cast_nullable_to_non_nullable
as bool,reviewReason: freezed == reviewReason ? _self.reviewReason : reviewReason // ignore: cast_nullable_to_non_nullable
as String?,votedOptionId: freezed == votedOptionId ? _self.votedOptionId : votedOptionId // ignore: cast_nullable_to_non_nullable
as int?,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,disliked: null == disliked ? _self.disliked : disliked // ignore: cast_nullable_to_non_nullable
as bool,favorited: null == favorited ? _self.favorited : favorited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemoUserModelCopyWith<$Res> get author {
  
  return $DemoUserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [PollModel].
extension PollModelPatterns on PollModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PollModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PollModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PollModel value)  $default,){
final _that = this;
switch (_that) {
case _PollModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PollModel value)?  $default,){
final _that = this;
switch (_that) {
case _PollModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? shareCode,  String title,  String? description,  DemoUserModel author,  bool isAnonymous,  bool allowAnonymousVote,  bool allowAnonymousComment,  bool allowComment,  bool allowLike,  bool allowShare,  DateTime? endAt,  List<PollOptionModel> options,  List<PollCommentModel> comments,  int voteCount,  int commentCount,  int likeCount,  int dislikeCount,  int favoriteCount,  int viewCount,  List<String> imageUrls,  String? topicName,  int? topicId,  String? status,  bool editRequested,  bool editApproved,  String? reviewReason,  int? votedOptionId,  bool liked,  bool disliked,  bool favorited,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PollModel() when $default != null:
return $default(_that.id,_that.shareCode,_that.title,_that.description,_that.author,_that.isAnonymous,_that.allowAnonymousVote,_that.allowAnonymousComment,_that.allowComment,_that.allowLike,_that.allowShare,_that.endAt,_that.options,_that.comments,_that.voteCount,_that.commentCount,_that.likeCount,_that.dislikeCount,_that.favoriteCount,_that.viewCount,_that.imageUrls,_that.topicName,_that.topicId,_that.status,_that.editRequested,_that.editApproved,_that.reviewReason,_that.votedOptionId,_that.liked,_that.disliked,_that.favorited,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? shareCode,  String title,  String? description,  DemoUserModel author,  bool isAnonymous,  bool allowAnonymousVote,  bool allowAnonymousComment,  bool allowComment,  bool allowLike,  bool allowShare,  DateTime? endAt,  List<PollOptionModel> options,  List<PollCommentModel> comments,  int voteCount,  int commentCount,  int likeCount,  int dislikeCount,  int favoriteCount,  int viewCount,  List<String> imageUrls,  String? topicName,  int? topicId,  String? status,  bool editRequested,  bool editApproved,  String? reviewReason,  int? votedOptionId,  bool liked,  bool disliked,  bool favorited,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _PollModel():
return $default(_that.id,_that.shareCode,_that.title,_that.description,_that.author,_that.isAnonymous,_that.allowAnonymousVote,_that.allowAnonymousComment,_that.allowComment,_that.allowLike,_that.allowShare,_that.endAt,_that.options,_that.comments,_that.voteCount,_that.commentCount,_that.likeCount,_that.dislikeCount,_that.favoriteCount,_that.viewCount,_that.imageUrls,_that.topicName,_that.topicId,_that.status,_that.editRequested,_that.editApproved,_that.reviewReason,_that.votedOptionId,_that.liked,_that.disliked,_that.favorited,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? shareCode,  String title,  String? description,  DemoUserModel author,  bool isAnonymous,  bool allowAnonymousVote,  bool allowAnonymousComment,  bool allowComment,  bool allowLike,  bool allowShare,  DateTime? endAt,  List<PollOptionModel> options,  List<PollCommentModel> comments,  int voteCount,  int commentCount,  int likeCount,  int dislikeCount,  int favoriteCount,  int viewCount,  List<String> imageUrls,  String? topicName,  int? topicId,  String? status,  bool editRequested,  bool editApproved,  String? reviewReason,  int? votedOptionId,  bool liked,  bool disliked,  bool favorited,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PollModel() when $default != null:
return $default(_that.id,_that.shareCode,_that.title,_that.description,_that.author,_that.isAnonymous,_that.allowAnonymousVote,_that.allowAnonymousComment,_that.allowComment,_that.allowLike,_that.allowShare,_that.endAt,_that.options,_that.comments,_that.voteCount,_that.commentCount,_that.likeCount,_that.dislikeCount,_that.favoriteCount,_that.viewCount,_that.imageUrls,_that.topicName,_that.topicId,_that.status,_that.editRequested,_that.editApproved,_that.reviewReason,_that.votedOptionId,_that.liked,_that.disliked,_that.favorited,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PollModel implements PollModel {
  const _PollModel({required this.id, this.shareCode, required this.title, this.description, required this.author, this.isAnonymous = false, this.allowAnonymousVote = true, this.allowAnonymousComment = true, this.allowComment = true, this.allowLike = true, this.allowShare = true, this.endAt, required final  List<PollOptionModel> options, final  List<PollCommentModel> comments = const [], this.voteCount = 0, this.commentCount = 0, this.likeCount = 0, this.dislikeCount = 0, this.favoriteCount = 0, this.viewCount = 0, final  List<String> imageUrls = const [], this.topicName, this.topicId, this.status, this.editRequested = false, this.editApproved = false, this.reviewReason, this.votedOptionId, this.liked = false, this.disliked = false, this.favorited = false, this.createdAt}): _options = options,_comments = comments,_imageUrls = imageUrls;
  factory _PollModel.fromJson(Map<String, dynamic> json) => _$PollModelFromJson(json);

@override final  int id;
@override final  String? shareCode;
@override final  String title;
@override final  String? description;
@override final  DemoUserModel author;
@override@JsonKey() final  bool isAnonymous;
@override@JsonKey() final  bool allowAnonymousVote;
@override@JsonKey() final  bool allowAnonymousComment;
@override@JsonKey() final  bool allowComment;
@override@JsonKey() final  bool allowLike;
@override@JsonKey() final  bool allowShare;
@override final  DateTime? endAt;
 final  List<PollOptionModel> _options;
@override List<PollOptionModel> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

 final  List<PollCommentModel> _comments;
@override@JsonKey() List<PollCommentModel> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}

@override@JsonKey() final  int voteCount;
@override@JsonKey() final  int commentCount;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int dislikeCount;
@override@JsonKey() final  int favoriteCount;
@override@JsonKey() final  int viewCount;
 final  List<String> _imageUrls;
@override@JsonKey() List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  String? topicName;
@override final  int? topicId;
@override final  String? status;
@override@JsonKey() final  bool editRequested;
@override@JsonKey() final  bool editApproved;
@override final  String? reviewReason;
@override final  int? votedOptionId;
@override@JsonKey() final  bool liked;
@override@JsonKey() final  bool disliked;
@override@JsonKey() final  bool favorited;
@override final  DateTime? createdAt;

/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PollModelCopyWith<_PollModel> get copyWith => __$PollModelCopyWithImpl<_PollModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PollModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PollModel&&(identical(other.id, id) || other.id == id)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.author, author) || other.author == author)&&(identical(other.isAnonymous, isAnonymous) || other.isAnonymous == isAnonymous)&&(identical(other.allowAnonymousVote, allowAnonymousVote) || other.allowAnonymousVote == allowAnonymousVote)&&(identical(other.allowAnonymousComment, allowAnonymousComment) || other.allowAnonymousComment == allowAnonymousComment)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.allowLike, allowLike) || other.allowLike == allowLike)&&(identical(other.allowShare, allowShare) || other.allowShare == allowShare)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&const DeepCollectionEquality().equals(other._options, _options)&&const DeepCollectionEquality().equals(other._comments, _comments)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.dislikeCount, dislikeCount) || other.dislikeCount == dislikeCount)&&(identical(other.favoriteCount, favoriteCount) || other.favoriteCount == favoriteCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.topicName, topicName) || other.topicName == topicName)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.status, status) || other.status == status)&&(identical(other.editRequested, editRequested) || other.editRequested == editRequested)&&(identical(other.editApproved, editApproved) || other.editApproved == editApproved)&&(identical(other.reviewReason, reviewReason) || other.reviewReason == reviewReason)&&(identical(other.votedOptionId, votedOptionId) || other.votedOptionId == votedOptionId)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.disliked, disliked) || other.disliked == disliked)&&(identical(other.favorited, favorited) || other.favorited == favorited)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,shareCode,title,description,author,isAnonymous,allowAnonymousVote,allowAnonymousComment,allowComment,allowLike,allowShare,endAt,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_comments),voteCount,commentCount,likeCount,dislikeCount,favoriteCount,viewCount,const DeepCollectionEquality().hash(_imageUrls),topicName,topicId,status,editRequested,editApproved,reviewReason,votedOptionId,liked,disliked,favorited,createdAt]);

@override
String toString() {
  return 'PollModel(id: $id, shareCode: $shareCode, title: $title, description: $description, author: $author, isAnonymous: $isAnonymous, allowAnonymousVote: $allowAnonymousVote, allowAnonymousComment: $allowAnonymousComment, allowComment: $allowComment, allowLike: $allowLike, allowShare: $allowShare, endAt: $endAt, options: $options, comments: $comments, voteCount: $voteCount, commentCount: $commentCount, likeCount: $likeCount, dislikeCount: $dislikeCount, favoriteCount: $favoriteCount, viewCount: $viewCount, imageUrls: $imageUrls, topicName: $topicName, topicId: $topicId, status: $status, editRequested: $editRequested, editApproved: $editApproved, reviewReason: $reviewReason, votedOptionId: $votedOptionId, liked: $liked, disliked: $disliked, favorited: $favorited, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PollModelCopyWith<$Res> implements $PollModelCopyWith<$Res> {
  factory _$PollModelCopyWith(_PollModel value, $Res Function(_PollModel) _then) = __$PollModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String? shareCode, String title, String? description, DemoUserModel author, bool isAnonymous, bool allowAnonymousVote, bool allowAnonymousComment, bool allowComment, bool allowLike, bool allowShare, DateTime? endAt, List<PollOptionModel> options, List<PollCommentModel> comments, int voteCount, int commentCount, int likeCount, int dislikeCount, int favoriteCount, int viewCount, List<String> imageUrls, String? topicName, int? topicId, String? status, bool editRequested, bool editApproved, String? reviewReason, int? votedOptionId, bool liked, bool disliked, bool favorited, DateTime? createdAt
});


@override $DemoUserModelCopyWith<$Res> get author;

}
/// @nodoc
class __$PollModelCopyWithImpl<$Res>
    implements _$PollModelCopyWith<$Res> {
  __$PollModelCopyWithImpl(this._self, this._then);

  final _PollModel _self;
  final $Res Function(_PollModel) _then;

/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shareCode = freezed,Object? title = null,Object? description = freezed,Object? author = null,Object? isAnonymous = null,Object? allowAnonymousVote = null,Object? allowAnonymousComment = null,Object? allowComment = null,Object? allowLike = null,Object? allowShare = null,Object? endAt = freezed,Object? options = null,Object? comments = null,Object? voteCount = null,Object? commentCount = null,Object? likeCount = null,Object? dislikeCount = null,Object? favoriteCount = null,Object? viewCount = null,Object? imageUrls = null,Object? topicName = freezed,Object? topicId = freezed,Object? status = freezed,Object? editRequested = null,Object? editApproved = null,Object? reviewReason = freezed,Object? votedOptionId = freezed,Object? liked = null,Object? disliked = null,Object? favorited = null,Object? createdAt = freezed,}) {
  return _then(_PollModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shareCode: freezed == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as DemoUserModel,isAnonymous: null == isAnonymous ? _self.isAnonymous : isAnonymous // ignore: cast_nullable_to_non_nullable
as bool,allowAnonymousVote: null == allowAnonymousVote ? _self.allowAnonymousVote : allowAnonymousVote // ignore: cast_nullable_to_non_nullable
as bool,allowAnonymousComment: null == allowAnonymousComment ? _self.allowAnonymousComment : allowAnonymousComment // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,allowLike: null == allowLike ? _self.allowLike : allowLike // ignore: cast_nullable_to_non_nullable
as bool,allowShare: null == allowShare ? _self.allowShare : allowShare // ignore: cast_nullable_to_non_nullable
as bool,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<PollOptionModel>,comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<PollCommentModel>,voteCount: null == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,dislikeCount: null == dislikeCount ? _self.dislikeCount : dislikeCount // ignore: cast_nullable_to_non_nullable
as int,favoriteCount: null == favoriteCount ? _self.favoriteCount : favoriteCount // ignore: cast_nullable_to_non_nullable
as int,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,topicName: freezed == topicName ? _self.topicName : topicName // ignore: cast_nullable_to_non_nullable
as String?,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,editRequested: null == editRequested ? _self.editRequested : editRequested // ignore: cast_nullable_to_non_nullable
as bool,editApproved: null == editApproved ? _self.editApproved : editApproved // ignore: cast_nullable_to_non_nullable
as bool,reviewReason: freezed == reviewReason ? _self.reviewReason : reviewReason // ignore: cast_nullable_to_non_nullable
as String?,votedOptionId: freezed == votedOptionId ? _self.votedOptionId : votedOptionId // ignore: cast_nullable_to_non_nullable
as int?,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,disliked: null == disliked ? _self.disliked : disliked // ignore: cast_nullable_to_non_nullable
as bool,favorited: null == favorited ? _self.favorited : favorited // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of PollModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DemoUserModelCopyWith<$Res> get author {
  
  return $DemoUserModelCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
