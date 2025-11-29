import 'dart:async';

import 'package:flutter_socket_example/core/data/message.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../logging.dart';

class SocketRepository {
  SocketRepository(io.Socket socket) : _socket = socket;

  final io.Socket _socket;
  final _messagesController = StreamController<List<Message>>.broadcast();
  final _systemMessagesController = StreamController<SystemMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _onlineCountController = StreamController<int>.broadcast();

  final _messages = List<Message>.empty(growable: true);

  Stream<List<Message>> get messages => _messagesController.stream;
  Stream<SystemMessage> get systemMessages => _systemMessagesController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  Stream<int> get onlineCount => _onlineCountController.stream;

  bool get isConnected => _socket.connected;
  String? get sessionId => _socket.id;
  String? _currentUsername;
  String? _pendingUsername;
  bool _isInitialized = false;

  void connect() {
    if (_isInitialized) {
      log('Already initialized, skipping connect setup');
      // 이미 초기화된 경우 현재 연결 상태를 알림
      _connectionController.add(_socket.connected);
      return;
    }

    _isInitialized = true;

    _socket
      ..onConnect((_) {
        log('onConnect: ${_socket.id}');
        _connectionController.add(true);

        // 대기 중인 joinChat이 있으면 실행
        if (_pendingUsername != null) {
          log('Executing pending joinChat for $_pendingUsername');
          final username = _pendingUsername!;
          _pendingUsername = null;
          joinChat(username);
        }
      })
      ..onDisconnect((_) {
        log('onDisconnect');
        _connectionController.add(false);
      })
      ..onConnectError((e) => log('onConnectError: $e'))
      ..on('connected', (data) {
        log('connected event: $data, ${_socket.id}');
        _connectionController.add(true);
      })
      ..on('disconnect', (e) {
        log('disconnect event: $e');
        _connectionController.add(false);
      })
      ..on('message_history', (data) {
        log('message_history: $data');
        _messages.clear();
        final messages = data['messages'] as List;
        for (var msg in messages) {
          final message = Message.fromJson(msg as Map<String, dynamic>);
          final isMine = message.username == _currentUsername;
          final updatedMessage = Message(
            id: message.id,
            username: message.username,
            message: message.message,
            timestamp: message.timestamp,
            isMine: isMine,
          );
          _messages.add(updatedMessage);
        }
        log('Added ${_messages.length} messages to list');
        // 새로운 리스트로 복사해서 전달
        _messagesController.add(List.from(_messages));
        log('Emitted message_history to stream');
      })
      ..on('new_message', (data) {
        log('new_message: $data');
        final message = Message.fromJson(data as Map<String, dynamic>);
        final isMine = message.username == _currentUsername;
        final updatedMessage = Message(
          id: message.id,
          username: message.username,
          message: message.message,
          timestamp: message.timestamp,
          isMine: isMine,
        );
        _messages.add(updatedMessage);
        log('Total messages now: ${_messages.length}, isMine: $isMine');
        // 새로운 리스트로 복사해서 전달
        _messagesController.add(List.from(_messages));
        log('Emitted new_message to stream');
      })
      ..on('user_joined', (data) {
        log('user_joined: $data');
        final systemMsg = SystemMessage.fromJson(data as Map<String, dynamic>);
        _systemMessagesController.add(systemMsg);
        final onlineUsers = data['online_users'] as int;
        _onlineCountController.add(onlineUsers);
      })
      ..on('user_left', (data) {
        log('user_left: $data');
        final systemMsg = SystemMessage.fromJson(data as Map<String, dynamic>);
        _systemMessagesController.add(systemMsg);
        final onlineUsers = data['online_users'] as int;
        _onlineCountController.add(onlineUsers);
      })
      ..on('error', (data) {
        log('error: $data');
      })
      ..connect();
  }

  // 채팅방 입장
  void joinChat(String username) {
    // 먼저 username 저장 (message_history에서 isMine 판단을 위해)
    _currentUsername = username;

    if (!_socket.connected) {
      log('Socket not connected yet, saving username for later');
      _pendingUsername = username;
      return;
    }

    _socket.emit('join_chat', {'username': username});
    log('join_chat emitted: $username');
  }

  // 메시지 전송
  void sendMessage(String message) {
    if (!_socket.connected) return;
    _socket.emit('send_message', {'message': message});
    log('send_message: $message');
  }

  // 온라인 사용자 목록 요청
  void getOnlineUsers() {
    if (!_socket.connected) return;
    _socket.emit('get_online_users', {});
  }

  // 연결 해제
  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
  }

  void dispose() {
    _messagesController.close();
    _systemMessagesController.close();
    _connectionController.close();
    _onlineCountController.close();
  }
}
