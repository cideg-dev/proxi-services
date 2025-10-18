import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Basic info
  String _email = '';
  String _password = '';
  
  // Form controllers
  final Map<String, TextEditingController> _controllers = {};

  // State for special fields
  bool _assuranceProfessionnelle = false;
  List<String> _selectedLangues = [];
  String? _sexe;
  bool _isPasswordVisible = false;

  final List<String> _availableLanguages = ['Français', 'Anglais', 'Fon', 'Yoruba', 'Bariba', 'Dendi', 'Mina'];

  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for common fields that are always present
    _controllers['nom_complet'] = TextEditingController();
    _controllers['telephone'] = TextEditingController();
    _controllers['location'] = TextEditingController();
    
    // Initialize controllers based on role
    if (widget.role == 'client') {
      _controllers['adresse'] = TextEditingController();
    } else if (widget.role == 'artisan') {
      _controllers['specialite'] = TextEditingController();
      _controllers['description'] = TextEditingController();
      _controllers['annees_experience'] = TextEditingController();
      _controllers['horaires_ouverture'] = TextEditingController();
      _controllers['siret'] = TextEditingController();
      _controllers['site_web'] = TextEditingController();
    } else if (widget.role == 'commercant') {
      _controllers['type_commerce'] = TextEditingController();
      _controllers['description'] = TextEditingController();
      _controllers['adresse'] = TextEditingController();
      _controllers['horaires_ouverture'] = TextEditingController();
      _controllers['siret'] = TextEditingController();
      _controllers['site_web'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _tryRegister() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      Map<String, dynamic> profileData = {};
      _controllers.forEach((key, controller) {
        profileData[key] = controller.text;
      });

      // Add special fields data
      if (widget.role == 'client') {
        profileData['sexe'] = _sexe;
      } else {
        profileData['assurance_professionnelle'] = _assuranceProfessionnelle;
        profileData['langues_parlees'] = _selectedLangues;
      }

      try {
        // The register method now takes profile data
        await _authService.register(_email, _password, widget.role, profileData);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription ${widget.role}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: _buildFormFields(),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    // --- Champs d'authentification ---
    fields.add(
      TextFormField(
        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer une adresse e-mail';
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
          if (!emailRegex.hasMatch(value)) return 'Entrez un email valide';
          return null;
        },
        onSaved: (value) => _email = value!,
      ),
    );
    fields.add(const SizedBox(height: 16.0));
    fields.add(
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        obscureText: !_isPasswordVisible,
        validator: (value) => (value == null || value.length < 6) ? 'Le mot de passe doit faire au moins 6 caractères' : null,
        onSaved: (value) => _password = value!,
      ),
    );
    fields.add(const SizedBox(height: 24.0));

    // --- Champs de profil communs ---
    fields.add(_buildTextField('nom_complet', 'Nom complet'));
    fields.add(_buildTextField('telephone', 'Téléphone'));
    fields.add(_buildTextField('location', 'Coordonnées GPS (lat,lon)'));

    // --- Champs Spécifiques au rôle ---
    if (widget.role == 'client') {
      fields.add(_buildTextField('adresse', 'Adresse'));
      fields.add(_buildSexeDropdown());
    } else if (widget.role == 'artisan') {
      fields.addAll([
        _buildTextField('specialite', 'Spécialité'),
        _buildTextField('description', 'Description', maxLines: 3),
        _buildTextField('annees_experience', 'Années d\'expérience', keyboardType: TextInputType.number),
        _buildTextField('horaires_ouverture', 'Horaires d\'ouverture'),
        _buildTextField('siret', 'Numéro SIRET (Optionnel)'),
        _buildTextField('site_web', 'Site Web (Optionnel)'),
        _buildLanguagesPicker(),
        _buildAssuranceSwitch(),
      ]);
    } else if (widget.role == 'commercant') {
      fields.addAll([
        _buildTextField('type_commerce', 'Type de commerce'),
        _buildTextField('description', 'Description', maxLines: 3),
        _buildTextField('adresse', 'Adresse'),
        _buildTextField('horaires_ouverture', 'Horaires d\'ouverture'),
        _buildTextField('siret', 'Numéro SIRET (Optionnel)'),
        _buildTextField('site_web', 'Site Web (Optionnel)'),
        _buildLanguagesPicker(),
        _buildAssuranceSwitch(),
      ]);
    }
    
    fields.add(const SizedBox(height: 24.0));

    // --- Error and Loading Indicators ---
    if (_errorMessage.isNotEmpty) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Lottie.asset('assets/lottie/error.json', height: 80),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      fields.add(Center(child: Lottie.asset('assets/lottie/loading.json', height: 100)));
    } else {
      fields.add(
        ElevatedButton(
          onPressed: _tryRegister,
          child: const Text('S\'inscrire'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      );
    }

    return fields;
  }

  Widget _buildTextField(String key, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (!key.contains('(Optionnel)') && (value == null || value.isEmpty)) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildSexeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _sexe,
        decoration: const InputDecoration(
          labelText: 'Sexe',
          border: OutlineInputBorder(),
        ),
        items: ['Homme', 'Femme', 'Autre'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _sexe = newValue;
          });
        },
        validator: (value) => value == null ? 'Veuillez sélectionner votre sexe' : null,
      ),
    );
  }

  Widget _buildAssuranceSwitch() {
    return SwitchListTile(
      title: const Text('Assurance professionnelle'),
      value: _assuranceProfessionnelle,
      onChanged: (bool value) {
        setState(() {
          _assuranceProfessionnelle = value;
        });
      },
    );
  }

  Widget _buildLanguagesPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Langues parlées',
          border: OutlineInputBorder(),
        ),
        child: Wrap(
          spacing: 8.0,
          children: _availableLanguages.map((lang) {
            return FilterChip(
              label: Text(lang),
              selected: _selectedLangues.contains(lang),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedLangues.add(lang);
                  } else {
                    _selectedLangues.remove(lang);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}