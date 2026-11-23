import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/presentation/form_widgets.dart' show LocalAttachment;

class MultigunaPaymentFailure implements Exception {
  const MultigunaPaymentFailure(this.message, this.uncertain);
  final String message;
  final bool uncertain;
}

class MultigunaPaymentApi {
  MultigunaPaymentApi({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const base = 'https://api.basyainvestama.id/app/multiguna';
  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw const MultigunaPaymentFailure(
        'Respons server tidak dapat dibaca.',
        true,
      );
    }
    if (body is! Map || body['status'] != true || response.statusCode >= 300) {
      throw MultigunaPaymentFailure(
        body is Map
            ? '${body['message'] ?? 'Pembayaran belum dapat diproses.'}'
            : 'Respons tidak valid.',
        response.statusCode >= 500,
      );
    }
    if (body['data'] is! Map) {
      throw const MultigunaPaymentFailure('Respons tidak lengkap.', true);
    }
    return Map<String, dynamic>.from(body['data']);
  }

  Future<Map<String, dynamic>> options(AuthSession session, int id) async =>
      _decode(
        await authorizedGet(
          _client,
          Uri.parse('$base/$id/payment/options'),
          session,
        ),
      );
  Future<List<Map<String, dynamic>>> pending(AuthSession session) async {
    final data = _decode(
      await authorizedGet(
        _client,
        Uri.parse('$base/payments/pending'),
        session,
      ),
    );
    return (data['payments'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> preview(
    AuthSession session,
    int id,
    int amount,
  ) async {
    final current = await session.recovery?.resolve() ?? session;
    final response = await _client
        .post(
          Uri.parse('$base/$id/payment/preview'),
          headers: {
            'Authorization': current.authorizationHeader,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'amount': amount}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    return _decode(response);
  }

  Future<Map<String, dynamic>> submit(
    AuthSession session,
    int id, {
    required int amount,
    required DateTime date,
    required int accountId,
    required String note,
    required LocalAttachment proof,
  }) async {
    final ext = proof.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'pdf'].contains(ext) ||
        proof.bytes.isEmpty ||
        proof.bytes.length > 5 * 1024 * 1024) {
      throw const MultigunaPaymentFailure(
        'Pilih bukti JPG, PNG, atau PDF maksimal 5 MB.',
        false,
      );
    }
    final current = await session.recovery?.resolve() ?? session;
    final request =
        http.MultipartRequest('POST', Uri.parse('$base/$id/payment'))
          ..headers.addAll({
            'Authorization': current.authorizationHeader,
            'Accept': 'application/json',
          })
          ..fields.addAll({
            'amount': '$amount',
            'trx_date':
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            'acc_bank_id': '$accountId',
            if (note.isNotEmpty) 'note': note,
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'payment_proof',
              proof.bytes,
              filename: proof.name,
              contentType: MediaType.parse(
                ext == 'pdf'
                    ? 'application/pdf'
                    : ext == 'png'
                    ? 'image/png'
                    : 'image/jpeg',
              ),
            ),
          );
    // Never retry a financial submission automatically.
    final response = await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    final payment = _decode(response)['payment'];
    if (payment is! Map || payment['id'] is! num) {
      throw const MultigunaPaymentFailure(
        'Status pengiriman belum dapat dipastikan.',
        true,
      );
    }
    return Map<String, dynamic>.from(payment);
  }

  void dispose() => _client.close();
}
