import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';

class RegistrationFailure implements Exception {
  const RegistrationFailure(this.message, this.status);
  final String message;
  final int status;
}

class InvestorRegistrationApi {
  InvestorRegistrationApi({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final uri = Uri.parse(
    'https://api.basyainvestama.id/app/investor/registration',
  );

  Future<Map<String, dynamic>> load(AuthSession session) async =>
      _decode(await authorizedGet(_client, uri, session));

  Future<Map<String, dynamic>> submit(
    AuthSession session,
    Map<String, dynamic> payload,
  ) async {
    final current = await session.recovery?.resolve() ?? session;
    // A mutation is sent once: never replay after a timeout or rejected token.
    final response = await _client
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': current.authorizationHeader,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw RegistrationFailure(
        'Respons server tidak dapat dibaca.',
        response.statusCode,
      );
    }
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Invalid registration response');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['status'] != true) {
      throw RegistrationFailure(
        body['message']?.toString() ?? 'Pendaftaran belum dapat diproses.',
        response.statusCode,
      );
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  void dispose() => _client.close();
}
