import 'package:hive/hive.dart';

import '../../core/constants/hive_boxes.dart';

const String kOnboardingCompletedKey = 'onboarding_completed_v1';

bool readOnboardingCompletedSync() {
  if (!Hive.isBoxOpen(HiveBoxes.appPrefs)) return false;
  final v = Hive.box<dynamic>(HiveBoxes.appPrefs).get(kOnboardingCompletedKey);
  return v == true;
}

Future<void> writeOnboardingCompleted() async {
  if (!Hive.isBoxOpen(HiveBoxes.appPrefs)) return;
  await Hive.box<dynamic>(HiveBoxes.appPrefs).put(kOnboardingCompletedKey, true);
}
