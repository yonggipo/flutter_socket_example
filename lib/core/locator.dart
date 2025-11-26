import 'package:flutter_socket_example/core/constants.dart';
import 'package:flutter_socket_example/core/models/chat_model.dart';
import 'package:flutter_socket_example/core/models/messages_model.dart';
import 'package:flutter_socket_example/core/models/socket_state_model.dart';
import 'package:flutter_socket_example/core/repositories/socket_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:socket_io_client/socket_io_client.dart';

// import '../models/index.dart';
// import '../repositories/index.dart';
// import '../services/index.dart';

late GetIt _locate;
T locate<T extends Object>() => _locate();

abstract class Locator {
  static void init({GetIt? instance}) {
    _locate = instance ?? GetIt.instance;
    _registerSingletons();
    _registerFactories();
    _registerViewModels();
  }

  static void _registerSingletons() {
    _locate.registerLazySingleton<Socket>(() {
      return io(
        Constants.localhost,
        OptionBuilder()
            .setTransports(['websocket', 'polling']) // 전송 방식
            .disableAutoConnect() // 자동 연결 비활성화
            .enableReconnection() // 재연결 활성화
            .build(),
      );
    });
  }

  static void _registerFactories() {
    _locate.registerFactory(() => SocketRepository(locate<Socket>()));
  }

  static void _registerViewModels() {
    _locate.registerFactory(() => MessagesModel(locate<SocketRepository>()));
    _locate.registerFactory(() => ChatModel(locate<MessagesModel>()));
    _locate.registerFactory(() => SocketStateModel());
  }

  static void reassemble() {
    _locate.allowReassignment = true;
    _registerFactories();
    _registerViewModels();
    _locate.allowReassignment = false;
  }

  static void dispose() {
    _locate.reset();
  }
}
