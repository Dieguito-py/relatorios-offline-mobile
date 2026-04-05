import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> opcoes;
  final bool obrigatorio;
  final ValueChanged<String?>? onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.controller,
    required this.opcoes,
    this.obrigatorio = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = controller.text.isEmpty ? null : controller.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: obrigatorio ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.25),
        ),
        items: opcoes
            .map((op) => DropdownMenuItem(
          value: op,
          child: Text(op),
        ))
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '';
          onChanged?.call(value);
        },
        validator: obrigatorio
            ? (value) => value == null || value.isEmpty ? "Selecione uma opção" : null
            : null,
      ),
    );
  }
}
