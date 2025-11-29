import 'dart:async';

import 'package:flutter_socket_example/core/data/message.dart';
import 'package:flutter_socket_example/core/models/base_model.dart';
import 'package:flutter_socket_example/core/repositories/socket_repository.dart';
import 'package:flutter_socket_example/core/logging.dart';

class MessagesModel extends BaseModel {
  MessagesModel(SocketRepository repository) : _repository = repository;

  final SocketRepository _repository;
  StreamSubscription<List<Message>>? _messageSubscription;
  StreamSubscription<SystemMessage>? _systemMessageSubscription;
  StreamSubscription<int>? _onlineCountSubscription;

  List<Message> _items = [];
  final List<SystemMessage> _systemMessages = [];
  int _onlineCount = 0;

  List<Message> get items => _items;
  List<SystemMessage> get systemMessages => _systemMessages;
  int get onlineCount => _onlineCount;

  // 메시지와 시스템 메시지를 시간순으로 정렬한 통합 리스트
  List<ChatItem> get allMessages {
    final List<ChatItem> combined = [];

    // 일반 메시지 추가
    for (var msg in _items) {
      combined.add(ChatMessageItem(msg));
    }

    // 시스템 메시지 추가
    for (var sysMsg in _systemMessages) {
      combined.add(ChatSystemMessageItem(sysMsg));
    }

    // 시간순으로 정렬
    combined.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return combined;
  }

  Future<void> onLoad() async {
    if (!startLoading()) return;

    _repository.connect();

    _messageSubscription = _repository.messages.listen((messages) {
      log('MessagesModel: Received ${messages.length} messages');
      _items = messages;
      notifyListeners();
      log('MessagesModel: notifyListeners called for messages');
    });

    _systemMessageSubscription = _repository.systemMessages.listen((systemMsg) {
      log('MessagesModel: Received system message: ${systemMsg.message}');
      _systemMessages.add(systemMsg);
      notifyListeners();
      log('MessagesModel: notifyListeners called for system message');
    });

    _onlineCountSubscription = _repository.onlineCount.listen((count) {
      log('MessagesModel: Online count: $count');
      _onlineCount = count;
      notifyListeners();
    });

    doneLoading();
  }

  void joinChat(String username) {
    _repository.joinChat(username);
  }

  void sendMessage(String message) {
    _repository.sendMessage(message);
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _systemMessageSubscription?.cancel();
    _onlineCountSubscription?.cancel();
    _messageSubscription = null;
    _systemMessageSubscription = null;
    _onlineCountSubscription = null;
    super.dispose();
  }
}
