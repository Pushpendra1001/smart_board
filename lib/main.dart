import 'dart:io';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:smart_board/pages/HomePage.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: HomePage(),
    );
  }
}
