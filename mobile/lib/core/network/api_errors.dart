import 'package:dio/dio.dart';

String parseApiError(Object error) {
  if (error is DioException) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return _clean(message);
        }
        if (message is List && message.isNotEmpty) {
          return _clean(message.join('\n'));
        }
        if (data['error'] is String) {
          return _clean(data['error'] as String);
        }
      } else if (data is String && data.isNotEmpty) {
        return _clean(data);
      }
      switch (response.statusCode) {
        case 400:
          return 'Invalid request. Please check the form fields.';
        case 401:
          return 'Your session has expired. Please log in again.';
        case 403:
          return 'You do not have permission to do this.';
        case 404:
          return 'The requested item was not found.';
        case 409:
          return 'This item already exists.';
        case 422:
          return 'Please check that all required fields are filled correctly.';
        case 429:
          return 'Too many requests. Please slow down and try again.';
        default:
          if (response.statusCode != null && response.statusCode! >= 500) {
            return 'Server error. Please try again in a moment.';
          }
          return 'Request failed (${response.statusCode}).';
      }
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond. Check your connection.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Please check your connection.';
    }
    return 'Network error. Please try again.';
  }
  final s = error.toString();
  if (s.startsWith('Exception: ')) {
    return _clean(s.substring(10));
  }
  return _clean(s);
}

String _clean(String s) {
  return s
      .replaceAll('Exception: ', '')
      .replaceAll('DioException [bad response]: ', '')
      .replaceAll('DioException [connection error]: ', '')
      .replaceAll('DioException [connection timeout]: ', '')
      .replaceAll('DioException [unknown]: ', '')
      .trim();
}
