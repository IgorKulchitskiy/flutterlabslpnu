import 'secret_torch_plugin_platform_interface.dart';

class SecretTorchPlugin {
  static Future<bool> onLight() {
    return SecretTorchPluginPlatform.instance.onLight();
  }
}
