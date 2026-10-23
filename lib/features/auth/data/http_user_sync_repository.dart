import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_failure.dart';
import '../models/user_profile.dart';
import '../repositories/user_sync_repository.dart';

/// `POST /auth/sync` del backend (branca `feature/auth` d'api-aprop).
///
/// Envia el token de Firebase de la sessió a `Authorization: Bearer`. El
/// backend en treu el compte i el correu, i retorna l'usuari de la base de
/// dades: el crea el primer cop amb el nom d'usuari del cos.
// TODO(DP-028): contracte llegit de la branca del backend sense fusionar.
class HttpUserSyncRepository implements UserSyncRepository {
  HttpUserSyncRepository({
    required this.baseUrl,
    required this._idToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final Uri baseUrl;

  /// Token de Firebase de l'usuari de la sessió, o `null` si no n'hi ha.
  final Future<String?> Function() _idToken;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<UserProfile?> sync({String? username}) async {
    final token = await _idToken();
    if (token == null) throw StateError('No hi ha cap sessió iniciada.');

    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint('auth/sync'),
            headers: {
              'Authorization': 'Bearer $token',
              if (username != null) 'Content-Type': 'application/json',
            },
            // El cos només cal el primer cop, per crear l'usuari.
            body: username == null ? null : jsonEncode({'username': username}),
          )
          .timeout(timeout);
    } on http.ClientException {
      throw AuthFailure.network;
    } on TimeoutException {
      throw AuthFailure.network;
    }

    return switch (response.statusCode) {
      200 || 201 => _profileFrom(response.body),
      409 => throw AuthFailure.usernameAlreadyInUse,
      // Sense nom d'usuari, el backend no pot crear l'usuari: encara no
      // existeix i cal que en triï un.
      // TODO(DP-028): el backend fa servir 422 també per a un nom invàlid.
      422 when username == null => null,
      _ => throw StateError(
        'POST /auth/sync ha respost ${response.statusCode}: ${response.body}',
      ),
    };
  }

  /// Accepta la URL base amb barra final o sense.
  Uri _endpoint(String path) {
    final base = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/$path');
  }

  UserProfile _profileFrom(String body) {
    final user = (jsonDecode(body) as Map<String, dynamic>)['user'] as Map;
    return UserProfile(
      id: '${user['id']}',
      username: user['username'] as String,
      email: user['email'] as String? ?? '',
    );
  }
}
