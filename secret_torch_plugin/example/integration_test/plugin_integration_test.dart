// ignore_for_file: avoid_relative_lib_imports

// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';

import '../../lib/secret_torch_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plugin exposes static onLight method', (WidgetTester tester) async {
    expect(SecretTorchPlugin.onLight, isA<Function>());
  });
}
