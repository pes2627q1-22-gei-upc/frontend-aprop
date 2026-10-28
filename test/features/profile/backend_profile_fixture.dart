const profileServerId = '11111111-1111-4111-8111-111111111111';
const otherProfileServerId = '22222222-2222-4222-8222-222222222222';

Map<String, Object?> backendProfile({String account = 'user-a'}) => {
  'id': profileServerId,
  'firebase-uid': account,
  'username': 'maria',
  'name': 'Maria Soler',
  'biography': 'Teatre i concerts',
  'profile-picture': 'https://images.example.test/avatar.png',
  'plans-count': 9,
  'completed-plans-count': 2,
  'friends-count': 3,
  'experience': 340,
  'level': 2,
  'rating': null,
  'reliability': 4.5,
  'show-plans': false,
};
