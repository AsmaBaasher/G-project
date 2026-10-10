import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المحادثات'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: Center(child: Text('قائمة المحادثات')),
    );
  }
} 