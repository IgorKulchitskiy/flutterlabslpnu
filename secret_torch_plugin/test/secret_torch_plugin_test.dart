import 'package:flutter_test/flutter_test.dart';
import 'package:secret_torch_plugin/secret_torch_plugin.dart';
import 'package:secret_torch_plugin/secret_torch_plugin_platform_interface.dart';
import 'package:secret_torch_plugin/secret_torch_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSecretTorchPluginPlatform
    with MockPlatformInterfaceMixin
    implements SecretTorchPluginPlatform {
  @override
  Future<bool> onLight() => Future.value(true);

  @override
  Future<bool> setLight(bool enabled) => Future.value(enabled);
}

void main() {
  final SecretTorchPluginPlatform initialPlatform = SecretTorchPluginPlatform.instance;

  test('$MethodChannelSecretTorchPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSecretTorchPlugin>());
  });

  test('onLight', () async {
    MockSecretTorchPluginPlatform fakePlatform = MockSecretTorchPluginPlatform();
    SecretTorchPluginPlatform.instance = fakePlatform;

    expect(await SecretTorchPlugin.onLight(), true);
  });

  test('setLight', () async {
    MockSecretTorchPluginPlatform fakePlatform = MockSecretTorchPluginPlatform();
    SecretTorchPluginPlatform.instance = fakePlatform;

    expect(await SecretTorchPlugin.setLight(true), true);
    expect(await SecretTorchPlugin.setLight(false), false);
  });
}
