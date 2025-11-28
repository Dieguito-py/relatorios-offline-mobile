import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> opcoes;
  final bool obrigatorio;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.controller,
    required this.opcoes,
    this.obrigatorio = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: opcoes
            .map((op) => DropdownMenuItem(
          value: op,
          child: Text(op),
        ))
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '';
        },
        validator: obrigatorio
            ? (value) => value == null || value.isEmpty ? "Selecione uma opção" : null
            : null,
      ),
    );
  }
}
