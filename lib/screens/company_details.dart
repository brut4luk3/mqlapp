import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompanyDetails extends StatefulWidget {
  final int companyId;

  CompanyDetails({required this.companyId});

  @override
  _CompanyDetailsState createState() => _CompanyDetailsState();
}

class _CompanyDetailsState extends State<CompanyDetails> {
  late CompanyDetailsData? companyDetailsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompanyDetails();
  }

  Future<void> fetchCompanyDetails() async {
    final String apiUrl = 'https://mqlapp.onrender.com/api/get_company_details';

    final Map<String, dynamic> data = {
      'company_id': widget.companyId,
    };

    final http.Response response = await http.post(
      Uri.parse(apiUrl),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      setState(() {
        companyDetailsData = CompanyDetailsData.fromJson(responseData);
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter detalhes da empresa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Empresa'),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : buildCompanyDetailsBody(),
    );
  }

  Widget buildCompanyDetailsBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nome: ${companyDetailsData!.name}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text('Descrição: ${companyDetailsData!.description}'),
          SizedBox(height: 8),
          Text('Endereço: ${companyDetailsData!.address}'),
          SizedBox(height: 8),
          Text('E-mail: ${companyDetailsData!.email}'),
          SizedBox(height: 8),
          Text('Instagram: ${companyDetailsData!.instagram}'),
          SizedBox(height: 8),
          Text('Telefone: ${companyDetailsData!.phone}'),
          SizedBox(height: 8),
          Text('Segmento: ${companyDetailsData!.segment}'),
        ],
      ),
    );
  }
}

class CompanyDetailsData {
  final int companyId;
  final String name;
  final String description;
  final String logo;
  final String address;
  final String email;
  final String instagram;
  final String phone;
  final String segment;
  final int userId;

  CompanyDetailsData({
    required this.companyId,
    required this.name,
    required this.description,
    required this.logo,
    required this.address,
    required this.email,
    required this.instagram,
    required this.phone,
    required this.segment,
    required this.userId,
  });

  factory CompanyDetailsData.fromJson(Map<String, dynamic> json) {
    return CompanyDetailsData(
      companyId: json['company_id'],
      name: json['name'],
      description: json['description'],
      logo: json['logo'],
      address: json['address'],
      email: json['email'],
      instagram: json['instagram'],
      phone: json['phone'],
      segment: json['segment'],
      userId: json['user_id'],
    );
  }
}