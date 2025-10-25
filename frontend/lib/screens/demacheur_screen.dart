import 'package:flutter/material.dart';
import 'package:frontend/services/demacheur_service.dart';

class DemacheurScreen extends StatefulWidget {
  const DemacheurScreen({Key? key}) : super(key: key);

  @override
  _DemacheurScreenState createState() => _DemacheurScreenState();
}

class _DemacheurScreenState extends State<DemacheurScreen> {
  final DemacheurService _demacheurService = DemacheurService();
  String _status = 'Chargement...';
  String? _expiresAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionStatus();
  }

  Future<void> _fetchSubscriptionStatus() async {
    try {
      final data = await _demacheurService.getSubscriptionStatus();
      setState(() {
        _status = data['status'];
        _expiresAt = data['expires_at'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Erreur';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir Démacheur'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Statut de l\'abonnement: $_status'),
                    if (_expiresAt != null)
                      Text('Expire le: $_expiresAt'),
                    const SizedBox(height: 20),
                    if (_status != 'active')
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement subscription logic
                        },
                        child: const Text('S\'abonner (2000 F CFA)'),
                      )
                    else
                      ElevatedButton(
                        onPressed: null,
                        child: const Text('Abonnement Actif'),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
