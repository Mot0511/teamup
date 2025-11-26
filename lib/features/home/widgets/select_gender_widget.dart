import 'package:flutter/material.dart';

class SelectGenderWidget extends StatefulWidget {
  const SelectGenderWidget({super.key});

  @override
  _SelectGenderWidget createState() => _SelectGenderWidget();
}

class _SelectGenderWidget extends State<SelectGenderWidget> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10),
        width: MediaQuery.of(context).size.width,
        child: DropdownButton<String>(
          isExpanded: true, // Устанавливаем флаг для расширения на всю ширину
          value: selectedValue,
          hint: Text("Выберите пол", style: TextStyle(color: Colors.white)),
          items: <String>['Мужской', 'Женский', 'Не важен']
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
          dropdownColor: Colors.grey,
          iconEnabledColor: Colors.white,
          iconDisabledColor: Color(0x00058c74),
        ),
      ),
    );
  }
}
