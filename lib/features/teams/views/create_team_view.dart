import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/teams/widgets/box_button_widget.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';
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
  List members = [];
  List<User> addedMembers = [];
  List<User> removedMembers = [];

  Uint8List? choosenIconBytes;
  bool isUploadingIcon = false;
  bool isPublic = false;
  Game? teamGame;

  final teamsRepository = GetIt.I<TeamsRepository>();
  final userBloc = GetIt.I<UserBloc>();
  final teamsBloc = GetIt.I<TeamsBloc>();
  final supabase = GetIt.I<SupabaseClient>();

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
        isPublic = widget.team!.isPublic;
        teamGame = widget.team!.game;
      }
      setState(() {});
    }
  }

  Future<void> pickAvatarHandler() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выбор логотипа команды',
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg'],
      withData: true
    );

    if (result != null) {
      choosenIconBytes = Uint8List.fromList(result.files.first.bytes!);
      setState(() {});
      if (widget.team != null) {
        teamsRepository.updateIconCache(widget.team!.id, MemoryImage(choosenIconBytes!));
        await teamsRepository.uploadIcon(widget.team!.id, choosenIconBytes!);
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
    final team = Team(id: id, users: members, name: name, isPublic: isPublic, game: teamGame);
    teamsBloc.add(AddTeam(team: team, choosenIconBytes: choosenIconBytes));
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
    widget.team!.isPublic = isPublic;
    widget.team!.game = teamGame;
    teamsBloc.add(EditTeam(
      team: widget.team!,
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

  Future<void> chooseGame() async {
    final Game? game = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseGameView()));

    if (game == null) return;
    teamGame = game;
    setState(() {});
  }

  void leaveTeam() {
    final uid = supabase.auth.currentUser!.id;
    teamsBloc.add(RemoveTeam(team: widget.team!, uid: uid));
    Navigator.of(context).pop();
    Navigator.of(context).pop();
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
                    image: choosenIconBytes != null ? MemoryImage(choosenIconBytes!) : null
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
            Field(title: 'Название', controller: nameController, error: nameError),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Участники', style: theme.textTheme.titleLarge),
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
                  trailing: member.uid != (userBloc.state as UserStateLoaded).user.uid && (widget.team == null || !widget.team!.isPublic)
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
            SizedBox(height: 20),
            if (widget.team == null || !widget.team!.isPublic || widget.team!.game != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Главная игра команды', style: theme.textTheme.titleLarge),
                SizedBox(height: 10),
                GameWidget(game: teamGame, onTap: widget.team == null || !widget.team!.isPublic ? chooseGame : null),
                SizedBox(height: 20),
              ],
            ),
            if (widget.team == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Приватность', style: theme.textTheme.titleLarge),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoxButton(title: 'Публичная команда', body: 'В нее сможет вcтупить кто угодно', isActive: isPublic, onTap: () => setState(() => isPublic = true)),
                    SizedBox(height: 10),
                    BoxButton(title: 'Приватная команда', body: 'Только участники команды смогут добавлять новых игроков', isActive: !isPublic, onTap: () => setState(() => isPublic = false))
                  ],
                ),
                SizedBox(height: 50),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.team != null && widget.team!.isPublic && widget.team!.users.where((user) => user.uid == supabase.auth.currentUser?.id).toList().isNotEmpty)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  theme.colorScheme.error
                  ),
                  onPressed: () => leaveTeam(),
                  child: Text('Выйти из команды', style: theme.textTheme.labelMedium)
                ),
                SizedBox(width: 5),
                if (widget.team == null)
                ElevatedButton(
                  onPressed: () => createTeamHandler(context),
                  child: Text('Создать команду', style: theme.textTheme.labelMedium)
                )
                else
                ElevatedButton(
                  onPressed: () => editTeamHandler(context),
                  child: Text('Сохранить', style: theme.textTheme.labelMedium)
                )
              ],
            )
          ],
        ),
      )
    );
  }
}