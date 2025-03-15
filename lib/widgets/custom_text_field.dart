import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final IconData icon;
  final String hint;
  final bool isPassword;
  final TextEditingController controller; 
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onEditingComplete;

  const CustomTextField({
    super.key,
    required this.icon,
    required this.hint,
    this.isPassword = false,
    required this.controller, 
    this.validator,
    this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    this.onEditingComplete,
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
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromRGBO(184, 184, 184, 100),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : Icon(widget.icon, color: const Color.fromRGBO(184, 184, 184, 100)),
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Color.fromRGBO(164, 164, 164, 100),
          fontSize: 16,
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
      ),
      validator: widget.validator,
    );
  }
}
