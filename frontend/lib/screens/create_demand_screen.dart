import 'package:flutter/material.dart';

class CreateDemandScreen extends StatefulWidget {
  final int artisanId;
  final String artisanName;
  final Map<String, dynamic>? selectedService;

  const CreateDemandScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
    this.selectedService,
  });

  @override
  State<CreateDemandScreen> createState() => _CreateDemandScreenState();
}

class _CreateDemandScreenState extends State<CreateDemandScreen> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';

  @override
  void initState() {
    super.initState();
    if (widget.selectedService != null) {
      _description = widget.selectedService!['name'];
    }
  }

  void _tryCreateDemand() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement demand creation logic
      print('Artisan ID: ${widget.artisanId}');
      print('Description: $_description');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demande pour ${widget.artisanName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description de la demande',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Veuillez décrire votre demande'
                    : null,
                onSaved: (value) => _description = value!,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _tryCreateDemand,
                child: const Text('Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
