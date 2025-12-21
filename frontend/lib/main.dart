
import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const AskaApp());
}

class AskaApp extends StatelessWidget {
  const AskaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}