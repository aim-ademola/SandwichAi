import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _checker = InternetConnection();

  Future<bool> get isOnline async {
    return await _checker.hasInternetAccess;
  }

  void listen(void Function(bool) onChange) {
    _checker.onStatusChange.listen((status) {
      onChange(status == InternetStatus.connected);
    });
  }
}
