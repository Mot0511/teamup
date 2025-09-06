import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/widgets/avatar_widget.dart';
import 'package:teamup/models/game.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teamup/widgets/widgets.dart';

class EditProfileView extends StatefulWidget {
  EditProfileView({super.key, required this.user});
  final User user;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {

  final usernameController = TextEditingController();
  final descriptionController = TextEditingController();
  final ageController = TextEditingController();

  final searchRepository = GetIt.I<SearchRepository>();
  final userRepository = GetIt.I<UserRepository>();

  String? usernameError;
  String? ageError;

  final userBloc = GetIt.I<UserBloc>();
  late String gender;
  int choosenGame = 0;
  File? choosenAvatar;

  List<Game>? games;
  void getGames() async {
    games = await searchRepository.getGames();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    
    getGames();
    usernameController.text = widget.user.username;
    descriptionController.text = widget.user.description ?? '';
    ageController.text = widget.user.age.toString();
    gender = widget.user.gender;
    choosenGame = widget.user.favouriteGame?.id ?? 0;
    setState(() {});
  }

  void pickAvatarHandler() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Выбор аватарки',
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg'],
    );

    if (result != null) {
      choosenAvatar = File(result.files.single.path!);
      setState(() {});
      userRepository.updateAvatarCache(widget.user.uid, MemoryImage(await choosenAvatar!.readAsBytes()));
    }
  }

  void saveChangesHandler(context) async {
    final username = usernameController.text.trim();
    final age = ageController.text.trim();
    final description = descriptionController.text.trim();
    if (username == '') {
      usernameError = 'Придумай юзернейм';
      setState(() {});
      return;
    }
    if (await userRepository.isUsernameExists(username)) {
      usernameError = 'Пользователь с таким именем уже существует';
      setState(() {});
      return;
    }
    if (age == '') {
      ageError = 'Укажи свой возраст';
      setState(() {});
      return;
    }
    if (double.tryParse(age) == null) {
      ageError = 'Возраст должен быть числом';
      setState(() {});
      return;
    }
    widget.user.username = username;
    widget.user.description = description != '' ? description : null;
    widget.user.age = int.parse(age);
    widget.user.gender = gender;
    widget.user.favouriteGame = choosenGame != 0 ? games?.where((game) => game.id == choosenGame).toList()[0] : null;
    userBloc.add(UpdateUser(user: widget.user, choosenAvatar: choosenAvatar));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Изменение профиля')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  AvatarWidget(
                    uid: widget.user.uid, 
                    image: choosenAvatar != null ? FileImage((choosenAvatar as File)) : null
                  ),
                  OutlinedButton(
                    onPressed: pickAvatarHandler,
                    child: Text('Изменить аватарку'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white
                    ),
                  ),
                ],
              )
            ),
            SizedBox(height: 20),
            Field(title: 'Имя пользователя', controller: usernameController, error: usernameError),
            Field(title: 'Описание профиля', controller: descriptionController, maxLines: 5),
            Field(title: 'Возраст', controller: ageController, error: ageError),
            Text('Пол:', style: theme.textTheme.labelLarge),
            DropdownButton(
              isExpanded: true,
              value: gender,
              items: [
                DropdownMenuItem(child: Text('Мужской'), value: 'male'),
                DropdownMenuItem(child: Text('Женский'), value: 'female')
              ], 
              onChanged: (value) => setState(() => gender = (value as String))
            ),
            SizedBox(height: 20),
            games != null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Любимая игра:', style: theme.textTheme.labelLarge),
                  DropdownButton(
                    isExpanded: true,
                    value: choosenGame,
                    items: [DropdownMenuItem(child: Text('Нет'), value: 0)] + 
                      (games?.map((game) => DropdownMenuItem(child: Text(game.name), value: game.id)).toList() as List<DropdownMenuItem<int>>),
                    onChanged: (value) => setState(() => choosenGame = (value as int))
                  )
                ],
              )
              : Center(child: CircularProgressIndicator()),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => saveChangesHandler(context), 
                  child: Text('Сохранить', style: theme.textTheme.labelMedium)
                ),
              )
          ],
        ),
      )
    );
  }
}