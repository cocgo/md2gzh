import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MarkdownEditorApp());
}

class MarkdownEditorApp extends StatelessWidget {
  const MarkdownEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MD公众号',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1D1D1F),
          contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
