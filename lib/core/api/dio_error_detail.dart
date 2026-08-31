import 'dart:io';

import 'package:dio/dio.dart';

bool isConnectivityDioError(DioException e) {
  final error = e.error;
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError ||
      error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TlsException;
}

/// Returns a short user-facing string from typical FastAPI error bodies.
String? extractApiDetailFromDio(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map<String, dynamic>) {
        final msg = first['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          final t = msg.trim();
          const prefix = 'Value error, ';
          if (t.startsWith(prefix)) {
            return t.substring(prefix.length).trim();
          }
          return t;
        }
      } else {
        final value = first.toString().trim();
        if (value.isNotEmpty) return value;
      }
    }
  }
  return null;
}
