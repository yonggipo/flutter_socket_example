import 'dart:async';

import 'package:flutter_socket_example/core/data/message.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../logging.dart';

class SocketRepository {
  SocketRepository(io.Socket socket) : _socket = socket;

  final io.Socket _socket;
  final _messagesController = StreamController<List<Message>>.broadcast();
  final _messages = List<Message>.empty(growable: true);
  Stream<List<Message>> get messages => _messagesController.stream;

  void connect() {
    _socket
      ..onConnect((_) => log('onConnect'))
      ..onDisconnect((_) => log('onDisconnect'))
      ..onConnectError((_) => log('onConnectError'))
      ..on('connect', (e) => log('connect: $e, ${_socket.id}'))
      ..on('disconnect', (e) => log('disconnect: $e'))
      ..on('message', (e) {
        log('message: $e');
        // _messages.add(Message(e.toString()));
        // _messagesController.add(_messages);
      })
      ..on('response', (_) => log('response'))
      ..connect();
  }

  // 메시지 전송
  void sendMessage(String message) {
    if (!_socket.connected) return;
    _socket.emit('message', message);
  }

  // 연결 해제
  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
  }
}
