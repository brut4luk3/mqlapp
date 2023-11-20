import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reset_password_confirm.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController emailController = TextEditingController();

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  bool isLoading = false;

  Future<void> sendResetCode() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = 'https://mqlapp.onrender.com/api/request_password_reset';

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
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Código de redefinição enviado com sucesso! Verifique seu e-mail.')),
      );
      // Redirecionar para a página reset_password_confirm
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetPasswordConfirmScreen()),
      );
    } else if (response.statusCode == 404) {
      Map<String, dynamic> errorData = jsonDecode(response.body);
      String errorMessage = errorData['error'] ?? 'E-mail não encontrado na base de dados.';
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
        title: Text('Redefina sua senha'),
        backgroundColor: Colors.redAccent,
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
                    Text(
                      'Insira seu e-mail de login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(height: 200),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'E-mail de login',
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
                    SizedBox(height: 200),
                    ElevatedButton(
                      onPressed: sendResetCode,
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
                            'Enviar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
}