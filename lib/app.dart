import 'package:flutter/material.dart';

import 'ui/rumba_chat_screen.dart';
import 'ui/theme.dart';

class RumbaApp extends StatelessWidget {
  const RumbaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Rumba',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: RumbaColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: RumbaColors.red,
          surface: RumbaColors.card,
        ),
      ),
      home: const RumbaChatScreen(),
    );
  }
}
