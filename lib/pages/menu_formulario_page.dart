import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/api_service.dart';
import 'package:relatoriooffline/pages/dynamic_form_page.dart';

class MenuFormularioPage extends StatefulWidget {
  const MenuFormularioPage({super.key});

  @override
  State<MenuFormularioPage> createState() => _MenuFormularioPageState();
}

class _MenuFormularioPageState extends State<MenuFormularioPage> {
  List<Map<String, dynamic>> _templates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await AppDatabase.instance.obterTemplates();
    setState(() {
      _templates = templates;
    });
  }

  Future<void> _syncTemplates() async {
    setState(() => _isLoading = true);
    try {
      final auth = await AppDatabase.instance.obterToken();
      final token = auth?['token'];
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado')),
          );
        }
        return;
      }

      final api = ApiService();
      final templates = await api.getTemplates(token);

      if (templates != null) {
        await AppDatabase.instance.salvarTemplates(templates);
        await _loadTemplates();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Templates sincronizados com sucesso!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao buscar templates do servidor')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na sincronização: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulários'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncTemplates,
              tooltip: 'Sincronizar Templates',
            ),
        ],
      ),
      body: _templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Nenhum formulário disponível.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _syncTemplates,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar agora'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final templateRecord = _templates[index];
                final templateData = jsonDecode(templateRecord['dados_json']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildFormButton(
                    context: context,
                    icon: Icons.assignment,
                    title: templateRecord['nome'],
                    subtitle: templateRecord['descricao'] ?? 'Toque para preencher',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DynamicFormPage(template: templateData),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFormButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF616595)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF616595),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFb0b2ca),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: const Color(0xFF3A3F7A),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF3A3F7A),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

