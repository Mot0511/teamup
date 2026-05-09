import 'package:flutter/material.dart';
import 'package:teamup/features/teams/teams.dart';

class BottomButtonsWidget extends StatefulWidget {
  const BottomButtonsWidget({super.key});

  @override
  State<BottomButtonsWidget> createState() => _BottomButtonsWidgetState();
}

class _BottomButtonsWidgetState extends State<BottomButtonsWidget> with SingleTickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  late Animatable tween;

  bool isFiltersVisible = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    controller.addListener(() => setState(() {}));
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutQuad);
    tween = Tween<double>(begin: 60, end: 300);
  }

  void toggleFilters() {
    if (controller.status == AnimationStatus.completed) {
      controller.reverse();
    } else {
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: tween.evaluate(animation),
            child: Material(
              color: theme.canvasColor,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: toggleFilters,
                    child: Text(
                      'Быстрый поиск',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 200)
                ],
              )
            ),
          ),
        ),
        SizedBox(width: 5),
        SizedBox(
          width: 60,
          height: 60,
          child: Material(
            color: theme.canvasColor,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateTeamView())),
              child: Center(
                child: Icon(Icons.add, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}