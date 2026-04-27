import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drivon_app.dart';
import 'shared/services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      'FlutterError',
      name: 'drivon',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Uncaught platform error', name: 'drivon', error: error, stackTrace: stack);
    return true; // handled
  };

  runZonedGuarded(() {
    // Keep startup lightweight: mount UI immediately, then bootstrap in-app.
    final container = ProviderContainer();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const _BootstrapGate(),
      ),
    );
  }, (error, stack) {
    developer.log('runZonedGuarded', name: 'drivon', error: error, stackTrace: stack);
  });
}

class _BootstrapGate extends ConsumerStatefulWidget {
  const _BootstrapGate();

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate> {
  late final Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await bootstrap(ProviderScope.containerOf(context));
    } catch (e, st) {
      developer.log('bootstrap failed', name: 'drivon', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Text('Starting Drivon…')),
          );
        }
        if (snapshot.hasError) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Text('Drivon failed to start. Please restart the app.')),
          );
        }
        return const DrivonApp();
      },
    );
  }
}
