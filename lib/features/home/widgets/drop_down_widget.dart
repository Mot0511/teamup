import 'package:flutter/material.dart';

class DropdownItem {
  final String text;
  final String value;

  const DropdownItem({required this.text, required this.value});
}

class DropdowmWidget extends StatelessWidget {
  const DropdowmWidget({super.key, required this.items, required this.value, required this.onChange});
  final List<DropdownItem> items;
  final String value;
  final Function(String? value) onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.cardColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      width: MediaQuery.of(context).size.width,
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        items: items.map((DropdownItem item) {
          return DropdownMenuItem(value: item.value, child: Text(item.text));
        }).toList(),
        onChanged: (value) => onChange(value),
        focusColor: Color(0x00058c74),
        icon: Icon(Icons.keyboard_arrow_down, size: 40),
        underline: Container(),
        borderRadius: BorderRadius.circular(5),
        dropdownColor: theme.cardColor,
        iconEnabledColor: Colors.white,
        iconDisabledColor: Color(0x00058c74),
      ),
    );
  }
}
