import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart'; // Importer le ChatService
import 'register_choice_screen.dart';
import 'home_screen.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Variables pour les effets de survol
  bool _isHoveringLogin = false;
  bool _isHoveringRegister = false;
  bool _isHoveringForgotPassword = false; // Ajout pour un futur bouton

  // Contrôleur et animation pour le fondu
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _tryLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final result = await _authService.login(_email, _password);
        final token = result['token'] as String?;

        if (token != null) {
          ChatService().connect();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          throw Exception('Token non reçu du serveur.');
        }

      } catch (e) {
        setState(() {
          _errorMessage = 'Email ou mot de passe incorrect. Veuillez réessayer.';
        });
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connexion'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Bienvenue',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48.0),
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer une adresse e-mail';
                                }
                                final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Entrez un email valide';
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value!,
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) => (value == null || value.length < 6) ? 'Le mot de passe doit faire au moins 6 caractères' : null,
                              onSaved: (value) => _password = value!,
                            ),
                            const SizedBox(height: 24.0),
                            if (_errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  children: [
                                    Lottie.asset('assets/lottie/error.json', height: 80, errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: theme.colorScheme.error, size: 60)),
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage,
                                      style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            if (_isLoading)
                              Center(child: Lottie.asset('assets/lottie/loading.json', height: 100))
                            else
                              MouseRegion(
                                onEnter: (_) => setState(() => _isHoveringLogin = true),
                                onExit: (_) => setState(() => _isHoveringLogin = false),
                                child: ElevatedButton(
                                  onPressed: _tryLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isHoveringLogin ? theme.colorScheme.secondary : theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onSecondary,
                                  ),
                                  child: const Text('Se connecter'),
                                ),
                              ),
                            MouseRegion(
                              onEnter: (_) => setState(() => _isHoveringRegister = true),
                              onExit: (_) => setState(() => _isHoveringRegister = false),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');},
                                style: TextButton.styleFrom(
                                  foregroundColor: _isHoveringRegister ? theme.colorScheme.primary : theme.colorScheme.secondary,
                                ),
                                child: const Text('Pas encore de compte ? S\'inscrire'),
                              ),
                            ),
                          ],
                        ),
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
}
