import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';

class ApiClient {
  String? token;

  Future<Map<String, dynamic>> login(String identifier, String password) {
    return _object('POST', '/auth/login', {
      'identifier': identifier,
      'password': password,
    });
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    await _object('POST', '/auth/register', {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _object('POST', '/auth/forgot-password', {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String password,
    required String passwordConfirm,
  }) async {
    await _object('POST', '/auth/reset-password', {
      'token': token,
      'password': password,
      'password_confirm': passwordConfirm,
    });
  }

  Future<Map<String, dynamic>> me() => _object('GET', '/users/me');

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
  }) {
    return _object('PUT', '/users/me', {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    await _object('PUT', '/users/me/password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirm': newPasswordConfirm,
    });
  }

  Future<Map<String, dynamic>> products() => _object('GET', '/products');

  Future<Map<String, dynamic>> syncProducts() => _object('POST', '/products/sync');

  Future<Map<String, dynamic>> checkout(List<Map<String, dynamic>> items) {
    return _object('POST', '/orders', {'items': items});
  }

  Future<List<dynamic>> orders() async {
    final data = await _send('GET', '/orders');
    if (data is List) return data;
    throw ApiException('Respuesta inesperada al cargar pedidos');
  }

  Future<Map<String, dynamic>> _object(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final data = await _send(method, path, body);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Respuesta inesperada del servidor');
  }

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await switch (method) {
        'POST' => http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
        'PUT' => http.put(uri, headers: headers, body: jsonEncode(body ?? {})),
        _ => http.get(uri, headers: headers),
      }.timeout(const Duration(seconds: 25));
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('La API tardó demasiado. Revisa que esté encendida en el puerto 8000.');
    } catch (_) {
      throw ApiException('No hay conexión con la API. Iníciala con uvicorn en el puerto 8000.');
    }
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw _error(response.statusCode, decoded);
  }

  ApiException _error(int status, dynamic decoded) {
    final detail = decoded is Map ? decoded['detail'] : null;
    if (detail is String) {
      return ApiException(detail, statusCode: status);
    }
    if (detail is Map) {
      final fields = <String, String>{};
      final raw = detail['fields'];
      if (raw is Map) {
        raw.forEach((key, value) {
          fields['$key'] = '$value';
        });
      }
      final message = '${detail['message'] ?? 'Revisa los datos'}';
      return ApiException(message, statusCode: status, fields: fields);
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return ApiException('${first['msg']}', statusCode: status);
      }
    }
    return ApiException('Ocurrió un error ($status)', statusCode: status);
  }
}
