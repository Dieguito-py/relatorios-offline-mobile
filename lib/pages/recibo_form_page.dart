import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/sync_service.dart';

class ReciboFormPage extends StatefulWidget {
  const ReciboFormPage({super.key});

  @override
  State<ReciboFormPage> createState() => _ReciboFormPageState();
}

class _ReciboFormPageState extends State<ReciboFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  Future<void> _salvarFormulario() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvando recibo...')),
      );

      final payload = {
        'tipo': 'recibo',
        'criadoEm': DateTime.now().toIso8601String(),
      };

      try {
        final id = await AppDatabase.instance.salvarFormulario(
          tipo: 'recibo',
          dadosJson: jsonEncode(payload),
        );
        final enviado = await SyncService.instance.trySendRelatorio(payload, localId: id);

        if (enviado) {
          await AppDatabase.instance.marcarComoSincronizado(id);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enviado
                  ? 'Recibo sincronizado com sucesso.'
                  : 'Recibo salvo como pendente para sincronizar.',
            ),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar recibo: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        } else {
          _isSaving = false;
        }
      }
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
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _salvarFormulario,
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
        onPressed: _isSaving ? null : _salvarFormulario,
        backgroundColor: _isSaving ? Colors.grey : Colors.orange.shade700,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Salvando...' : 'Salvar'),
      ),
    );
  }
}

