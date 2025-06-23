import 'package:flutter/material.dart';
import 'package:teamup/features/teams/widgets/team_widget.dart';

class TeamsView extends StatelessWidget {
  const TeamsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Команды')),
      body: ListView(
        children: List.generate(5, (i) => TeamWidget(id: i.toString()))
      ),
    );
  }
}