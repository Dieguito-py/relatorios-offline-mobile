import 'package:flutter/material.dart';

class MenuFormularioPage extends StatelessWidget {
  const MenuFormularioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulários'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormButton(
              context: context,
              icon: Icons.family_restroom,
              title: 'Cadastro de Família',
              subtitle: 'Atingida por Desastre',
              onTap: () => Navigator.pushNamed(context, '/familia_form'),
            ),
            const SizedBox(height: 24),
            _buildFormButton(
              context: context,
              icon: Icons.receipt_long,
              title: 'Recibo de Assistência',
              subtitle: 'Item de Assistência Humanitária',
              onTap: () => Navigator.pushNamed(context, '/recibo_form'),
            ),
          ],
        ),
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
          border: Border.all(color: Color(0xFF616595)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF616595),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFb0b2ca),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Color(0xFF3A3F7A),
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
            Icon(
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

