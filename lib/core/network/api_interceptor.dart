/// API Interceptor
/// Handles request/response interception, token management, and error handling
library;

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../data/services/storage_service.dart';
import 'network_exceptions.dart';

class ApiInterceptor extends Interceptor {
  final StorageService _storageService;

  ApiInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization token if available
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix} $token';
    }

    // Add content type
    options.headers[ApiConstants.contentTypeHeader] = 'application/json';
    options.headers[ApiConstants.acceptHeader] = 'application/json';

    // Log request
    print('Request: ${options.method} ${options.path}');
    if (options.data != null) {
      print('Request Data: ${options.data}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log response
    print('Response: ${response.statusCode} ${response.requestOptions.path}');
    print('Response Data: ${response.data}');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error
    print('Error: ${err.type} - ${err.message}');
    print('Error Path: ${err.requestOptions.path}');

    NetworkException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = TimeoutException('Request timeout. Please try again.');
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        switch (statusCode) {
          case 400:
            exception = BadRequestException(
              err.response?.data['message'] ?? 'Bad request',
            );
            break;
          case 401:
            exception = UnauthorizedException(
              err.response?.data['message'] ?? 'Unauthorized',
            );
            // TODO: Handle token refresh or logout
            break;
          case 404:
            exception = NotFoundException(
              err.response?.data['message'] ?? 'Resource not found',
            );
            break;
          case 500:
          case 502:
          case 503:
            exception = InternalServerErrorException(
              err.response?.data['message'] ?? 'Server error',
            );
            break;
          default:
            exception = NetworkException(
              err.response?.data['message'] ?? 'Unknown error',
              statusCode,
            );
        }
        break;
      case DioExceptionType.cancel:
        exception = NetworkException('Request cancelled');
        break;
      case DioExceptionType.unknown:
        if (err.message?.contains('SocketException') ?? false) {
          exception = NoInternetException('No internet connection');
        } else {
          exception = FetchDataException(
            err.message ?? 'Network error occurred',
          );
        }
        break;
      default:
        exception = FetchDataException('Unknown network error');
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }
}
