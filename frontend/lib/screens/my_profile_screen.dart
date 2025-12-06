import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/models/user_model.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late Future<User> _profileFuture;
  String? _userRole;

  // Controllers for form fields
  final Map<String, TextEditingController> _controllers = {};

  // State for special fields
  bool _assuranceProfessionnelle = false;
  List<String> _selectedLangues = [];
  String? _sexe;

  final List<String> _availableLanguages = ['Français', 'Anglais', 'Fon', 'Yoruba', 'Bariba', 'Dendi', 'Mina'];

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getProfile();
    _profileFuture.then((user) {
      _userRole = user.role;
      _initializeFields(user);
    });
  }

  void _initializeFields(User user) {
    final profile = user.toJson();
    profile.forEach((key, value) {
      if (value != null) {
        _controllers[key] = TextEditingController(text: value.toString());
      }
    });
    
    // Handle mapped fields that might have different keys in JSON vs Model
    if (!_controllers.containsKey('nom_complet') && user.name != null) {
      _controllers['nom_complet'] = TextEditingController(text: user.name);
    }
    if (!_controllers.containsKey('telephone') && user.phoneNumber != null) {
      _controllers['telephone'] = TextEditingController(text: user.phoneNumber);
    }
    if (!_controllers.containsKey('location') && user.city != null) {
      _controllers['location'] = TextEditingController(text: user.city);
    }
    if (!_controllers.containsKey('adresse') && user.address != null) {
      _controllers['adresse'] = TextEditingController(text: user.address);
    }

    setState(() {
      _assuranceProfessionnelle = profile['assurance_professionnelle'] ?? false;
      _sexe = profile['sexe'];
      if (profile['langues_parlees'] != null) {
        _selectedLangues = List<String>.from(profile['langues_parlees']);
      }
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> profileData = {};
      _controllers.forEach((key, controller) {
        profileData[key] = controller.text;
      });

      // Add special fields data
      profileData['assurance_professionnelle'] = _assuranceProfessionnelle;
      profileData['langues_parlees'] = _selectedLangues;
      profileData['sexe'] = _sexe;
      
      // Map back to model fields if necessary, but updateProfile takes a Map
      // so we can send what we have. API should handle it.

      try {
        await _authService.updateProfile(profileData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Enregistrer',
          )
        ],
      ),
      body: FutureBuilder<User>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement du profil: ${snapshot.error}'));
          }

          // Initialize controllers if they haven't been
          if (_controllers.isEmpty && snapshot.hasData) {
            _initializeFields(snapshot.data!);
            _userRole = snapshot.data!.role;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: _buildFormFields(),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFormFields() {
    if (_userRole == null) {
      return [const Center(child: Text("Impossible de déterminer le rôle de l'utilisateur."))];
    }

    List<Widget> fields = [];

    // --- Champs Communs ---
    fields.add(_buildTextField('nom_complet', 'Nom complet'));
    fields.add(_buildTextField('telephone', 'Téléphone'));
    fields.add(_buildTextField('location', 'Coordonnées GPS (lat,lon)'));

    // --- Champs Spécifiques ---
    if (_userRole == 'client') {
      fields.add(_buildTextField('adresse', 'Adresse'));
      fields.add(_buildSexeDropdown());
    } else if (_userRole == 'artisan') {
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
    } else if (_userRole == 'commercant') {
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

    return fields;
  }

  Widget _buildTextField(String key, String label, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    _controllers.putIfAbsent(key, () => TextEditingController());
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
          // Simple validation for non-optional fields
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