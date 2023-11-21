import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mql/screens/update_company.dart';
import 'dart:convert';
import 'register_company.dart';


class CompanyScreen extends StatefulWidget {
  final int userId;

  CompanyScreen({required this.userId});

  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  List<CompanyData> companyDataList = [];
  bool _isLoading = true; // Adiciona uma variável de estado para controlar o carregamento

  @override
  void initState() {
    super.initState();
    fetchUserCompanies();
  }

  Future<void> fetchUserCompanies() async {
    final String apiUrl = 'https://mqlapp.onrender.com/api/get_user_companies';

    final Map<String, dynamic> data = {
      'user_id': widget.userId,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData.containsKey('company_data')) {
        final List<dynamic> companies = responseData['company_data'];

        setState(() {
          companyDataList = companies.map((data) => CompanyData.fromJson(data)).toList();
          // Define _isLoading como false quando os dados são carregados
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Este usuário não tem empresas cadastradas.')),
        );
        // Define _isLoading como false em caso de erro
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cadastre sua primeira empresa!')),
      );
      // Define _isLoading como false em caso de erro
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de controle'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Suas empresas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Exibe a animação de carregamento enquanto os dados estão sendo carregados
            _isLoading
                ? Center(child: CircularProgressIndicator()) // Centraliza a animação de carregamento
                : Expanded(
              child: companyDataList.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                itemCount: companyDataList.length,
                itemBuilder: (context, index) {
                  return buildCompanyCard(companyDataList[index]);
                },
              )
                  : Center(child: Text('Você não tem empresas cadastradas.')),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Redireciona para a tela CompanyScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterCompanyScreen(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(horizontal: 116, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cadastrar empresa',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCompanyCard(CompanyData companyData) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateCompany(
              companyId: companyData.companyId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.memory(
                base64Decode(companyData.logo),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    companyData.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    companyData.description.length > 50
                        ? '${companyData.description.substring(0, 50)}...'
                        : companyData.description,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Clique para editar ou excluir',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyData {
  final int companyId;
  final String name;
  final String description;
  final String logo;

  CompanyData({
    required this.companyId,
    required this.name,
    required this.description,
    required this.logo,
  });

  factory CompanyData.fromJson(Map<String, dynamic> json) {
    return CompanyData(
      companyId: json['company_id'],
      name: json['name'],
      description: json['description'],
      logo: json['logo'],
    );
  }
}