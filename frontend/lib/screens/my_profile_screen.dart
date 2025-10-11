    ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Félicitations ! Votre profil sera mis en avant pendant 24h.')),
        );
        // TODO: Call backend API to activate the boost
        // Example: APIService.applyProfileBoost();
      },
    );
  }

  Future<void> _handleSubscription() async {
    final token = await TokenManager().getToken();
    if (token == null) {
      // Handle case where token is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur d\'authentification. Veuillez vous reconnecter.')),
      );
      return;
    }

    final backendUrl = '${ApiConstants.baseUrl}/api/premium/subscribe';

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': 5000, // 5000 FCFA
          'service': 'Abonnement Premium Proxi-Services 1 an',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['paymentUrl'];
        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $paymentUrl';
        }
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nom de l\'Artisan', // Placeholder
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Plombier', // Placeholder
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              if (_isPremium)
                const Chip(
                  label: Text('Statut: Premium'),
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.all(12),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.star),
                  label: const Text('Devenir Premium (5000 FCFA/an)'),
                  onPressed: _handleSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text('Mon Parrainage'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReferralScreen()));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              if (_isBoosting)
                const Chip(
                  label: Text('Profil actuellement boosté !'),
                  backgroundColor: Colors.greenAccent,
                  padding: EdgeInsets.all(12),
                )
              else if (!_isPremium) // Can only boost if not premium (as premium has permanent boost)
                ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Booster mon profil pour 24h'),
                  onPressed: _handleBoost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 16),
              if (!_isPremium)
                const Text(
                  'Regardez une courte publicité pour mettre votre profil en avant dans les résultats de recherche.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}��