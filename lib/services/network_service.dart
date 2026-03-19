import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasConnection() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return _hasAnyNetwork(results);
  }

  Stream<bool> onConnectionChanged() {
    return _connectivity.onConnectivityChanged.map(_hasAnyNetwork);
  }

  bool _hasAnyNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }
}
