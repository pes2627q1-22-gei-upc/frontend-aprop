const backendUserId = '11111111-1111-4111-8111-111111111111';
const backendOtherUserId = '22222222-2222-4222-8222-222222222222';
const firebaseAccountId = 'firebase-test-account';

Map<String, Object?> backendNotification(
  int id, {
  int type = 19,
  int? event = 7,
  bool read = false,
}) => {
  'id': id,
  'user-id': backendUserId,
  'notification-date': '2026-10-26T10:05:00',
  'friend-id': null,
  'request-date': null,
  'event': event,
  'type': type,
  'read': read,
};

const backendNotificationTypes = [
  {'id': 41, 'name': 'Social'},
  {'id': 83, 'name': 'Recomanacio'},
  {'id': 19, 'name': 'Recordatori'},
];

Map<String, Object?> backendOwnProfile({
  String id = backendUserId,
  String firebaseId = firebaseAccountId,
}) => {
  'id': id,
  'firebase-uid': firebaseId,
  'username': 'test_user',
  'name': 'Test User',
};
