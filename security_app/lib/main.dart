import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:security_app/pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.lexendDecaTextTheme(),
      ),
    );
  }
}

