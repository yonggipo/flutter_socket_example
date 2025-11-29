import 'package:flutter/material.dart';
import 'package:flutter_socket_example/core/data/message.dart';
import 'package:flutter_socket_example/core/models/chat_model.dart';
import 'package:flutter_socket_example/core/models/socket_state_model.dart';
import 'package:flutter_socket_example/ui/view.dart' as ui;
import 'package:intl/intl.dart';

/// 채팅 페이지
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isLoggedIn = false;
  String _username = '';

  void _onLogin(String username) {
    setState(() {
      _isLoggedIn = true;
      _username = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _LoginPage(onLogin: _onLogin);
    }
    return _ChatRoomPage(username: _username);
  }
}

// MARK: - Login Page
class _LoginPage extends StatefulWidget {
  final Function(String) onLogin;

  const _LoginPage({required this.onLogin});

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _usernameController = TextEditingController();

  void _handleLogin() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요')));
      return;
    }
    widget.onLogin(username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '오픈 채팅방',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: '닉네임을 입력하세요...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('입장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Chat Room Page
class _ChatRoomPage extends StatelessWidget {
  final String username;

  const _ChatRoomPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _AppBar(),
      body: Column(
        children: [
          _ConnectionStatusView(),
          Expanded(child: _ChatView(username: username)),
          _MessageInputView(username: username),
        ],
      ),
    );
  }
}

// MARK: - AppBar
class _AppBar extends AppBar {
  _AppBar() : super(title: const Text('오픈 채팅방'));
}

// MARK: - ConnectionStatus
class _ConnectionStatusView extends StatelessWidget {
  const _ConnectionStatusView();

  @override
  Widget build(BuildContext context) {
    return ui.View<SocketStateModel>(
      onInit: (vm) => vm.onLoad(),
      builder: (context, vm, _) {
        return Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: vm.connected ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vm.connected ? '연결됨' : '연결 안됨',
                style: TextStyle(
                  color: vm.connected ? Colors.green[900] : Colors.red[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
              ui.View<ChatModel>(
                builder: (context, chatVm, _) {
                  return Text(
                    '온라인: ${chatVm.messages.onlineCount}명',
                    style: TextStyle(
                      color: vm.connected ? Colors.green[900] : Colors.red[900],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// MARK: - Chat
class _ChatView extends StatefulWidget {
  final String username;

  const _ChatView({required this.username});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ui.View<ChatModel>(
      onInit: (vm) async {
        await vm.onLoad();
        vm.messages.joinChat(widget.username);
        _scrollToBottom();
      },
      builder: (context, vm, _) {
        final allMessages = vm.messages.allMessages;

        // 새 메시지가 추가되면 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(5),
          ),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: allMessages.length,
            itemBuilder: (context, index) {
              final item = allMessages[index];

              if (item is ChatMessageItem) {
                return _MessageWidget(message: item.message);
              } else if (item is ChatSystemMessageItem) {
                return _SystemMessageWidget(message: item.systemMessage);
              }

              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

// MARK: - Message Widget
class _MessageWidget extends StatelessWidget {
  final Message message;

  const _MessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final timeStr = DateFormat('HH:mm').format(message.dateTime);

    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isMine ? 50 : 0,
        right: isMine ? 0 : 50,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                message.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.message),
        ],
      ),
    );
  }
}

// MARK: - System Message Widget
class _SystemMessageWidget extends StatelessWidget {
  final SystemMessage message;

  const _SystemMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(message.dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message.message,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              timeStr,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Message Input
class _MessageInputView extends StatefulWidget {
  final String username;

  const _MessageInputView({required this.username});

  @override
  State<_MessageInputView> createState() => _MessageInputViewState();
}

class _MessageInputViewState extends State<_MessageInputView> {
  final _messageController = TextEditingController();

  void _sendMessage(ChatModel chatModel) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      chatModel.messages.sendMessage(message);
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ui.View<ChatModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(vm),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _sendMessage(vm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('전송'),
              ),
            ],
          ),
        );
      },
    );
  }
}
