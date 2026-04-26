// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:autopilot/core/constants/hive_boxes.dart';
import 'package:autopilot/drivon_app.dart';
import 'package:autopilot/features/documents/data/models/document_model.dart';
import 'package:autopilot/features/expenses/data/models/expense_model.dart';
import 'package:autopilot/features/profile/data/models/profile_model.dart';
import 'package:autopilot/features/trips/data/models/trip_model.dart';
import 'package:autopilot/features/vehicle/data/models/vehicle_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('drivon_hive_test_');
    Hive.init(dir.path);
    Hive.registerAdapter(VehicleModelAdapter());
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(DocumentModelAdapter());
    Hive.registerAdapter(ProfileModelAdapter());
    Hive.registerAdapter(TripExpenseModelAdapter());
    Hive.registerAdapter(TripModelAdapter());
    await Hive.openBox<dynamic>(HiveBoxes.appPrefs);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App boots smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DrivonApp()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
