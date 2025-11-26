import 'package:flutter/material.dart';
import 'package:flutter_socket_example/core/i18n/strings.dart';
import 'package:flutter_socket_example/core/models/chat_model.dart';
import 'package:flutter_socket_example/core/models/socket_state_model.dart';
import 'package:flutter_socket_example/ui/view.dart' as ui;

/// 채팅 페이지
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Scaffold(_AppBar(), _ConnectionStateView(), _ChatView());
  }
}

class _Scaffold extends StatelessWidget {
  final _AppBar appBar;
  final _ConnectionStateView connectionStateView;
  final _ChatView chatView;

  const _Scaffold(this.appBar, this.connectionStateView, this.chatView);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar, body: chatView);
  }
}

// MARK: - AppBar
class _AppBar extends AppBar {
  _AppBar();

  Widget build(BuildContext context) {
    final title = Strings.of(context)?.pages.chat.title;
    return AppBar(title: title == null ? null : Text(title));
  }
}

// MARK: - ConnectionState
class _ConnectionStateView extends StatelessWidget {
  const _ConnectionStateView();

  @override
  Widget build(BuildContext context) {
    return ui.View<SocketStateModel>(
      onInit: (vm) => vm.onLoad(),
      builder: (context, vm, _) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: ColoredBox(
            color: vm.connected == true ? Colors.green : Colors.red,
            child: Text(
              vm.connected == true ? '연결됨 (${vm.id})' : '연결 안됨',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

// MARK: - Chat
class _ChatView extends StatelessWidget {
  const _ChatView();

  @override
  Widget build(BuildContext context) {
    return ui.View<ChatModel>(
      onInit: (vm) => vm.onLoad(),
      builder: (context, vm, _) {
        final scrollView = CustomScrollView(slivers: []);
        return Scrollbar(child: scrollView);
      },
    );
  }
}

// Padding(
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: '메시지 입력...',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(onPressed: _sendMessage, child: Text('전송')),
//               ],
//             ),
//           )
