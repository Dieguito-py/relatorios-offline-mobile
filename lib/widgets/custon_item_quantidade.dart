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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Checkbox(
                value: marcado,
                activeColor: Colors.orange,
                onChanged: (v) {
                  final novoValor = v ?? false;
                  setState(() => marcado = novoValor);
                  widget.controllerMarcado.text = novoValor ? "Sim" : "Não";
                  if (!novoValor) {
                    widget.controllerQuantidade.clear();
                  }
                },
              ),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: widget.controllerQuantidade,
                  enabled: marcado,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "Qtd",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
        ),
      ),
    );
  }
}
