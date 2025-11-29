import 'dart:async';

import 'package:flutter_socket_example/core/models/base_model.dart';
import 'package:flutter_socket_example/core/repositories/socket_repository.dart';

class SocketStateModel extends BaseModel {
  SocketStateModel(SocketRepository repository) : _repository = repository;

  final SocketRepository _repository;
  StreamSubscription<bool>? _connectionSubscription;

  bool _connected = false;
  String _id = '';

  bool get connected => _connected;
  String get id => _id;

  Future<void> onLoad() async {
    if (!startLoading()) return;

    // 현재 연결 상태를 즉시 업데이트
    _connected = _repository.isConnected;
    _id = _repository.sessionId ?? '';

    _connectionSubscription = _repository.connectionStatus.listen((isConnected) {
      _connected = isConnected;
      _id = _repository.sessionId ?? '';
      notifyListeners();
    });

    doneLoading();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    super.dispose();
  }
}
