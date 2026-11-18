import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/domain/auth_session.dart';
import '../../auth/data/authorized_request.dart';

class MultigunaApplicationFailure implements Exception {
  const MultigunaApplicationFailure(this.message, this.status);
  final String message;
  final int status;
}

class MultigunaApplicationApi {
  MultigunaApplicationApi({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static const base = 'https://api.basyainvestama.id/app/multiguna/pengajuan';
  Future<Map<String, dynamic>> applications(
    AuthSession session, {
    String? status,
    int? limit,
    int? page,
  }) async {
    final uri = Uri.parse(base).replace(
      queryParameters: {
        'status': ?status,
        if (limit != null) 'limit': '$limit',
        if (page != null) ...{'page': '$page', 'per_page': '20'},
      },
    );
    if (limit != null && page != null) {
      throw ArgumentError('Use limit or pagination');
    }
    final data = _decode(await authorizedGet(_client, uri, session));
    if (data['applications'] is! List) {
      throw const MultigunaApplicationFailure(
        'Daftar pengajuan tidak valid.',
        0,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> detail(AuthSession session, int id) async {
    final data = _decode(
      await authorizedGet(_client, Uri.parse('$base/$id'), session),
    );
    if (data['application'] is! Map) {
      throw const MultigunaApplicationFailure(
        'Detail pengajuan tidak valid.',
        0,
      );
    }
    return Map<String, dynamic>.from(data['application']);
  }

  Future<Map<String, dynamic>> options(AuthSession session) async => _decode(
    await authorizedGet(_client, Uri.parse('$base/options'), session),
  );
  Future<Map<String, dynamic>> simulate(
    AuthSession session,
    Map<String, dynamic> body,
  ) async {
    final current = await session.recovery?.resolve() ?? session;
    final response = await _client
        .post(
          Uri.parse('$base/simulasi'),
          headers: {
            'Authorization': current.authorizationHeader,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    return _decode(response);
  }

  Future<Map<String, dynamic>> submit(
    AuthSession session,
    Map<String, String> fields,
  ) async {
    final current = await session.recovery?.resolve() ?? session;
    final request = http.MultipartRequest('POST', Uri.parse(base))
      ..headers.addAll({
        'Authorization': current.authorizationHeader,
        'Accept': 'application/json',
      })
      ..fields.addAll(fields);
    // Do not replay a financial mutation.
    final response = await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    final data = _decode(response);
    final application = data['application'];
    if (application is! Map ||
        application['id'] is! int ||
        application['trx_id'] is! String) {
      throw const MultigunaApplicationFailure(
        'Konfirmasi pengajuan tidak lengkap. Periksa daftar pengajuan sebelum mengirim ulang.',
        0,
      );
    }
    return Map<String, dynamic>.from(application);
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {}
    if (response.statusCode >= 500) {
      throw MultigunaApplicationFailure(
        'Server mengalami gangguan (HTTP ${response.statusCode}). Periksa daftar pengajuan sebelum mengirim ulang.',
        response.statusCode,
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body is! Map ||
        body['status'] != true) {
      throw MultigunaApplicationFailure(
        body is Map
            ? body['message']?.toString() ?? 'Pengajuan belum dapat diproses.'
            : 'Respons server tidak dapat dibaca.',
        response.statusCode,
      );
    }
    if (body['data'] is Map) return Map<String, dynamic>.from(body['data']);
    throw const MultigunaApplicationFailure('Data respons tidak lengkap.', 0);
  }

  void dispose() => _client.close();
}
