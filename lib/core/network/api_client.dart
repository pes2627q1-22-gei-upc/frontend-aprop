import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../l10n/locale_controller.dart';

/// The encoded multipart body exceeds an endpoint's complete request limit.
class MultipartBodyTooLargeException implements Exception {
  const MultipartBodyTooLargeException();
}

/// Excepció estandarditzada per a les peticions HTTP al backend d'AProp!.
class ApiException extends StateError implements Exception {
  ApiException(
    super.message, {
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
  });

  ApiException.timeout([String? message])
    : statusCode = null,
      isTimeout = true,
      isNetworkError = false,
      super(message ?? currentL10n.apiTimeout);

  ApiException.network([String? message])
    : statusCode = null,
      isTimeout = false,
      isNetworkError = true,
      super(message ?? currentL10n.apiNetwork);

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
/// - Injecció d'autenticació (`Authorization: Bearer <token>`): el backend
///   treu l'usuari del token.
/// - Timeout de 60s per absorbir el cold start de Render Free.
/// - Descodificació UTF-8 i d'errors estandarditzats `{"error": "..."}`.
class ApiClient {
  ApiClient({
    Uri? baseUrl,
    Future<String?> Function()? idToken,
    http.Client? client,
    this.timeout = ApiConfig.connectTimeout,
    this.language,
  }) : baseUrl = baseUrl ?? Uri.parse(ApiConfig.baseUrl),
       idTokenProvider = idToken,
       _client = client ?? http.Client();

  final Uri baseUrl;
  final Future<String?> Function()? idTokenProvider;
  final http.Client _client;
  final Duration timeout;

  /// Current UI language; sent as `lang` on the `events` and
  /// `preferences/test` endpoints so the backend can return translated texts.
  final String Function()? language;

  static final _translatedPaths = RegExp(
    r'^(events(/|$)|users/[^/]+/(events|created-events)$|preferences/test$)',
  );

  /// Construeix la URI completa a partir d'un camí relatiu i paràmetres opcionals.
  /// [withLanguage] afegeix `lang` (només les lectures, `GET`) als camins amb
  /// esdeveniments.
  Uri resolveUri(
    String path, [
    Map<String, String>? queryParameters,
    bool withLanguage = false,
  ]) {
    final normalizedBase = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.replaceAll(RegExp(r'^/+'), '');
    final uri = Uri.parse('$normalizedBase/$normalizedPath');
    final lang = language?.call();
    final isEventPath =
        withLanguage &&
        _translatedPaths.hasMatch(
          uri.path.substring(Uri.parse(normalizedBase).path.length + 1),
        );
    final query = <String, String>{
      ...uri.queryParameters,
      ...?queryParameters,
      if (lang != null && isEventPath) 'lang': lang,
    };
    if (query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  /// Construeix les capçaleres comunes i d'autenticació.
  Future<Map<String, String>> buildHeaders({
    bool hasJsonBody = false,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await idTokenProvider?.call();

    return <String, String>{
      'Accept': 'application/json',
      if (hasJsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = resolveUri(path, queryParameters, true);
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

  Future<http.Response> put(
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
      () => _client.put(uri, headers: resolvedHeaders, body: encodedBody),
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

  Future<Object?> putJson(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final response = await put(
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
    Map<String, String>? headers,
    int? maximumBodyBytes,
  }) async {
    final uri = resolveUri(path);
    final resolvedHeaders = await buildHeaders(extraHeaders: headers);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(resolvedHeaders)
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );
    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (maximumBodyBytes != null && request.contentLength > maximumBodyBytes) {
      throw const MultipartBodyTooLargeException();
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

  void close() => _client.close();
}
