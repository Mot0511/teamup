import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/models/game.dart';

class FiltersWidget extends StatelessWidget {
  const FiltersWidget({
    super.key, 
    required this.currentGame,
    required this.onSetGame,

    required this.currentGender,
    required this.onSetGender,

    required this.currentTeamSize,
    required this.onSetTeamSize
  });
  final Game currentGame;
  final Function onSetGame;

  final String currentGender;
  final Function onSetGender;

  final String currentTeamSize;
  final Function onSetTeamSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Center(
          child: Text(
            "Фильтры поиска",
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        Text("Игра", style: theme.textTheme.labelMedium),
        GameWidget(
          game: currentGame, 
          onTap: () async {
            final game = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseGameView()));
            if (game != null) {
              onSetGame(game);
            }
          }
        ),
        Text(
          "Кол-во игроков в команде",
          style: theme.textTheme.labelMedium,
        ),
        DropdowmWidget(
          items: [
            DropdownItem(text: '2', value: '2'),
            DropdownItem(text: '3', value: '3'),
            DropdownItem(text: '4', value: '4'),
            DropdownItem(text: '5', value: '5'),
            DropdownItem(text: '6', value: '6'),
            DropdownItem(text: '7', value: '7'),
            DropdownItem(text: '8', value: '8'),
            DropdownItem(text: '9', value: '9'),
            DropdownItem(text: '10', value: '10'),
          ],
          value: currentTeamSize,
          onChange: (value) =>
              onSetTeamSize(value)
        ),
        Text("Пол", style: theme.textTheme.labelMedium),
        DropdowmWidget(
          items: [
            DropdownItem(text: "Не важно", value: "null"),
            DropdownItem(text: "Мужской", value: "male"),
            DropdownItem(text: "Женский", value: "female"),
          ],
          value: currentGender,
          onChange: (value) =>
              onSetGender(value)
        ),
      ],
    );
  }
}