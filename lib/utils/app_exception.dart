class AppException implements Exception {
  final String message;
  final String prefix;

  AppException([this.message = 'Something went wrong', this.prefix = 'Error']);

  @override
  String toString() => '$prefix: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'No Internet Connection'])
    : super(message, 'Network Error');
}

class ApiException extends AppException {
  ApiException([String message = 'Server returned an error'])
    : super(message, 'API Error');
}

class PermissionException extends AppException {
  PermissionException([String message = 'Permission Denied'])
    : super(message, 'Permission Error');
}

class JsonFormatException extends AppException {
  JsonFormatException([String message = 'Invalid Data Format'])
    : super(message, 'Data Error');
}
