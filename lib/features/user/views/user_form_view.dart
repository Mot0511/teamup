import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/widgets/widgets.dart';

class UserFormView extends StatefulWidget {
  UserFormView({super.key, required this.userdata});
  final sb.User userdata;

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {

  final usernameController = TextEditingController();
  final ageController = TextEditingController();
  String gender = 'male';

  final userRepository = GetIt.I<UserRepository>();
  final userBloc = GetIt.I<UserBloc>();
  final notificationsService = GetIt.I<NotificationsService>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();
  final prefs = GetIt.I<SharedPreferences>();

  String? usernameError;
  String? ageError;

  Game? choosenGame;

  @override
  void initState() {
    super.initState();

    loadGames();
  }

  Future<void> loadGames() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await homeProvider.loadGames();
  }

  Future<void> submit() async {
    final username = usernameController.text.trim();
    final age = ageController.text.trim();
    if (username == '') {
      usernameError = 'Придумай имя пользователя';
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
    final user = User(
      uid: widget.userdata.id,
      email: widget.userdata.email ?? '',
      username: username,
      age: int.parse(age),
      gender: gender,
      favouriteGame: choosenGame
    );
    await userRepository.addUserdata(user);
    userBloc.add(LoadUser(uid: widget.userdata.id));
    if (choosenGame != null) {
      await prefs.setString('currentGame', choosenGame!.id.toString());
    } 
    await notificationsService.setFcmToken(widget.userdata.id);
    await userRepository.setOnline(widget.userdata.id);
    if (mounted) {
      await analyticsRepository.logSignup(user, context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
        NavScreen()
      ));
    }
  }

  Future<void> chooseGame() async {
    final Game game = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseGameView()));
    choosenGame = game;
    setState(() {});
  }

  Future<void> exit() async {
    await userRepository.signout();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SigninView()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Добро пожаловать!', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
                SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Field(title: 'Придумай имя пользователя', controller: usernameController, error: usernameError),
                      Field(title: 'Укажи свой возраст', controller: ageController, type: TextInputType.number, error: ageError),
                      Text('Твой пол:', style: theme.textTheme.labelLarge),
                      DropdownButton(
                        value: gender,
                        items: [
                          DropdownMenuItem(child: Text('Мужской'), value: 'male'),
                          DropdownMenuItem(child: Text('Женский'), value: 'female')
                        ], 
                        onChanged: (value) => setState(() => gender = (value as String))
                      ),
                      Text('Любимая игра', style: theme.textTheme.labelLarge),
                      SizedBox(height: 10),
                      Consumer<HomeProvider>(
                        builder: (context, homeProvider, child) {
                          if (homeProvider.games == null) {
                            return ShimmerWidget(height: 80);
                          } else if (choosenGame == null) {
                            return ElevatedButton(onPressed: () => chooseGame(), child: Text('Выбрать любимую игру', style: theme.textTheme.labelMedium));
                          } else {
                            return GameWidget(game: choosenGame!, onTap: chooseGame);
                          }
                        }
                      )
                      
                    ]
                  )
                ]
              ),
            )
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: exit, 
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 40),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                    )
                  ),
                  ElevatedButton(
                    onPressed: submit, 
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: theme.primaryColor
                    )
                  )
                ],
              )
            )
          )
        ],
      )
    );
  }
}