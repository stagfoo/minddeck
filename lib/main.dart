import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A home app draws the whole panel; letting the system letterbox it around
  // the status and gesture bars wastes height this screen does not have.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MindDeckApp());
}

class MindDeckApp extends StatelessWidget {
  const MindDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindDeck',
      debugShowCheckedModeBanner: false,
      theme: buildDeckTheme(),
      home: const HomeScreen(),
    );
  }
}
