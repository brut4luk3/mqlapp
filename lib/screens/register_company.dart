import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'home_screen.dart';

class RegisterCompanyScreen extends StatefulWidget {
  final int userId;

  RegisterCompanyScreen({required this.userId});

  @override
  _RegisterCompanyScreenState createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  final List<String> _segments = [];
  List<String> _selectedSegments = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _instagramController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  File? _selectedLogo;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  bool _isLoading = false;

  String _selectedSegmentsText = 'Selecionar segmento';

  @override
  void initState() {
    super.initState();
    _fetchSegments();
  }

  Future<void> _fetchSegments() async {
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
  }

  void _updateSelectedSegmentsText() {
    setState(() {
      _selectedSegmentsText = _selectedSegments.isEmpty
          ? 'Selecionar segmento'
          : _selectedSegments.join(', ');
    });
  }

  void _selectSegment() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              margin: EdgeInsets.all(20),
              child: Center(
                child: ListView.builder(
                  itemCount: _segments.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_segments[index]),
                                if (_selectedSegments.contains(_segments[index]))
                                  IconButton(
                                    icon: Icon(Icons.check, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _selectedSegments.remove(_segments[index]);
                                        _updateSelectedSegmentsText();
                                      });
                                    },
                                  )
                                else
                                  IconButton(
                                    icon: Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _selectedSegments.add(_segments[index]);
                                        _updateSelectedSegmentsText();
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSegments.contains(_segments[index])
                                  ? _selectedSegments.remove(_segments[index])
                                  : _selectedSegments.add(_segments[index]);
                              _updateSelectedSegmentsText();
                            });
                          },
                        ),
                        Divider(height: 1, color: Colors.grey),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _uploadLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedLogo = File(result.files.single.path!);
      });
    }
  }

  void _registerCompany() async {
    if (_validateInputs()) {
      setState(() {
        _isLoading = true;
      });

      final bytes = _selectedLogo?.readAsBytesSync();

      final String apiUrl = 'https://mqlapp.onrender.com/api/register_company';

      final Map<String, dynamic> data = {
        'user_id': widget.userId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'instagram': _instagramController.text.startsWith('@')
            ? _instagramController.text
            : '@${_instagramController.text}',
        'phone': _phoneController.text,
        'email': _emailController.text,
        'selected_segment': _selectedSegments,
        'image_base64': base64Encode(bytes!),
        'address': _addressController.text,
      };

      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Empresa salva com sucesso!')),
        );
        _clearForm();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen(userId: widget.userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar empresa!')),
        );
      }
    }
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _instagramController.text.isEmpty ||
        _emailController.text.isEmpty ||
        !_isValidEmail(_emailController.text) ||
        _selectedSegments.isEmpty ||
        _selectedLogo == null ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente!')),
      );
      return false;
    }
    return true;
  }

  void _clearForm() {
    setState(() {
      _nameController.text = '';
      _descriptionController.text = '';
      _phoneController.text = '';
      _instagramController.text = '';
      _emailController.text = '';
      _selectedSegments = [];
      _selectedLogo = null;
      _addressController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registre uma nova empresa',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Cadastre sua empresa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da empresa',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                maxLines: 4,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone celular',
                  border: OutlineInputBorder(),
                ),
                maxLength: 15,
                keyboardType: TextInputType.phone,
                onChanged: (text) {
                  final maskedText = _maskPhoneNumber(text);
                  _phoneController.value = TextEditingValue(
                    text: maskedText,
                    selection: TextSelection.collapsed(offset: maskedText.length),
                  );
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _instagramController,
                decoration: InputDecoration(
                  labelText: 'Instagram',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail de contato',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                keyboardType: TextInputType.emailAddress,
                onChanged: (text) {
                  setState(() {});
                },
              ),
              if (_emailController.text.isNotEmpty && !_isValidEmail(_emailController.text))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'E-mail inválido',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Endereço',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _selectSegment,
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: _selectedSegments.isEmpty
                          ? 'Selecionar segmento'
                          : _selectedSegments.join(', '),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Segmentos',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _selectedLogo != null
                  ? Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: FileImage(_selectedLogo!),
                ),
              )
                  : Container(),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _uploadLogo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(buttonWidth, 0),
                  ),
                  icon: Icon(Icons.add_a_photo, color: Colors.white),
                  label: Text(
                    'Selecionar logo',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _registerCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(buttonWidth, 0),
                  ),
                  child: Text(
                    'Salvar',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskPhoneNumber(String text) {
    text = text.replaceAll(RegExp(r'\D'), '');
    if (text.length == 11) {
      return '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7)}';
    } else if (text.length >= 6) {
      return '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6)}';
    } else if (text.length >= 2) {
      return '(${text.substring(0, 2)}) ${text.substring(2)}';
    } else {
      return text;
    }
  }
}