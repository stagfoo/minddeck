import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A home app draws the whole panel; letting the system letterbox it around
  // the status and gesture bars wastes height this screen does not have.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const RolidecksApp());
}

class RolidecksApp extends StatelessWidget {
  const RolidecksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rolidecks',
      debugShowCheckedModeBanner: false,
      theme: buildDeckTheme(),
      home: const HomeScreen(),
    );
  }
}
