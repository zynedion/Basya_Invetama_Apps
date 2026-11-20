import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';

class SavingsTopUpFailure implements Exception {
  const SavingsTopUpFailure(this.message);
  final String message;
}

class SavingsTopUpApi {
  SavingsTopUpApi({http.Client? client})
    : _client = client ?? http.Client(),
      _uri = uri;
  SavingsTopUpApi.buyPower({http.Client? client})
    : _client = client ?? http.Client(),
      _uri = Uri.parse('https://api.basyainvestama.id/app/investasi/topup');
  final http.Client _client;
  final Uri _uri;
  static final uri = Uri.parse(
    'https://api.basyainvestama.id/app/simpanan/topup',
  );
  Future<List<Map<String, dynamic>>> options(AuthSession session) async {
    final data = _decode(
      await authorizedGet(_client, Uri.parse('$_uri/options'), session),
    );
    return (data['bank_accounts'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> submit(
    AuthSession session, {
    required DateTime date,
    required int amount,
    required int accountId,
    required String filename,
    required Uint8List bytes,
    required String note,
  }) async {
    final extension = filename.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf'].contains(extension) ||
        bytes.isEmpty ||
        bytes.length > 5 * 1024 * 1024) {
      throw const SavingsTopUpFailure(
        'Pilih bukti JPG, PNG, atau PDF maksimal 5 MB.',
      );
    }
    final current = await session.recovery?.resolve() ?? session;
    final request = http.MultipartRequest('POST', _uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': current.authorizationHeader,
      })
      ..fields.addAll({
        'trx_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'amount': '$amount',
        'acc_bank_id': '$accountId',
        if (note.isNotEmpty) 'note': note,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'payment_proof',
          bytes,
          filename: filename,
          contentType: MediaType.parse(
            extension == 'pdf'
                ? 'application/pdf'
                : extension == 'png'
                ? 'image/png'
                : 'image/jpeg',
          ),
        ),
      );
    // Never replay a financial mutation, including after a timeout or HTTP 401.
    final response = await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    return _decode(response)['topup'] as Map<String, dynamic>;
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw const SavingsTopUpFailure('Respons server tidak dapat dibaca.');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body is! Map ||
        body['status'] != true) {
      throw SavingsTopUpFailure(
        body is Map
            ? body['message']?.toString() ?? 'Top up belum dapat diproses.'
            : 'Top up belum dapat diproses.',
      );
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  void dispose() => _client.close();
}
