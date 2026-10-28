import '../../../core/network/api_client.dart';

/// Pins an authenticated operation to the requested account. The profile's
/// UUID is authoritative; Firebase UIDs are never converted into invented IDs.
class ProfileApi {
  ProfileApi(this.client);
  final ApiClient client;

  Future<({Map<String, Object?> profile, Map<String, String> headers})> own(
    String accountId,
  ) async {
    final headers = Map<String, String>.unmodifiable(
      await client.buildHeaders(),
    );
    if (!RegExp(r'^Bearer \S+$').hasMatch(headers['Authorization'] ?? '')) {
      throw ApiException(
        'Cal iniciar sessió per consultar el perfil.',
        statusCode: 401,
      );
    }
    final decoded = await client.getJson('users/me', headers: headers);
    final profile = validateOwnProfile(decoded, accountId);
    return (profile: profile, headers: headers);
  }
}

Map<String, Object?> validateOwnProfile(Object? decoded, String accountId) {
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Expected the authenticated profile');
  }
  final id = decoded['id'];
  if (id is! String ||
      !RegExp(r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$')
          .hasMatch(id) ||
      id == '00000000-0000-0000-0000-000000000000') {
    throw const FormatException('Expected the real profile UUID');
  }
  if (accountId.isEmpty ||
      (decoded['firebase-uid'] != accountId &&
          id.toLowerCase() != accountId.toLowerCase())) {
    throw ApiException(
      'La sessió ha canviat. Torna a carregar el perfil.',
      statusCode: 401,
    );
  }
  return Map.unmodifiable(decoded);
}
