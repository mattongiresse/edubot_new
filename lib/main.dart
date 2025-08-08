import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const EduBotApp());
}

class EduBotApp extends StatelessWidget {
  const EduBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduBot',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginPage(),
    );
  }
}