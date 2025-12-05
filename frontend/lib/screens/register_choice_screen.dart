import 'package:flutter/material.dart';
import 'register_screen.dart'; // Assuming you have a general register screen

class RegisterChoiceScreen extends StatelessWidget {
  const RegisterChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S\'inscrire en tant que'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register/client');
              },
              child: const Text('Client'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register/artisan');
              },
              child: const Text('Artisan'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register/commercant');
              },
              child: const Text('Commerçant'),
            ),
          ],
        ),
      ),
    );
  }
}
