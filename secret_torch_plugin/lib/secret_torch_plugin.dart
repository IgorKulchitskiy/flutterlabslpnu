import 'secret_torch_plugin_platform_interface.dart';

class SecretTorchPlugin {
  static Future<bool> onLight() {
    return SecretTorchPluginPlatform.instance.onLight();
  }

  static Future<bool> setLight(bool enabled) {
    return SecretTorchPluginPlatform.instance.setLight(enabled);
  }
}
