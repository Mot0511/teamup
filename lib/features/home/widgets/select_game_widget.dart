import 'package:flutter/material.dart';
import 'package:teamup/theme.dart';

class SelectGameWidget extends StatefulWidget {
  const SelectGameWidget({super.key});

  @override
  _SelectGameWidget createState() => _SelectGameWidget();
}

class _SelectGameWidget extends State<SelectGameWidget> {
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
          hint: Text("Выберите игру", style: TextStyle(color: Colors.white)),
          items: <String>['Minecraft', 'Rust', 'Dota 2']
              .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              })
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedValue = newValue;
            });
          },
          focusColor: Color(0x00058c74),
          icon: Icon(Icons.arrow_drop_down_circle_outlined),
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
