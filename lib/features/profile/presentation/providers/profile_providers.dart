import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/hive_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return HiveProfileRepository();
});

final profileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watchProfile();
});

final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(repo: ref.watch(profileRepositoryProvider));
});

class ProfileActions {
  ProfileActions({required this.repo});

  final ProfileRepository repo;

  Future<void> save(UserProfile profile) async {
    await repo.saveProfile(profile);
  }
}
