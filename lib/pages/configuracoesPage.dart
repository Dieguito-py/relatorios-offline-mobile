import 'package:flutter/material.dart';
import 'package:relatoriooffline/services/apiService.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _ipController = TextEditingController();
  final _portaController = TextEditingController(text: '8084');

  @override
  void initState() {
    super.initState();
    if (ApiService.customBaseUrl.isNotEmpty) {
      final uri = Uri.parse(ApiService.customBaseUrl);
      _ipController.text = uri.host;
      _portaController.text = uri.port.toString();
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portaController.dispose();
    super.dispose();
  }

  void _salvarConfiguracao() {
    final ip = _ipController.text.trim();
    final porta = _portaController.text.trim();

    if (ip.isEmpty) {
      ApiService.customBaseUrl = '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usando URL padrão do sistema'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ApiService.customBaseUrl = 'http://$ip:$porta/api';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL configurada: ${ApiService.customBaseUrl}'),
          backgroundColor: Colors.green,
        ),
      );
    }

    Navigator.pop(context);
  }

  void _testarConexao() async {
    final ip = _ipController.text.trim();
    final porta = _portaController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o IP do servidor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testando conexão...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Aqui você pode adicionar um teste de ping ou uma requisição simples
    final testUrl = 'http://$ip:$porta/api/auth/login';
    print('🧪 Testando: $testUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de API'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Configuração de Servidor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'URL Atual: ${ApiService.getBaseUrl()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dicas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Android Emulator: use 10.0.2.2\n'
                  '• Dispositivo físico: use o IP da sua máquina (ex: 192.168.1.100)\n'
                  '• Windows/Desktop: deixe em branco para usar localhost',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'IP do Servidor',
              hintText: '10.0.2.2 ou 192.168.1.100',
              prefixIcon: Icon(Icons.computer, color: Colors.orange.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
              ),
              helperText: 'Deixe vazio para usar localhost',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portaController,
            decoration: InputDecoration(
              labelText: 'Porta',
              hintText: '8084',
              prefixIcon: Icon(Icons.settings_ethernet, color: Colors.orange.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _salvarConfiguracao,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Configuração'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testarConexao,
            icon: const Icon(Icons.wifi_find),
            label: const Text('Testar Conexão'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.orange.shade700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

