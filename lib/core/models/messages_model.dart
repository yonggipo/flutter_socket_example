import 'dart:async';

import 'package:flutter_socket_example/core/data/message.dart';
import 'package:flutter_socket_example/core/models/base_model.dart';
import 'package:flutter_socket_example/core/repositories/socket_repository.dart';

class MessagesModel extends BaseModel {
  MessagesModel(SocketRepository repository) : _repository = repository;

  final SocketRepository _repository;
  // ignore: unused_field
  late final StreamSubscription<List<Message>>? _subscription;
  List<Message> _items = [];
  List<Message> get items => _items;

  Future<void> onLoad() async {
    if (!startLoading()) return;
    _subscription = null;
    _repository.connect();
    _subscription = _repository.messages.listen((messages) {
      _items = messages;
      notifyListeners();
    });
    doneLoading();
  }

  @override
  void dispose() {
    _subscription = null;
    super.dispose();
  }
}
