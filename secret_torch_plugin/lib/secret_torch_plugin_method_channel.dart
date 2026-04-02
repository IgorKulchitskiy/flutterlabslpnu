import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'secret_torch_plugin_platform_interface.dart';

/// An implementation of [SecretTorchPluginPlatform] that uses method channels.
class MethodChannelSecretTorchPlugin extends SecretTorchPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('secret_torch_plugin');

  @override
  Future<bool> onLight() async {
    final isEnabled = await methodChannel.invokeMethod<bool>('toggleTorch');
    return isEnabled ?? false;
  }

  @override
  Future<bool> setLight(bool enabled) async {
    final isEnabled = await methodChannel.invokeMethod<bool>(
      'setTorch',
      <String, bool>{'enabled': enabled},
    );
    return isEnabled ?? false;
  }
}
