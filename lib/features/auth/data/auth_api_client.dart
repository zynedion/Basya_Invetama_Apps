import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_session.dart';
import '../domain/auth_profile.dart';
import 'auth_exception.dart';

class AuthApiClient {
  AuthApiClient({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? (() => DateTime.now().toUtc());

  static final Uri loginUri = Uri.parse(
    'https://api.basyainvestama.id/app/login',
  );
  static final Uri profileUri = Uri.parse(
    'https://api.basyainvestama.id/app/profile',
  );
  final http.Client _client;
  final DateTime Function() _now;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            loginUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      final body = _decodeBody(response.body);
      if (response.statusCode == 200) return _parseSession(body);

      final message = _extractMessage(body);
      if (response.statusCode == 400) {
        throw AuthException(
          AuthFailureType.validation,
          message ?? 'Username/email atau kata sandi tidak valid.',
        );
      }
      if (response.statusCode == 401) {
        throw AuthException(
          AuthFailureType.invalidCredentials,
          message ?? 'Username atau kata sandi tidak valid.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AuthException(
          AuthFailureType.server,
          'Layanan sedang mengalami gangguan. Silakan coba lagi nanti.',
        );
      }
      throw AuthException(
        AuthFailureType.server,
        message ?? 'Login belum dapat diproses. Silakan coba lagi.',
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu koneksi habis. Periksa koneksi Anda lalu coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons server tidak dapat dibaca. Silakan coba lagi.',
      );
    }
  }

  Future<AuthProfile> getProfile(AuthSession session) async {
    try {
      final response = await _client
          .get(
            profileUri,
            headers: {
              'Accept': 'application/json',
              'Authorization': session.authorizationHeader,
            },
          )
          .timeout(const Duration(seconds: 20));
      final body = _decodeBody(response.body);
      if (response.statusCode == 200) {
        return _parseProfile(body);
      }
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode >= 500) {
        throw const AuthException(
          AuthFailureType.server,
          'Profil belum dapat dimuat. Silakan coba lagi nanti.',
        );
      }
      throw AuthException(
        AuthFailureType.server,
        _extractMessage(body) ?? 'Profil belum dapat dimuat.',
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat profil habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Tidak dapat memuat profil. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons profil server tidak dapat dibaca.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  AuthSession _parseSession(Map<String, dynamic> body) {
    final token = body['token'];
    final tokenType = body['token_type'];
    final expiresIn = body['expires_in'];
    if (body['status'] != true ||
        token is! String ||
        token.isEmpty ||
        tokenType is! String ||
        tokenType.isEmpty ||
        expiresIn is! num ||
        expiresIn <= 0) {
      throw const FormatException();
    }
    return AuthSession(
      accessToken: token,
      tokenType: tokenType,
      expiresAt: _now().add(Duration(seconds: expiresIn.toInt())),
    );
  }

  AuthProfile _parseProfile(Map<String, dynamic> body) {
    final user = body['user'];
    if (body['status'] != true || user is! Map) {
      throw const FormatException();
    }
    String field(String key) => user[key]?.toString() ?? '';
    final id = field('id');
    final username = field('username');
    final groupLevel = field('group_level');
    if (id.isEmpty || username.isEmpty || groupLevel.isEmpty) {
      throw const FormatException();
    }
    return AuthProfile(
      id: id,
      username: username,
      fullName: field('full_name'),
      email: field('email'),
      photo: field('foto_user'),
      groupLevel: groupLevel,
      active: field('aktif').toUpperCase() == 'Y',
      hasNasabahProfile: body['nasabah'] is Map,
      hasInvestorProfile: body['investor'] is Map,
      nasabah: body['nasabah'] is Map
          ? NasabahProfile.fromJson(body['nasabah'] as Map)
          : null,
      investor: body['investor'] is Map
          ? InvestorProfile.fromJson(body['investor'] as Map)
          : null,
    );
  }

  String? _extractMessage(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is Map && messages['error'] is String) {
      return messages['error'] as String;
    }
    return body['message'] is String ? body['message'] as String : null;
  }
}
