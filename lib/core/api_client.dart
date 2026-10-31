import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks directly to the free CoinGecko public API (no key required).
/// Optional demo key: flutter run --dart-define=CG_API_KEY=your_key
class ApiClient {
  ApiClient()
      : dio = Dio(BaseOptions(
          baseUrl: 'https://api.coingecko.com/api/v3',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'accept': 'application/json',
            if (const String.fromEnvironment('CG_API_KEY').isNotEmpty)
              'x-cg-demo-api-key': const String.fromEnvironment('CG_API_KEY'),
          },
        ));

  final Dio dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get<T>(path, queryParameters: query);
      return res.data as T;
    } on DioException catch (e) {
      throw ApiException(_describe(e));
    }
  }

  String _describe(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond.';
      default:
        final code = e.response?.statusCode;
        if (code == 429) return 'CoinGecko free API rate limit reached. Wait a minute and retry.';
        return code == null ? 'Unexpected network error.' : 'Server error ($code).';
    }
  }
}
