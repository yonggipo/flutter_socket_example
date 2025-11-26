import 'package:flutter_socket_example/core/models/base_model.dart';
import 'package:flutter_socket_example/core/models/messages_model.dart';

class ChatModel extends BaseModel {
  ChatModel(this.messages);

  final MessagesModel messages;

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
}
