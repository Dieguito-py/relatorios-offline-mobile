import 'package:flutter/material.dart';

class ReciboFormPage extends StatefulWidget {
  const ReciboFormPage({super.key});

  @override
  State<ReciboFormPage> createState() => _ReciboFormPageState();
}

class _ReciboFormPageState extends State<ReciboFormPage> {
  final _formKey = GlobalKey<FormState>();

  void _salvarFormulario() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvando recibo...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo de Assistência'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarFormulario,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Recibo de Item de Assistência Humanitária',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Campos do recibo serão adicionados aqui.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvarFormulario,
        backgroundColor: Colors.orange.shade700,
        icon: const Icon(Icons.save),
        label: const Text('Salvar'),
      ),
    );
  }
}

