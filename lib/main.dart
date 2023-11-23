import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtenha o estado salvo do checkbox
  bool keepMeLoggedIn = await getKeepMeLoggedInState();

  // Verifique a saúde do servidor antes de iniciar o aplicativo
  bool isServerHealthy = await checkServerHealth();

  if (isServerHealthy) {
    runApp(MyApp(keepMeLoggedIn: keepMeLoggedIn));
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

Future<bool> getKeepMeLoggedInState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('keepMeLoggedIn') ?? false;
}

class MyApp extends StatelessWidget {
  final bool keepMeLoggedIn;

  MyApp({required this.keepMeLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQLapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<int>(
        future: getUserId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return keepMeLoggedIn
                ? HomeScreen(userId: snapshot.data ?? 0)
                : LoginScreen();
          } else {
            // Pode exibir um indicador de carregamento enquanto espera pelo resultado
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Future<int> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId') ?? 0; // Ou outro valor padrão, se apropriado
  }
}