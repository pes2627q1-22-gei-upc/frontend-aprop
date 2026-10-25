import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Excepció estandarditzada per a les peticions HTTP al backend d'AProp!.
class ApiException extends StateError implements Exception {
  ApiException(
    super.message, {
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
  });

  ApiException.timeout([
    super.message = 'El servidor està despertant o triga massa a respondre. Torna-ho a provar.',
  ]) : statusCode = null,
       isTimeout = true,
       isNetworkError = false;

  ApiException.network([
    super.message = 'No s’ha pogut connectar amb el servidor.',
  ]) : statusCode = null,
       isTimeout = false,
       isNetworkError = true;

  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';
}

/// Client HTTP centralitzat per comunicar-se amb el backend d'AProp! a Render.
///
/// Gestiona:
/// - Injecció de capçaleres comunes (`Accept`, `Content-Type`).
/// - Injecció d'autenticació (`Authorization: Bearer <token>` i `X-User-ID`).
/// - Timeout de 60s per absorbir el cold start de Render Free.
/// - Descodificació UTF-8 i d'errors estandarditzats `{"error": "..."}`.
class ApiClient {
  ApiClient({
    Uri? baseUrl,
    Future<String?> Function()? idToken,
    FutureOr<String?> Function()? userId,
    http.Client? client,
    this.timeout = ApiConfig.connectTimeout,
  }) : baseUrl = baseUrl ?? Uri.parse(ApiConfig.baseUrl),
       idTokenProvider = idToken,
       userIdProvider = userId,
       _client = client ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function()? idTokenProvider;
  final FutureOr<String?> Function()? userIdProvider;
  final http.Client _client;
  final Duration timeout;

  /// Construeix la URI completa a partir d'un camí relatiu i paràmetres opcionals.
  Uri resolveUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceAll(RegExp(r'^/+'), '');
    final uri = Uri.parse('$normalizedBase/$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  /// Construeix les capçaleres comunes i d'autenticació.
  Future<Map<String, String>> buildHeaders({
    bool hasJsonBody = false,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await idTokenProvider?.call();
    final uid = await userIdProvider?.call();

    return <String, String>{
      'Accept': 'application/json',
      if (hasJsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (uid != null && uid.isNotEmpty) 'X-User-ID': uid,
      ...?extraHeaders,
    };
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = resolveUri(path, queryParameters);
    final resolvedHeaders = await buildHeaders(extraHeaders: headers);
    return _send(() => _client.get(uri, headers: resolvedHeaders));
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = resolveUri(path, queryParameters);
    final hasBody = body != null;
    final resolvedHeaders = await buildHeaders(
      hasJsonBody: hasBody,
      extraHeaders: headers,
    );
    final encodedBody = hasBody ? jsonEncode(body) : null;
    return _send(
      () => _client.post(uri, headers: resolvedHeaders, body: encodedBody),
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = resolveUri(path, queryParameters);
    final hasBody = body != null;
    final resolvedHeaders = await buildHeaders(
      hasJsonBody: hasBody,
      extraHeaders: headers,
    );
    final encodedBody = hasBody ? jsonEncode(body) : null;
    return _send(
      () => _client.patch(uri, headers: resolvedHeaders, body: encodedBody),
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = resolveUri(path, queryParameters);
    final hasBody = body != null;
    final resolvedHeaders = await buildHeaders(
      hasJsonBody: hasBody,
      extraHeaders: headers,
    );
    final encodedBody = hasBody ? jsonEncode(body) : null;
    return _send(
      () => _client.delete(uri, headers: resolvedHeaders, body: encodedBody),
    );
  }

  Future<Object?> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await get(
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return decodeOrThrow(response);
  }

  Future<Object?> postJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await post(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
    return decodeOrThrow(response);
  }

  Future<Object?> patchJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await patch(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
    return decodeOrThrow(response);
  }

  Future<Object?> deleteJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await delete(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
    return decodeOrThrow(response);
  }

  /// Envia un fitxer `multipart/form-data` (p. ex. imatge d'esdeveniment o avatar).
  Future<Object?> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final uri = resolveUri(path);
    final headers = await buildHeaders();
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );
    if (fields != null) {
      request.fields.addAll(fields);
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    }

    return decodeOrThrow(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  /// Descodifica el cos JSON en UTF-8 o llança [ApiException] si l'estat no és 2xx.
  static Object? decodeOrThrow(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodeBody(response);
    }
    throw ApiException(
      extractErrorMessage(response),
      statusCode: response.statusCode,
    );
  }

  /// Descodifica el cos d'una resposta en UTF-8 com a JSON. Retorna `null` si és buit.
  static Object? decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final text = utf8.decode(response.bodyBytes).trim();
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  /// Extreu el camp `"error"` d'una resposta d'error del backend, o un missatge per defecte.
  static String extractErrorMessage(http.Response response) {
    try {
      final decoded = decodeBody(response);
      if (decoded is Map<String, Object?>) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) {
          return error.trim();
        }
      }
    } on FormatException {
      // Si la resposta no és JSON vàlid, fem servir el codi d'estat HTTP.
    }
    return 'Error HTTP ${response.statusCode}';
  }

  /// Comprova si [value] ja té el format UUID canònic (8-4-4-4-12 dígits hexadecimals).
  static bool isCanonicalUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  /// Converteix qualsevol identificador d'usuari (com un UID de Firebase) en un
  /// UUID canònic determinista (8-4-4-4-12) per als endpoints del backend que
  /// exigeixen el tipus UUID de PostgreSQL.
  /// TODO(DP-036): Eliminar la normalització al client quan el backend resolgui
  /// `X-User-ID` / UID de Firebase cap a l'UUID intern a tots els serveis.
  static String toCanonicalUuid(String value) {
    final trimmed = value.trim();
    if (isCanonicalUuid(trimmed)) {
      return trimmed.toLowerCase();
    }
    final bytes = utf8.encode(trimmed);
    final hex = List<int>.generate(16, (i) {
      var acc = (i * 31 + 17) & 0xff;
      for (var j = 0; j < bytes.length; j++) {
        acc = (acc * 33 + bytes[j] + j + i) & 0xff;
      }
      return acc;
    });
    // Marquem versió 4 i variant RFC 4122.
    hex[6] = (hex[6] & 0x0f) | 0x40;
    hex[8] = (hex[8] & 0x3f) | 0x80;

    String part(int start, int end) => hex
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${part(0, 4)}-${part(4, 6)}-${part(6, 8)}-${part(8, 10)}-${part(10, 16)}';
  }

  void close() => _client.close();
}
