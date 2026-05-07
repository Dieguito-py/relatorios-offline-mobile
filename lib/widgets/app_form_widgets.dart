import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  final bool obrigatorio;

  const FieldLabel({super.key, required this.label, this.obrigatorio = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label + (obrigatorio ? ' *' : ''),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A3F7A),
        ),
      ),
    );
  }
}

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.obrigatorio = false,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.hintText,
    this.suffixIcon,
    this.onTap,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obrigatorio;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final String? hintText;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(label: label, obrigatorio: obrigatorio),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3A3F7A), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: validator ??
                (obrigatorio
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      }
                    : null),
          ),
        ],
      ),
    );
  }
}

class AppImagePickerButtons extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final String label;
  final bool obrigatorio;

  const AppImagePickerButtons({
    super.key,
    required this.onCamera,
    required this.onGallery,
    this.label = "Adicionar Foto",
    this.obrigatorio = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          FieldLabel(label: label, obrigatorio: obrigatorio),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Câmera"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3F7A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text("Galeria"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade800,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ImageHelper {
  static const int maxSizeBytes = 10 * 1024 * 1024; // 10MB

  static Future<Uint8List?> pickAndCompress(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    // maxWidth de 1920 (Full HD) e qualidade 80 geralmente resultam em arquivos de 1MB a 2MB
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    
    if (bytes.lengthInBytes > maxSizeBytes) {
      // Se ainda for maior que 10MB (raríssimo com as configs acima), avisar ou comprimir mais
      return null; 
    }

    return bytes;
  }

  static Future<List<Uint8List>> pickMultiAndCompress() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );

    List<Uint8List> result = [];
    for (var file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes <= maxSizeBytes) {
        result.add(bytes);
      }
    }
    return result;
  }
}



