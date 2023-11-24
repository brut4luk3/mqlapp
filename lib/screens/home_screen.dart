import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'company_details.dart';
import 'company_screen.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CompanyData> companyDataList = [];
  String _selectedSegment = 'Todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    setState(() {
      _isLoading = true;
    });

    String apiUrl = 'https://mqlapp.onrender.com/api/get_companies_by_segment';

    final Map<String, dynamic> data = {
      'segment': _selectedSegment,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> companies = responseData['company_data'];

      setState(() {
        companyDataList = companies.map((data) => CompanyData.fromJson(data)).toList();
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não há empresas cadastradas neste segmento.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSegment() async {
    final List<String> _segments = [];

    final String apiUrl = 'https://mqlapp.onrender.com/api/get_segments';

    final http.Response response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final List<dynamic> segments = responseData['segments'];

      setState(() {
        _segments.addAll(segments.cast<String>());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter segmentos!')),
      );
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(20),
          child: Center(
            child: ListView.builder(
              itemCount: _segments.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      ListTile(
                        title: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Todos'),
                              if (_selectedSegment == 'Todos')
                                Icon(Icons.check, color: Colors.redAccent),
                              if (_selectedSegment != 'Todos')
                                Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedSegment = 'Todos';
                          });
                          Navigator.pop(context);
                          fetchCompanies();
                        },
                      ),
                      Divider(height: 1, color: Colors.grey),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ListTile(
                        title: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_segments[index - 1]),
                              if (_selectedSegment == _segments[index - 1])
                                Icon(Icons.check, color: Colors.redAccent),
                              if (_selectedSegment != _segments[index - 1])
                                Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedSegment = _segments[index - 1];
                          });
                          Navigator.pop(context);
                          fetchCompanies();
                        },
                      ),
                      Divider(height: 1, color: Colors.grey),
                    ],
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Você irá encerrar sua sessão. \n\nDeseja continuar?'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Não'),
                  ),
                  SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      _logout();
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    child: Text('Sim'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepMeLoggedIn', false);
    // Adicione qualquer outra lógica de logout necessária
  }

  Widget buildCompanyCard(CompanyData companyData) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyDetails(
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
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Veja mais detalhes',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Início',
            style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtro atual:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectSegment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedSegment,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: companyDataList.length,
                itemBuilder: (context, index) {
                  return buildCompanyCard(companyDataList[index]);
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompanyScreen(userId: widget.userId),
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
                  'Minhas empresas',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
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