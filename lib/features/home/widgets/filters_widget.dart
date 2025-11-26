import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:teamup/features/home/widgets/drop_down_widget.dart';
import 'package:teamup/models/game.dart';

class FiltersWidget extends StatefulWidget {
  const FiltersWidget({
    super.key, 
    required this.currentGame,
    required this.games,
    required this.onSetGame,

    required this.currentGender,
    required this.onSetGender,

    required this.currentTeamSize,
    required this.onSetTeamSize
  });
  final String currentGame;
  final List<Game> games;
  final Function onSetGame;

  final String currentGender;
  final Function onSetGender;

  final String currentTeamSize;
  final Function onSetTeamSize;

  @override
  State<FiltersWidget> createState() => _FiltersWidgetState();
}

class _FiltersWidgetState extends State<FiltersWidget> {


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
        DropdowmWidget(
          items: widget.games
              .map(
                (game) => DropdownItem(
                  text: game.name,
                  value: game.id.toString(),
                ),
              )
              .toList(),
          value: widget.currentGame,
          onChange: (value) =>
              widget.onSetGame(value)
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
          value: widget.currentTeamSize,
          onChange: (value) =>
              widget.onSetTeamSize(value)
        ),
        Text("Пол", style: theme.textTheme.labelMedium),
        DropdowmWidget(
          items: [
            DropdownItem(text: "Не важно", value: "null"),
            DropdownItem(text: "Мужской", value: "male"),
            DropdownItem(text: "Женский", value: "female"),
          ],
          value: widget.currentGender,
          onChange: (value) =>
              widget.onSetGender(value)
        ),
      ],
    );
  }
}