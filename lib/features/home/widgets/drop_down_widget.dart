import 'package:flutter/material.dart';

class DropdownItem {
  final String text;
  final String value;

  const DropdownItem({required this.text, required this.value});
}

class DropdowmWidget extends StatefulWidget {
  const DropdowmWidget({super.key, required this.items, required this.hint});
  final List<DropdownItem> items;
  final String hint;

  @override
  _DropdownWidget createState() => _DropdownWidget();
}

class _DropdownWidget extends State<DropdowmWidget> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.cardColor,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10),
        width: MediaQuery.of(context).size.width,
        child: DropdownButton<String>(
          isExpanded: true, // Устанавливаем флаг для расширения на всю ширину
          value: selectedValue,
          hint: Text(widget.hint, style: TextStyle(color: Colors.white)),
          items: widget.items.map((DropdownItem item) {
            return DropdownMenuItem(value: item.value, child: Text(item.text));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedValue = newValue;
            });
          },
          focusColor: Color(0x00058c74),
          icon: Icon(Icons.keyboard_arrow_down, size: 40),
          underline: Container(),
          borderRadius: BorderRadius.circular(5),
          dropdownColor: theme.cardColor,
          iconEnabledColor: Colors.white,
          iconDisabledColor: Color(0x00058c74),
        ),
      ),
    );
  }
}
