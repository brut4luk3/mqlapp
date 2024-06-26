import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class CompanyDetails extends StatefulWidget {
  final int companyId;

  CompanyDetails({required this.companyId});

  @override
  _CompanyDetailsState createState() => _CompanyDetailsState();
}

class _CompanyDetailsState extends State<CompanyDetails> {
  late CompanyDetailsData companyDetailsData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    companyDetailsData = CompanyDetailsData(
      companyId: 0,
      name: '',
      description: '',
      logo: '',
      address: '',
      email: '',
      instagram: '',
      phone: '',
      segment: '',
      userId: 0,
    );
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
        SnackBar(content: Text('Erro ao obter detalhes da empresa!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalhes da Empresa',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/fundo.png',
                  fit: BoxFit.cover,
                ),
                Column(
                  children: [
                    SizedBox(height: 16),
                    ClipOval(
                      child: Image.memory(
                        base64Decode(companyDetailsData.logo),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      companyDetailsData.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 8),
                    _buildSegmentLabel(companyDetailsData.segment),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showDescriptionPopup(
                          context,
                          companyDetailsData.description,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Container(
                        width: 270,
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '${companyDetailsData.description.length > 50 ? '${companyDetailsData.description.substring(0, 50)}...Leia mais' : companyDetailsData.description}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildText('Instagram:', companyDetailsData.instagram),
                    SizedBox(height: 10),
                    _buildText('Telefone:', _formatPhoneNumber(companyDetailsData.phone)),
                    SizedBox(height: 10),
                    _buildText('E-mail de Contato:', companyDetailsData.email),
                    SizedBox(height: 10),
                    _buildText('Endereço:', companyDetailsData.address),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            String url = 'https://api.whatsapp.com/send?phone=${_formatPhoneNumberForWhatsApp(companyDetailsData.phone)}';
                            Uri new_url = Uri.parse(url);
                            _launchURL(new_url);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Whatsapp',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            String url = 'https://www.instagram.com/${companyDetailsData.instagram}';
                            Uri new_url = Uri.parse(url);
                            _launchURL(new_url);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Instagram',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentLabel(String segment) {
    // Remove chaves e separa as palavras
    List<String> segmentWords = segment.replaceAll('{', '').replaceAll('}', '').split(',');

    return Text(
      segmentWords.join(', '),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
        color: Colors.redAccent,
      ),
    );
  }

  Widget _buildText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  void _showDescriptionPopup(BuildContext context, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text('Descrição'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(description),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Fechar'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Verifica se o telefone está no padrão (47)99999-9999
    final RegExp regex = RegExp(r'^\(\d{2}\)\d{5}-\d{4}$');
    if (!regex.hasMatch(phoneNumber)) {
      // Se não estiver, tenta ajustar
      phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (phoneNumber.length == 11) {
        phoneNumber = '(${phoneNumber.substring(0, 2)})${phoneNumber.substring(2, 7)}-${phoneNumber.substring(7)}';
      }
    }
    return phoneNumber;
  }

  String _formatPhoneNumberForWhatsApp(String phoneNumber) {
    // Remove caracteres não numéricos
    final String formattedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    return formattedNumber;
  }

  void _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Não foi possível abrir o link: $url';
    }
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