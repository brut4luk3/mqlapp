import 'package:flutter/material.dart';

import 'screens/login_screen.dart'; // Certifique-se de substituir pelo caminho correto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialize o servidor ou realize as configurações necessárias aqui
  await initializeServer();

  runApp(MyApp());
}

Future<void> initializeServer() async {
  // Adicione aqui a lógica de inicialização do servidor, se necessário
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQLapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Inicie com a tela de login
    );
  }
}