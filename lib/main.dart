import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verifique a saúde do servidor antes de iniciar o aplicativo
  bool isServerHealthy = await checkServerHealth();

  if (isServerHealthy) {
    runApp(MyApp());
  } else {
    // Trate o caso em que o servidor não está saudável
    print('O servidor não está saudável. O aplicativo não será iniciado.');
  }
}

Future<bool> checkServerHealth() async {
  final healthCheckUrl = Uri.parse('https://mqlapp.onrender.com/healthcheck');

  try {
    final response = await http.get(healthCheckUrl);

    if (response.statusCode == 200) {
      // O servidor está saudável
      return true;
    } else {
      // O servidor não está saudável
      print('Erro no health check: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    // Ocorreu um erro ao fazer o health check
    print('Erro ao fazer o health check: $e');
    return false;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQLapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}