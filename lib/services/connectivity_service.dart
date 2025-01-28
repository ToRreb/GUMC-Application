import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

class ConnectivityService {
  final _connectivity = Connectivity();
  final _connectionStatus = BehaviorSubject<bool>();

  ConnectivityService() {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus.add(result != ConnectivityResult.none);
  }

  Stream<bool> get connectionStream => _connectionStatus.stream;
  bool get isConnected => _connectionStatus.value;

  void dispose() {
    _connectionStatus.close();
  }
} 