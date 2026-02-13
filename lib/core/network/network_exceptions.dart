/// Network Exceptions
/// Custom exception classes for handling different network errors
library;

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class FetchDataException extends NetworkException {
  FetchDataException([super.message = 'Error during communication']);
}

class BadRequestException extends NetworkException {
  BadRequestException([String message = 'Bad request']) : super(message, 400);
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException([String message = 'Unauthorized'])
    : super(message, 401);
}

class NotFoundException extends NetworkException {
  NotFoundException([String message = 'Not found']) : super(message, 404);
}

class InternalServerErrorException extends NetworkException {
  InternalServerErrorException([String message = 'Internal server error'])
    : super(message, 500);
}

class NoInternetException extends NetworkException {
  NoInternetException([super.message = 'No internet connection']);
}

class TimeoutException extends NetworkException {
  TimeoutException([super.message = 'Request timeout']);
}
