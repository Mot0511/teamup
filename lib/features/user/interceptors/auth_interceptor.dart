import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class AuthInterceptor extends Interceptor {

  final storage = GetIt.I<FlutterSecureStorage>();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler
  ) async {
      final accessToken = await storage.read(key: 'access_token');

      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      handler.next(options);
  }

}