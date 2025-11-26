import 'package:get_it/get_it.dart';

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

  static void _registerSingletons() {}

  static void _registerFactories() {}

  static void _registerViewModels() {}

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
