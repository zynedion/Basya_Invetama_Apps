import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';

Map<String, dynamic> mutationMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
int mutationInt(dynamic value) => int.tryParse('$value') ?? 0;

class InvestmentMutationFailure implements Exception {
  const InvestmentMutationFailure(this.message, this.status, this.data);
  final String message;
  final int status;
  final Map<String, dynamic> data;
}

class InvestmentMutationApi {
  InvestmentMutationApi({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const _base =
      'https://api.basyainvestama.id/app/investasi/mutasi-sukarela';
  Future<Map<String, dynamic>> options(AuthSession session) =>
      _get(session, '/options');
  Future<List<Map<String, dynamic>>> pending(AuthSession session) async {
    final data = await _get(session, '/pending');
    if (data['items'] is! List) {
      throw const InvestmentMutationFailure(
        'Respons pengajuan tidak valid.',
        0,
        {},
      );
    }
    return (data['items'] as List).map(mutationMap).toList();
  }

  Future<Map<String, dynamic>> _get(AuthSession session, String path) async =>
      _decode(await authorizedGet(_client, Uri.parse('$_base$path'), session));
  Future<Map<String, dynamic>> create(
    AuthSession session,
    int amount,
    String note,
  ) =>
      _post(session, '', {'amount': amount, if (note.isNotEmpty) 'note': note});
  Future<Map<String, dynamic>> verify(
    AuthSession session,
    int id,
    String otp,
  ) => _post(session, '/$id/verify-otp', {'otp': otp});
  Future<Map<String, dynamic>> resend(AuthSession session, int id) =>
      _post(session, '/$id/resend-otp', null);
  Future<Map<String, dynamic>> _post(
    AuthSession session,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final current = await session.recovery?.resolve() ?? session;
    // Financial mutations are never replayed on timeout or token rejection.
    final response = await _client
        .post(
          Uri.parse('$_base$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': current.authorizationHeader,
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw InvestmentMutationFailure(
        'Respons server tidak dapat dibaca.',
        response.statusCode,
        {},
      );
    }
    final map = mutationMap(body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        map['status'] != true) {
      throw InvestmentMutationFailure(
        map['message']?.toString() ?? 'Mutasi belum dapat diproses.',
        response.statusCode,
        mutationMap(map['data']),
      );
    }
    if (map['data'] is! Map) {
      throw const InvestmentMutationFailure(
        'Respons mutasi tidak valid.',
        0,
        {},
      );
    }
    return mutationMap(map['data']);
  }

  void dispose() => _client.close();
}
