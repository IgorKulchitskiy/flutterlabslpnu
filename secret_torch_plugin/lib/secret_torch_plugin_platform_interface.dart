import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'secret_torch_plugin_method_channel.dart';

abstract class SecretTorchPluginPlatform extends PlatformInterface {
  /// Constructs a SecretTorchPluginPlatform.
  SecretTorchPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SecretTorchPluginPlatform _instance = MethodChannelSecretTorchPlugin();

  /// The default instance of [SecretTorchPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSecretTorchPlugin].
  static SecretTorchPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SecretTorchPluginPlatform] when
  /// they register themselves.
  static set instance(SecretTorchPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> onLight() {
    throw UnimplementedError('onLight() has not been implemented.');
  }
}
