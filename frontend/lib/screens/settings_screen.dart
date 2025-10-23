import 'package:flutter/material.dart';
import 'package:frontend/screens/change_password_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien : $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionTitle(context, 'Affichage'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Mode Sombre'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
                secondary: const Icon(Icons.dark_mode_outlined),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle(context, 'Compte'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () async {
              await authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          const Divider(),
          _buildSectionTitle(context, 'Légal'),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Conditions d\'utilisation'),
            onTap: () => _launchURL(context, 'https://example.com/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            onTap: () => _launchURL(context, 'https://example.com/privacy'),
          ),
          const Divider(),
          _buildSectionTitle(context, 'À propos'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version de l\'application'),
            subtitle: Text(_appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode_outlined),
            title: const Text('Développé par'),
            subtitle: const Text('cideg-dev'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contacter le support'),
            subtitle: const Text('support@proxi-services.com'),
            onTap: () => _launchURL(context, 'mailto:support@proxi-services.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
