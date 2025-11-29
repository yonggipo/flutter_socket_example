import 'package:flutter_socket_example/core/models/base_model.dart';
import 'package:flutter_socket_example/core/models/messages_model.dart';

class ChatModel extends BaseModel {
  ChatModel(this.messages) {
    // MessagesModel의 변경사항을 감지하고 전파
    messages.addListener(_onMessagesChanged);
  }

  final MessagesModel messages;

  void _onMessagesChanged() {
    notifyListeners();
  }

  Future<void> onLoad() async {
    if (!startLoading()) return;

    try {
      await Future.wait([messages.onLoad()]);
      doneLoading();
      if (messages.hasError) loadingFailed(onLoad);
    } catch (e, _) {
      loadingFailed(onLoad);
    }
  }

  @override
  void dispose() {
    messages.removeListener(_onMessagesChanged);
    super.dispose();
  }
}
