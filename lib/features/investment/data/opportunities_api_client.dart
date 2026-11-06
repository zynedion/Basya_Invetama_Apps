import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/authorized_request.dart';
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/investment_overview_data.dart';

abstract interface class OpportunitiesGateway {
  Future<List<InvestmentOpportunity>> getOpportunities(AuthSession session);
}

class OpportunitiesApiClient implements OpportunitiesGateway {
  OpportunitiesApiClient({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final uri = Uri.parse(
    'https://api.basyainvestama.id/app/investasi/peluang',
  );
  void close() => _client.close();

  Future<InvestmentOpportunity> getOpportunity(
    AuthSession session,
    int id,
  ) async {
    final data = await _getData(session, uri.replace(path: '${uri.path}/$id'));
    if (data['currency'] != 'IDR' || data['peluang'] is! Map) {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Detail investasi tidak dapat dibaca.',
      );
    }
    try {
      final item = _parseOpportunity(data['peluang']);
      if (item.id != id) throw const FormatException();
      return item;
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Detail investasi tidak dapat dibaca.',
      );
    }
  }

  Future<Map> _getData(AuthSession session, Uri endpoint) async {
    try {
      final response = await authorizedGet(_client, endpoint, session);
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Detail investasi belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      return body['data'] as Map;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat detail habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Detail investasi tidak dapat dibaca.',
      );
    }
  }

  InvestmentOpportunity _parseOpportunity(dynamic value) {
    if (value is! Map) throw const FormatException();
    String str(String key) {
      final field = value[key];
      if (field == null) return '';
      if (field is! String) throw const FormatException();
      return field;
    }

    num number(String key) {
      final field = value[key];
      if (field is! num || !field.isFinite) throw const FormatException();
      return field;
    }

    return InvestmentOpportunity(
      id: number('id').toInt(),
      code: str('kode'),
      name: str('nama'),
      category: str('sub_produk'),
      location: str('lokasi'),
      company: str('startup'),
      description: str('deskripsi'),
      imageUrl: str('gambar'),
      logoUrl: str('logo'),
      pricePerLot: number('harga_per_lot').toInt(),
      pricePerShare: number('harga_per_lembar').toInt(),
      availableLots: number('sisa_lot').toInt(),
      totalLots: number('total_lot').toInt(),
      totalValue: number('total_nilai_stock').toInt(),
      allocatedLots: number('lot_teralokasi').toInt(),
      pendingLots: number('lot_pending').toInt(),
      allocatedValue: number('nilai_teralokasi').toInt(),
      pendingValue: number('nilai_pending').toInt(),
      remainingValue: number('sisa_nilai').toInt(),
      allocatedPercent: number('persentase_teralokasi').toDouble(),
      averageRoi: number('rata_rata_roi').toDouble(),
      endDate: str('tanggal_berakhir'),
      projectStatus: str('project_status'),
      status: str('status'),
    );
  }

  @override
  Future<List<InvestmentOpportunity>> getOpportunities(
    AuthSession session,
  ) async {
    try {
      final response = await authorizedGet(_client, uri, session);
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Peluang investasi belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final data = body['data'] as Map;
      if (data['currency'] != 'IDR' || data['peluang'] is! List) {
        throw const FormatException();
      }
      return List.unmodifiable(
        (data['peluang'] as List).map((value) {
          return _parseOpportunity(value);
        }),
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat peluang investasi habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons peluang investasi tidak dapat dibaca.',
      );
    }
  }
}
