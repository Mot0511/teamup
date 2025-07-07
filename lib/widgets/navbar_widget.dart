import 'package:flutter/material.dart';
import 'package:teamup/models/navitem.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.items,
    required this.currentView,
    required this.onTap,
  });
  final List<Navitem> items;
  final int currentView;
  final onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 75,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(i),
            customBorder: CircleBorder(),
            splashColor: Color.fromARGB(255, 58, 56, 56),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Icon(items[i].icon, color: currentView == i ? theme.primaryColor : Colors.white, size: 30),
                  Text(items[i].title, style: currentView == i 
                    ? theme.textTheme.labelSmall?.copyWith(color: theme.primaryColor, fontSize: 10)
                    : theme.textTheme.labelSmall?.copyWith(fontSize: 10)
                  )
                ],
              )
              )
            )
          )
        )
      )
    );
  }
}
