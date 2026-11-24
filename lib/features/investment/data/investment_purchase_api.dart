import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';

Map<String, dynamic> purchaseMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
int purchaseInt(dynamic value) => int.tryParse('$value') ?? 0;

class InvestmentPurchaseFailure implements Exception {
  const InvestmentPurchaseFailure(this.message, this.status, this.data);
  final String message;
  final int status;
  final Map<String, dynamic> data;
}

class InvestmentPurchaseApi {
  InvestmentPurchaseApi({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const _base = 'https://api.basyainvestama.id/app/investasi';
  Future<Map<String, dynamic>> options(AuthSession session, int stockId) =>
      _get(session, '/pembelian/$stockId/options');
  Future<List<Map<String, dynamic>>> pending(AuthSession session) async {
    final data = await _get(session, '/pengajuan?type=pembelian');
    if (data['pengajuan'] is! List) {
      throw const InvestmentPurchaseFailure(
        'Respons pengajuan tidak valid.',
        0,
        {},
      );
    }
    return (data['pengajuan'] as List).map(purchaseMap).toList();
  }

  Future<Map<String, dynamic>> _get(AuthSession session, String path) async =>
      _decode(await authorizedGet(_client, Uri.parse('$_base$path'), session));
  Future<Map<String, dynamic>> create(
    AuthSession session,
    int stockId,
    int lots,
  ) => _post(session, '/pembelian/$stockId', {'total_lot': lots});
  Future<Map<String, dynamic>> verify(
    AuthSession session,
    int id,
    String otp,
  ) => _post(session, '/pengajuan/$id/verify-otp', {'otp': otp});
  Future<Map<String, dynamic>> resend(AuthSession session, int id) =>
      _post(session, '/pengajuan/$id/resend-otp', null);
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
    return _decode(response, allowEmptyData: path.endsWith('/resend-otp'));
  }

  Map<String, dynamic> _decode(
    http.Response response, {
    bool allowEmptyData = false,
  }) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw InvestmentPurchaseFailure(
        'Respons server tidak dapat dibaca.',
        response.statusCode,
        {},
      );
    }
    final map = purchaseMap(body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        map['status'] != true) {
      throw InvestmentPurchaseFailure(
        map['message']?.toString() ?? 'Pembelian belum dapat diproses.',
        response.statusCode,
        purchaseMap(map['data']),
      );
    }
    if (allowEmptyData && map['data'] == null) return {};
    if (map['data'] is! Map) {
      throw const InvestmentPurchaseFailure(
        'Respons pembelian tidak valid.',
        0,
        {},
      );
    }
    return purchaseMap(map['data']);
  }

  void dispose() => _client.close();
}
