import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  @override
  _ResetPasswordConfirmScreenState createState() => _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState extends State<ResetPasswordConfirmScreen> {
  TextEditingController resetCodeController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isLoading = false;

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = 'https://mqlapp.onrender.com/api/reset_password';

    // Verificar se as senhas são iguais
    if (newPasswordController.text != confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas não coincidem!')),
      );

      setState(() {
        isLoading = false;
      });

      return;
    }

    final Map<String, String> data = {
      'reset_code': resetCodeController.text,
      'new_password': newPasswordController.text,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      // Redirecionar para a tela de login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else if (response.statusCode == 404) {
      Map<String, dynamic> errorData = jsonDecode(response.body);
      String errorMessage = errorData['error'] ?? 'Código de redefinição inválido.';
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
        title: Text('Confirme a redefinição de senha'),
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
                      'Redefina a senha',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(height: 150),
                    TextField(
                      controller: resetCodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de redefinição',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 6,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: newPasswordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
                    TextField(
                      controller: confirmNewPasswordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirme a nova senha',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 100),
                    ElevatedButton(
                      onPressed: resetPassword,
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
                            'Confirmar',
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