import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../auth/data/authorized_request.dart';
import '../../auth/domain/auth_session.dart';
import '../../forms/presentation/form_widgets.dart' show LocalAttachment;

class ProfileEditFailure implements Exception {
  const ProfileEditFailure(this.message);
  final String message;
}

class ProfileEditApi {
  ProfileEditApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const base = 'https://api.basyainvestama.id/app/profile';
  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body);
    if (body is! Map || body['status'] != true || response.statusCode >= 300) {
      throw ProfileEditFailure(
        body is Map
            ? '${body['message'] ?? 'Profil belum dapat disimpan.'}'
            : 'Respons tidak valid.',
      );
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  Future<Map<String, dynamic>> options(AuthSession session) async => _decode(
    await authorizedGet(_client, Uri.parse('$base/edit/options'), session),
  );
  Future<void> save(
    AuthSession session,
    Map<String, String> fields,
    LocalAttachment? photo,
  ) async {
    if (photo != null) {
      final ext = photo.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext) ||
          photo.bytes.isEmpty ||
          photo.bytes.length > 5 * 1024 * 1024) {
        throw const ProfileEditFailure(
          'Pilih foto JPG atau PNG maksimal 5 MB.',
        );
      }
    }
    final current = await session.recovery?.resolve() ?? session;
    final request = http.MultipartRequest('POST', Uri.parse(base))
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': current.authorizationHeader,
      })
      ..fields.addAll(fields);
    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_user',
          photo.bytes,
          filename: photo.name,
          contentType: MediaType.parse(
            photo.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg',
          ),
        ),
      );
    }
    final response = await (() async => http.Response.fromStream(
      await _client.send(request),
    ))().timeout(const Duration(seconds: 30));
    if (response.statusCode == 401) await session.recovery?.invalidate();
    _decode(response);
  }

  void dispose() => _client.close();
}
