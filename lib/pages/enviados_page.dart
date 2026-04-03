import 'package:flutter/material.dart';
import 'package:relatoriooffline/core/database/app_database.dart';

class EnviadosPage extends StatefulWidget {
  const EnviadosPage({super.key});

  @override
  State<EnviadosPage> createState() => _EnviadosPageState();
}

class _EnviadosPageState extends State<EnviadosPage> {
  List<Map<String, dynamic>> _formularios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarFormularios();
  }

  Future<void> _carregarFormularios() async {
    setState(() => _isLoading = true);

    final formularios = await AppDatabase.instance.obterFormularios(
      sincronizado: true,
    );

    if (mounted) {
      setState(() {
        _formularios = formularios;
        _isLoading = false;
      });
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'familia':
        return 'Família';
      case 'recibo':
        return 'Recibo';
      default:
        return tipo;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'familia':
        return Icons.family_restroom;
      case 'recibo':
        return Icons.receipt_long;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulários Enviados'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formularios.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum formulário enviado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarFormularios,
                  color: Colors.orange.shade700,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _formularios.length,
                    itemBuilder: (context, index) {
                      final form = _formularios[index];
                      final tipo = form['tipo'] as String;
                      final dataCriacao = DateTime.parse(
                        form['data_criacao'] as String,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getTipoIcon(tipo),
                              color: Colors.green.shade700,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            _getTipoLabel(tipo),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Enviado em: ${dataCriacao.day.toString().padLeft(2, '0')}/${dataCriacao.month.toString().padLeft(2, '0')}/${dataCriacao.year} às ${dataCriacao.hour.toString().padLeft(2, '0')}:${dataCriacao.minute.toString().padLeft(2, '0')}',
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sincronizado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

