part of 'main.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:3000',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final storage = const FlutterSecureStorage();
  String? accessToken;
  String? refreshToken;

  Future<void> saveTokens(String access, String refresh) async {
    accessToken = access;
    refreshToken = refresh;
    await storage.write(key: 'accessToken', value: access);
    await storage.write(key: 'refreshToken', value: refresh);
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
  }
}
