import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_socket_example/core/i18n/strings.dart';
import 'package:flutter_socket_example/core/locator.dart';
import 'package:flutter_socket_example/ui/chat_page.dart';

void main() async {
  final _ = WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    Locator.init();
    super.initState();
  }

  @override
  void reassemble() {
    Locator.reassemble();
    super.reassemble();
  }

  @override
  void dispose() {
    Locator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        Strings.delegate,
      ],
      home: const ChatPage(),
    );
  }
}
