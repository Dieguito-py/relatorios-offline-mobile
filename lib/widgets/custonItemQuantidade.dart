import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomItemQuantidade extends StatefulWidget {
  final String label;
  final TextEditingController controllerMarcado;
  final TextEditingController controllerQuantidade;

  const CustomItemQuantidade({
    super.key,
    required this.label,
    required this.controllerMarcado,
    required this.controllerQuantidade,
  });

  @override
  State<CustomItemQuantidade> createState() => _CustomItemQuantidadeState();
}

class _CustomItemQuantidadeState extends State<CustomItemQuantidade> {
  bool marcado = false;

  @override
  void initState() {
    super.initState();

    if (widget.controllerMarcado.text.isEmpty) {
      widget.controllerMarcado.text = "Não";
    }

    final texto = widget.controllerMarcado.text;
    marcado = texto.toLowerCase() == "sim";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: marcado,
            activeColor: Colors.orange,
            onChanged: (v) {
              setState(() => marcado = v ?? false);
              widget.controllerMarcado.text = marcado ? "Sim" : "Não";
            },
          ),

          // Label
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Campo de quantidade
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: widget.controllerQuantidade,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Qtd",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (marcado && (value == null || value.isEmpty)) {
                  return "Obrigatório";
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
