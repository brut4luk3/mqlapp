import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'home_screen.dart';
import 'dart:io';

class UpdateDeleteCompanyScreen extends StatefulWidget {
  final int companyId;
  final int userId;

  UpdateDeleteCompanyScreen({required this.companyId, required this.userId});

  @override
  _UpdateDeleteCompanyScreenState createState() =>
      _UpdateDeleteCompanyScreenState();
}

class _UpdateDeleteCompanyScreenState extends State<UpdateDeleteCompanyScreen> {
  final List<String> _segments = [];
  String _selectedSegment = '';
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _instagramController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  MemoryImage? _selectedLogo;

  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSegments();
    _fetchCompanyDetails();
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

  Future<void> _fetchCompanyDetails() async {
    final String apiUrl =
        'https://mqlapp.onrender.com/api/get_company_details';

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
        _nameController.text = responseData['name'];
        _descriptionController.text = responseData['description'];
        _phoneController.text = responseData['phone'];
        _instagramController.text = responseData['instagram'];
        _emailController.text = responseData['email'];
        _selectedSegment = responseData['segment'];
        _addressController.text = responseData['address'];
        _loadLogo(responseData['logo']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter detalhes da empresa!')),
      );
    }
  }

  void _loadLogo(String logoBase64) {
    if (logoBase64.isNotEmpty) {
      final List<int> bytes = base64Decode(logoBase64);
      final MemoryImage memoryImage = MemoryImage(Uint8List.fromList(bytes));

      setState(() {
        _selectedLogo = memoryImage;
      });
    } else {
      setState(() {
        _selectedLogo = null;
      });
    }
  }


  void _selectSegment() {
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
                            if (_selectedSegment == _segments[index])
                              Icon(Icons.check, color: Colors.redAccent),
                            if (_selectedSegment != _segments[index])
                              Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedSegment = _segments[index];
                        });
                        Navigator.pop(context);
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
  }

  Key key = UniqueKey();

  void _uploadLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      try {
        final PlatformFile file = result.files.single;
        final Uint8List newBytes = await File(file.path!).readAsBytes();
        setState(() {
          _selectedLogo = MemoryImage(newBytes);
          key = UniqueKey(); // Atualize a chave para forçar a reconstrução
        });
      } catch (e) {
        print('Erro ao converter bytes do arquivo: $e');
      }
    }
  }

  void _updateCompany() async {
    if (_validateInputs()) {
      setState(() {
        _isLoading = true;
      });

      final Uint8List bytes = _selectedLogo!.bytes as Uint8List;

      final String apiUrl = 'https://mqlapp.onrender.com/api/update_company';

      final Map<String, dynamic> data = {
        'company_id': widget.companyId,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'instagram': _instagramController.text.startsWith('@')
            ? _instagramController.text
            : '@${_instagramController.text}',
        'phone': _phoneController.text,
        'email': _emailController.text,
        'selected_segment': _selectedSegment,
        'image_base64': base64Encode(bytes),
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

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados da empresa atualizados com sucesso!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen(userId: widget.userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar empresa!')),
        );
      }
    }
  }

  void _deleteCompany() async {
    bool shouldDelete = await _showDeleteConfirmationDialog() ?? false;

    if (shouldDelete) {
      final String apiUrl =
          'https://mqlapp.onrender.com/api/delete_company/${widget.companyId}';

      final http.Response response = await http.delete(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Empresa deletada com sucesso!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => HomeScreen(userId: widget.userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir empresa!')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Confirmação')),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Esta ação irá excluir sua empresa permanentemente.\nTem certeza que deseja continuar?',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Sim'),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Não'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _instagramController.text.isEmpty ||
        _emailController.text.isEmpty ||
        !_isValidEmail(_emailController.text) ||
        _selectedSegment.isEmpty ||
        _selectedLogo == null ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente!')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width * 0.45;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edite ou exclua a empresa'),
        backgroundColor: Colors.redAccent,
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
              // Logo Atual ou Nova Foto
              _selectedLogo != null
                  ? Center(
                child: ClipOval(
                  child: Material(
                    color: Colors.transparent,
                    child: Ink.image(
                      key: ValueKey<String>(_selectedLogo?.toString() ?? ''),
                      image: _selectedLogo!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      child: InkWell(
                        onTap: _uploadLogo,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  : Container(), // Mostra a foto atual aqui

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadLogo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(100, 0), // Ajuste o valor conforme necessário
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo),
                    SizedBox(width: 8),
                    Text(
                      'Atualizar logo',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _selectSegment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(100, 0), // Ajuste o valor conforme necessário
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedSegment.isEmpty
                          ? 'Selecionar segmento'
                          : _selectedSegment,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da empresa',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLength: 15,
                keyboardType: TextInputType.phone,
                onChanged: (text) {
                  final maskedText = _maskPhoneNumber(text);
                  _phoneController.value = TextEditingValue(
                    text: maskedText,
                    selection: TextSelection.collapsed(
                        offset: maskedText.length),
                  );
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _instagramController,
                decoration: InputDecoration(
                  labelText: 'Instagram',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail de contato',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLength: 50,
                keyboardType: TextInputType.emailAddress,
                onChanged: (text) {
                  setState(() {});
                },
              ),
              if (_emailController.text.isNotEmpty &&
                  !_isValidEmail(_emailController.text))
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                maxLength: 50,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _updateCompany,
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
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _deleteCompany,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(buttonWidth, 0),
                    ),
                    child: Text(
                      'Excluir',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
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