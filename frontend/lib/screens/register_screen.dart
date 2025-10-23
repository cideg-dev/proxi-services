import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';
import '../widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {};

  // State for special fields
  bool _assuranceProfessionnelle = false;
  List<String> _selectedLangues = [];
  String? _sexe;
  bool _isPasswordVisible = false;
  bool _isHoveringRegister = false;

  final List<String> _availableLanguages = ['Français', 'Anglais', 'Fon', 'Yoruba', 'Bariba', 'Dendi', 'Mina'];

  String _errorMessage = '';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Initialize controllers for common fields
    _controllers['telephone'] = TextEditingController();
    _controllers['location'] = TextEditingController();
    
    // Initialize controllers based on role
    if (widget.role == 'client') {
      _controllers['nom_complet'] = TextEditingController();
      _controllers['adresse'] = TextEditingController();
    } else if (widget.role == 'artisan') {
      _controllers['nom_complet'] = TextEditingController();
      _controllers['specialite'] = TextEditingController();
      _controllers['description'] = TextEditingController();
      _controllers['annees_experience'] = TextEditingController();
      _controllers['horaires_ouverture'] = TextEditingController();
      _controllers['siret'] = TextEditingController();
      _controllers['site_web'] = TextEditingController();
    } else if (widget.role == 'commercant') {
      _controllers['nom_entreprise'] = TextEditingController(); 
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
    _emailController.dispose();
    _passwordController.dispose();
    _controllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
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
        profileData[key] = controller.text.trim();
      });

      if (widget.role == 'client') {
        profileData['sexe'] = _sexe;
      } else {
        profileData['langues_parlees'] = _selectedLangues;
        profileData['assurance_professionnelle'] = _assuranceProfessionnelle;
      }

      try {
        await _authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          widget.role,
          profileData
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        debugPrint("Registration failed: $e");
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscription ${widget.role}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GlassCard(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24.0),
                        children: _buildFormFields(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(BuildContext context) {
    final theme = Theme.of(context);
    List<Widget> fields = [];

    fields.add(Text(
      'Créez votre compte',
      style: theme.textTheme.displaySmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ));
    fields.add(const SizedBox(height: 24.0));

    fields.add(TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez entrer une adresse e-mail';
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(value)) return 'Entrez un email valide';
        return null;
      },
    ));
    fields.add(const SizedBox(height: 16.0));
    fields.add(TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: theme.colorScheme.secondary),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) => (value == null || value.length < 6) ? 'Le mot de passe doit faire au moins 6 caractères' : null,
    ));
    fields.add(const SizedBox(height: 24.0));

    if (widget.role == 'commercant') {
      fields.add(_buildTextField('nom_entreprise', 'Nom de l\'entreprise'));
    } else {
      fields.add(_buildTextField('nom_complet', 'Nom complet'));
    }

    final bool isCommercant = widget.role == 'commercant';
    fields.add(_buildTextField(
      'telephone',
      isCommercant ? 'Téléphone' : 'Téléphone (Optionnel)',
    ));
    fields.add(_buildTextField('location', 'Coordonnées GPS (lat,lon) (Optionnel)'));

    if (widget.role == 'client') {
      fields.add(_buildTextField('adresse', 'Adresse'));
      fields.add(_buildSexeDropdown(context));
    } else if (widget.role == 'artisan') {
      fields.addAll([
        _buildTextField('specialite', 'Spécialité (Optionnel)'),
        _buildTextField('description', 'Description', maxLines: 3),
        _buildTextField('annees_experience', 'Années d\'expérience', keyboardType: TextInputType.number),
        _buildTextField('horaires_ouverture', 'Horaires d\'ouverture'),
        _buildTextField('siret', 'Numéro SIRET (Optionnel)'),
        _buildTextField('site_web', 'Site Web (Optionnel)'),
        _buildLanguagesPicker(context),
        _buildAssuranceSwitch(context),
      ]);
    } else if (widget.role == 'commercant') {
      fields.addAll([
        _buildTextField('type_commerce', 'Type de commerce (Optionnel)'),
        _buildTextField('description', 'Description', maxLines: 3),
        _buildTextField('adresse', 'Adresse'),
        _buildTextField('horaires_ouverture', 'Horaires d\'ouverture'),
        _buildTextField('siret', 'Numéro SIRET (Optionnel)'),
        _buildTextField('site_web', 'Site Web (Optionnel)'),
        _buildLanguagesPicker(context),
        _buildAssuranceSwitch(context),
      ]);
    }
    
    fields.add(const SizedBox(height: 24.0));

    if (_errorMessage.isNotEmpty) {
      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Icon(Icons.error, color: theme.colorScheme.error, size: 60),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_isLoading) {
      fields.add(const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ));
    } else {
      fields.add(
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringRegister = true),
          onExit: (_) => setState(() => _isHoveringRegister = false),
          child: ElevatedButton(
            onPressed: _tryRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isHoveringRegister ? theme.colorScheme.secondary : theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
            child: const Text('S\'inscrire'),
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
        controller: _controllers[key] ?? TextEditingController(),
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (!label.contains('(Optionnel)') && (value == null || value.isEmpty)) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildSexeDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _sexe,
        decoration: const InputDecoration(labelText: 'Sexe'),
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

  Widget _buildAssuranceSwitch(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: const Text('Assurance professionnelle'),
      value: _assuranceProfessionnelle,
      onChanged: (bool value) {
        setState(() {
          _assuranceProfessionnelle = value;
        });
      },
      activeColor: theme.colorScheme.primary,
      inactiveThumbColor: theme.colorScheme.surface,
    );
  }

  Widget _buildLanguagesPicker(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Langues parlées'),
        child: Wrap(
          spacing: 8.0,
          children: _availableLanguages.map((lang) {
            final isSelected = _selectedLangues.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedLangues.add(lang);
                  } else {
                    _selectedLangues.remove(lang);
                  }
                });
              },
              backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.black : theme.colorScheme.onSurface),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary.withOpacity(0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}