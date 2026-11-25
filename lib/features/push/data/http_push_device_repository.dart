import '../../../core/network/api_client.dart';
import '../repositories/push_repository.dart';

/// `PUT /users/me/devices` and `DELETE /users/me/devices/{token}` (#275); the
/// person comes from the session token. Both answer 204 without a body.
class HttpPushDeviceRepository implements PushDeviceRepository {
  HttpPushDeviceRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await apiClient.putJson(
      'users/me/devices',
      body: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> unregisterDevice(String token) async {
    await apiClient.deleteJson(
      'users/me/devices/${Uri.encodeComponent(token)}',
    );
  }
}
