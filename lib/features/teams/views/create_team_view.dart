import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/teams/bloc/teams_bloc.dart';
import 'package:teamup/features/teams/bloc/teams_events.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/views/choose_members_view.dart';
import 'package:teamup/features/teams/views/team2_view.dart';
import 'package:teamup/features/teams/widgets/team_icon_widget.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/models/game.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teamup/widgets/widgets.dart';

class CreateTeamView extends StatefulWidget {
  CreateTeamView({super.key, this.team});
  final Team? team;

  @override
  State<CreateTeamView> createState() => _CreateTeamViewState();
}

class _CreateTeamViewState extends State<CreateTeamView> {

  late int id;

  final nameController = TextEditingController();
  List<User> members = [];
  List<User> addedMembers = [];
  List<User> removedMembers = [];
  File? choosenIcon;

  final teamsRepository = GetIt.I<TeamsRepository>();

  final userBloc = GetIt.I<UserBloc>();
  final teamsBloc = GetIt.I<TeamsBloc>();

  String? nameError;

  @override
  void initState() {
    super.initState();
    if (userBloc.state is UserStateLoaded) {
      if (widget.team == null) {
        id = DateTime.now().millisecondsSinceEpoch;
        members.add((userBloc.state as UserStateLoaded).user);
      } else {
        nameController.text = widget.team!.name;
        members = widget.team!.users;
      }
      setState(() {});
    }
  }

  void pickAvatarHandler() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выбор логотипа команды',
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg'],
    );

    if (result != null) {
      choosenIcon = File(result.files.single.path!);
      setState(() {});
      if (widget.team != null) {
        teamsRepository.updateIconCache(widget.team!.id, MemoryImage(await choosenIcon!.readAsBytes()));
      }
    }

  }

  void createTeamHandler(context) {
    final name = nameController.text.trim();
    if (name == '') {
      nameError = 'Придумай название команды';
      setState(() {});
      return;
    }
    final team = Team(id: id, users: members, name: name);
    teamsBloc.add(AddTeam(team: team, choosenIcon: choosenIcon));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeamView(team: team)));
  }

  void editTeamHandler(context) {
    final name = nameController.text.trim();
    if (name == '') {
      nameError = 'Придумай название команды';
      setState(() {});
      return;
    }
    widget.team!.name = name;
    widget.team!.users = members;
    teamsBloc.add(EditTeam(
      team: (widget.team as Team),
      choosenIcon: choosenIcon,
      addedMembers: addedMembers,
      removedMembers: removedMembers,
    ));
    Navigator.pop(context);
  }

  void chooseMembers() async {
    final List<User>? choosenMembers = await Navigator.push(context, MaterialPageRoute(builder: (_) => ChooseMembersView()));
    if (choosenMembers == null) return;
    members += choosenMembers.where((member) => !members.contains(member)).toList();
    addedMembers += choosenMembers.where((member) => !addedMembers.contains(member)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.team != null ? 'Изменение' : 'Создание'} команды')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  TeamIconWidget(
                    id: widget.team != null ? widget.team!.id : id,
                    image: choosenIcon != null ? FileImage((choosenIcon as File)) : null
                  ),
                  SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: pickAvatarHandler,
                    child: Text('Изменить иконку команды'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white
                    ),
                  ),
                ],
              )
            ),
            SizedBox(height: 20),
            Field(title: 'Название команды', controller: nameController, error: nameError),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Участники команды', style: theme.textTheme.titleLarge),
                IconButton(
                  onPressed: chooseMembers,
                  icon: Icon(Icons.add)
                )
              ],
            ),
            Column(
              children: members.map((member) => 
                UserWidget(
                  user: member,
                  trailing: member.uid != (userBloc.state as UserStateLoaded).user.uid
                    ? IconButton(
                      onPressed: () {
                        members.remove(member);
                        removedMembers.add(member);
                        setState(() {});
                      },
                      icon: Icon(Icons.delete, color: Colors.red, size: 30)
                    )
                    : null
                )
              ).toList()
            ),
            SizedBox(height: 50),
            Align(
              alignment: Alignment.centerRight,
              child: widget.team == null
                ? ElevatedButton(
                  onPressed: () => createTeamHandler(context),
                  child: Text('Создать команду', style: theme.textTheme.labelMedium)
                )
                : ElevatedButton(
                  onPressed: () => editTeamHandler(context),
                  child: Text('Сохранить', style: theme.textTheme.labelMedium)
                )
            )
          ],
        ),
      )
    );
  }
}