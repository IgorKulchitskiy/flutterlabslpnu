import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_torch_plugin/secret_torch_plugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSecretTorchPlugin platform = MethodChannelSecretTorchPlugin();
  const MethodChannel channel = MethodChannel('secret_torch_plugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('onLight', () async {
    expect(await platform.onLight(), true);
  });

  test('setLight', () async {
    expect(await platform.setLight(true), true);
  });
}
