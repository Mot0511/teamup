import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);
  bool isSearching = false;

  void searchHandler() {
    if (isSearching) {
      controller.forward();
    } else {
      controller.reverse();
    }
    isSearching = !isSearching;
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Teamup', style: theme.textTheme.headlineMedium),
            )
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  width: isSearching ? 150 : 180,
                  height: isSearching ? 150 : 180,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: const Color(0xff004323),
                      border: Border.all(color: theme.primaryColor, width: 5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: InkWell(
                      onTap: searchHandler,
                      customBorder: CircleBorder(),
                      splashColor: theme.primaryColor,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic)),
                        child: Icon(Icons.search, color: Colors.white, size: 100)
                      )
                    )
                  ),
                ),
                SizedBox(height: 20),
              ]
            )
          ),
          Expanded(
            flex: 4,
            child: SizedBox.shrink()
          )
        ],
      ),
    );
  }
}