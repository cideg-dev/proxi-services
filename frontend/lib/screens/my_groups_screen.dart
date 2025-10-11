import 'package:flutter/material.dart';

class MyGroupsScreen extends StatelessWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Groupes'),
      ),
      body: const Center(
        child: Text('Page de mes groupes'),
      ),
    );
  }
}
