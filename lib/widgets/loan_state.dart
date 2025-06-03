import 'package:flutter/material.dart';

// Widget que muestra un dropdown con los estados posibles en los que puede encontrarse una solicitud de préstamo
class LoanStateDropdown extends StatefulWidget {
  final String selectedState;
  final ValueChanged<String?>? onChanged;
  final List<String> disabledOptions;

  const LoanStateDropdown({
    super.key,
    required this.selectedState,
    this.onChanged,
    this.disabledOptions = const [],
  });

  @override
  State<LoanStateDropdown> createState() => _LoanStateDropdownState();
}

class _LoanStateDropdownState extends State<LoanStateDropdown> {
  late String _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.selectedState;
  }

  // Para gestionar el color en función del estado
  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      case 'aceptado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> states = ['Pendiente', 'Aceptado', 'Rechazado'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF112363),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<String>(
        value: _currentState,
        onChanged: (newState) {
          if (newState != null) {
            setState(() {
              _currentState = newState;
            });
            widget.onChanged?.call(newState);
          }
        },
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF112363)),
        isExpanded: false,
        items: states.map((String state) {
          final isDisabled = widget.disabledOptions.contains(state);

          return DropdownMenuItem<String>(
            value: isDisabled ? null : state,
            enabled: !isDisabled,
            child: Text(
              state,
              style: TextStyle(
                color: isDisabled ? Colors.grey : _getStateColor(state),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        selectedItemBuilder: (BuildContext context) {
          return states.map((String state) {
            return Center(
              child: Text(
                state,
                style: TextStyle(
                  color: _getStateColor(state),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList();
        }
      ),
    );
  }

}