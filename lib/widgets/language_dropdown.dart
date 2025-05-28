import 'package:flutter/material.dart';

class LanguageDropdown extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String?>? onChanged;

  final List<String>? languages;

  const LanguageDropdown({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.languages,
  });


  @override
  Widget build(BuildContext context) {
    final List<String> languageOptions = languages ??
    [
      'Español',
      'Inglés',
      'Francés',
      'Alemán',
      'Italiano',
      'Portugués',
      'Chino'
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF112363),
          width: 2,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: 'Seleccione el idioma...',
          hintStyle: TextStyle(
            color: Color.fromRGBO(158, 158, 158, 1),
            fontSize: 16,
          ),
        ),
        items: languageOptions.map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF112363)),
        dropdownColor: Colors.white,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        menuMaxHeight: 200,
        isExpanded: true,
      ),
    );
  }
}
