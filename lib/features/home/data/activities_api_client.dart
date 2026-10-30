import '../../auth/data/authorized_request.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_exception.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/activities_gateway.dart';
import '../domain/investor_home_data.dart';

class ActivitiesApiClient implements ActivitiesGateway {
  ActivitiesApiClient({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  static final activitiesUri = Uri.parse(
    'https://api.basyainvestama.id/app/activities',
  );
  void close() => _client.close();

  @override
  Future<List<InvestorHomeActivity>> getActivities(
    AuthSession session, {
    int? limit,
  }) async {
    try {
      final response = await authorizedGet(
        _client,
        limit == null
            ? activitiesUri
            : activitiesUri.replace(queryParameters: {'limit': '$limit'}),
        session,
        headers: {
          'Accept': 'application/json',
          'Authorization': session.authorizationHeader,
        },
      );
      if (response.statusCode == 401) {
        throw const AuthException(
          AuthFailureType.invalidCredentials,
          'Sesi Anda sudah tidak berlaku. Silakan masuk kembali.',
        );
      }
      if (response.statusCode != 200) {
        throw const AuthException(
          AuthFailureType.server,
          'Aktivitas belum dapat dimuat. Silakan coba lagi.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map || body['status'] != true || body['data'] is! Map) {
        throw const FormatException();
      }
      final data = body['data'] as Map;
      // The app currently formats amounts in rupiah only.
      if (data['currency'] != 'IDR' || data['activities'] is! List) {
        throw const FormatException();
      }
      return (data['activities'] as List).map((item) {
        if (item is! Map ||
            item['title'] is! String ||
            item['amount'] is! num ||
            item['occurred_at'] is! String ||
            item['status'] is! Map ||
            item['status']['label'] is! String ||
            item['status']['code'] is! String ||
            item['reference_id'] is! String) {
          throw const FormatException();
        }
        final amount = item['amount'] as num;
        if (!amount.isFinite ||
            amount < 0 ||
            amount != amount.roundToDouble()) {
          throw const FormatException();
        }
        final date = DateTime.tryParse(item['occurred_at'] as String);
        if (date == null) throw const FormatException();
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        return InvestorHomeActivity(
          title: item['title'] as String,
          date:
              '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          amount: amount.toInt(),
          direction: switch (item['direction']) {
            'incoming' => HomeActivityDirection.incoming,
            'outgoing' => HomeActivityDirection.outgoing,
            'transfer' => HomeActivityDirection.transfer,
            _ => throw const FormatException(),
          },
          referenceId: item['reference_id'] as String,
          statusCode: item['status']['code'] as String,
          statusLabel: item['status']['label'] as String,
        );
      }).toList();
    } on TimeoutException {
      throw const AuthException(
        AuthFailureType.timeout,
        'Waktu memuat aktivitas habis. Silakan coba lagi.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureType.connection,
        'Periksa koneksi internet Anda lalu coba lagi.',
      );
    } on FormatException {
      throw const AuthException(
        AuthFailureType.invalidResponse,
        'Respons aktivitas server tidak dapat dibaca.',
      );
    }
  }
}
