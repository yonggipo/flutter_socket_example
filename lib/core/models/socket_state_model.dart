import 'package:flutter_socket_example/core/models/base_model.dart';

class SocketStateModel extends BaseModel {
  bool connected = false;
  String id = '' ;

  Future<void> onLoad() async {}
}
