import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'signup_screen.dart';
import 'reset_password.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;
  bool keepMeLoggedIn = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  void toggleKeepMeLoggedIn() {
    setState(() {
      keepMeLoggedIn = !keepMeLoggedIn;
    });
  }

  Future<void> saveKeepMeLoggedInState(bool value, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepMeLoggedIn', value);
    if (value) {
      await prefs.setInt('userId', userId);
    } else {
      // Se o usuário desmarcar "Me mantenha conectado", você pode limpar o userId
      await prefs.remove('userId');
    }
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = 'https://mqlapp.onrender.com/api/authentication';

    if (!_isValidEmail(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-mail inválido!')),
      );

      setState(() {
        isLoading = false;
      });

      return;
    }

    final Map<String, String> data = {
      'email': emailController.text,
      'password': passwordController.text,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      if (keepMeLoggedIn) {
        await saveKeepMeLoggedInState(keepMeLoggedIn, responseData['id']);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            //fullName: responseData['full_name'],
            userId: responseData['id'],
          ),
        ),
      );
    }
    else if (response.statusCode == 404) {
      Map<String, dynamic> errorData = jsonDecode(response.body);
      String errorMessage = errorData['erro'] ?? 'Usuário não encontrado!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Houve um erro sistêmico!')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Inicie sua sessão',
            style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo2.png',
                      width: 225,
                      height: 225,
                    ),
                    SizedBox(height: 1),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
                    if (emailController.text.isNotEmpty && !_isValidEmail(emailController.text))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'E-mail inválido',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        child: Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1),
                    Row(
                      children: [
                        Checkbox(
                          value: keepMeLoggedIn,
                          onChanged: (value) {
                            toggleKeepMeLoggedIn();
                          },
                        ),
                        Text('Me mantenha conectado'),
                      ],
                    ),
                    SizedBox(height: 1),
                    TextButton(
                      onPressed: () async {
                        await _showResetPasswordScreen();
                      },
                      child: Text(
                        'Esqueci minha senha',
                        style: TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.none,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _showSignUpScreen();
                      },
                      child: Text(
                        'Cadastre-se',
                        style: TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.none,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showResetPasswordScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(),
      ),
    );
  }

  Future<void> _showSignUpScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpScreen(),
      ),
    );
  }
}