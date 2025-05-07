import 'package:flutter/material.dart';

class SummaryInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const SummaryInputWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Resumen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.file_copy,
              size: 18,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          height: 200,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF687CFF), Color(0xFF2E3C94)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF112363),
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
