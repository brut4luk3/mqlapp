import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String fullName;
  final int userId;

  HomeScreen({required this.fullName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo, $fullName!'),
            Text('ID do usuário: $userId'),
          ],
        ),
      ),
    );
  }
}