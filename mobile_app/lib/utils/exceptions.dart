/// User-facing exception with a friendly message.
/// Use this for errors that should be shown directly to users.
class UserFacingException implements Exception {
  const UserFacingException(this.message);
  final String message;

  @override
  String toString() => message;
}
