class Message {
  final int? id;
  final String username;
  final String message;
  final String timestamp;
  final bool isMine;

  Message({
    this.id,
    required this.username,
    required this.message,
    required this.timestamp,
    this.isMine = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      username: json['username'] as String,
      message: json['message'] as String,
      timestamp: json['timestamp'] as String,
      isMine: false,
    );
  }

  DateTime get dateTime => DateTime.parse(timestamp);
}

class SystemMessage {
  final String message;
  final String timestamp;

  SystemMessage({
    required this.message,
    required this.timestamp,
  });

  factory SystemMessage.fromJson(Map<String, dynamic> json) {
    return SystemMessage(
      message: json['message'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  DateTime get dateTime => DateTime.parse(timestamp);
}

// 통합 메시지 타입
abstract class ChatItem {
  String get timestamp;
  DateTime get dateTime;
}

class ChatMessageItem implements ChatItem {
  final Message message;

  ChatMessageItem(this.message);

  @override
  String get timestamp => message.timestamp;

  @override
  DateTime get dateTime => message.dateTime;
}

class ChatSystemMessageItem implements ChatItem {
  final SystemMessage systemMessage;

  ChatSystemMessageItem(this.systemMessage);

  @override
  String get timestamp => systemMessage.timestamp;

  @override
  DateTime get dateTime => systemMessage.dateTime;
}
