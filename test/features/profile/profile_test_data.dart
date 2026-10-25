import 'package:aprop/features/activities/models/activity.dart';
import 'package:aprop/features/auth/models/app_user.dart';
import 'package:aprop/features/profile/models/user_profile.dart';

const profileUser = AppUser(
  id: 'user-a',
  username: 'adam',
  email: 'adam@example.test',
  firstName: 'Adam',
  lastName: 'Ziani',
  emailVerified: true,
);

Activity profileActivity({
  String id = 'profile-event',
  String? creatorId = 'user-a',
}) => Activity(
  id: id,
  title: 'Teatre al parc',
  category: 'Teatre',
  municipality: 'Girona',
  startsAt: DateTime(2026, 9, 27, 20),
  imageAsset: 'assets/images/teatre_sota_les_estrelles.jpg',
  source: ActivitySource.community,
  creator: ActivityCreator(
    name: 'Adam Ziani',
    userId: creatorId,
    isFriend: false,
  ),
);

UserProfile sampleProfile({AppUser user = profileUser, bool empty = false}) =>
    UserProfile(
      userId: user.id,
      displayName: '${user.firstName} ${user.lastName}',
      username: user.username,
      biography: 'Teatre i concerts',
      municipality: 'Girona',
      friendCount: 14,
      organizerRating: 4.7,
      progress: const ProfileProgress(
        level: ProfileLevel.explorer,
        experience: 340,
        nextLevelTarget: 500,
      ),
      completedPlans: empty
          ? []
          : [CompletedPlan(activity: profileActivity(), rating: 5)],
      createdActivities: empty ? [] : [profileActivity()],
    );
