import 'package:flutter/material.dart';

// Widget para el diseño de los campos a introducir en un formulario
class CustomTextField extends StatefulWidget {
  final IconData? icon;
  final String hint;
  final bool isPassword;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onEditingComplete;
  final bool? readOnly;

  const CustomTextField({
    super.key,
    this.icon,
    required this.hint,
    this.isPassword = false,
    required this.controller,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    this.onEditingComplete,
    this.readOnly = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? !_isPasswordVisible : false,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      onEditingComplete: widget.onEditingComplete,
      readOnly: widget.readOnly ?? false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        errorMaxLines: 2,
        filled: true,
        fillColor: widget.readOnly == true
            ? const Color.fromARGB(255, 214, 208, 208)
            : Colors.white,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(156, 168, 168, 168),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : (widget.icon != null ? Icon(widget.icon, color: const Color.fromRGBO(184, 184, 184, 100)) : null),
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Color.fromRGBO(189, 189, 189, 0.612),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF112363),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF112363),
            width: 2.5,
          ),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          //fontWeight: FontWeight.bold,
        ),
      ),
      validator: widget.validator,
    );
  }
  
}