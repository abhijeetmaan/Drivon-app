import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drivon_app.dart';
import 'shared/services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await bootstrap(container);
  runApp(UncontrolledProviderScope(container: container, child: const DrivonApp()));
}
