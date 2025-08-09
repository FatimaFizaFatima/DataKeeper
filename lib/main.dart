import 'package:data_keeper/screens/user_list_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataKeeper',
      theme: ThemeData(
        fontFamily: 'Sen',
      ),
      debugShowCheckedModeBanner: false,
      home: const UserListScreen(),
    );
  }
}
