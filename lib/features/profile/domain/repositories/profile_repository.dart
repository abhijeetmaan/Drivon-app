import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile();
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> clear();
}

