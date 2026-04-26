import 'package:hive/hive.dart';

import '../../../../core/constants/hive_boxes.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

class HiveProfileRepository implements ProfileRepository {
  static const String _key = 'me';

  Future<Box<ProfileModel>> _open() => Hive.openBox<ProfileModel>(HiveBoxes.profile);

  @override
  Stream<UserProfile?> watchProfile() async* {
    final box = await _open();
    yield box.get(_key)?.toEntity();
    await for (final _ in box.watch(key: _key)) {
      yield box.get(_key)?.toEntity();
    }
  }

  @override
  Future<UserProfile?> getProfile() async {
    final box = await _open();
    return box.get(_key)?.toEntity();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final box = await _open();
    await box.put(_key, ProfileModel.fromEntity(profile));
  }

  @override
  Future<void> clear() async {
    final box = await _open();
    await box.delete(_key);
  }
}

