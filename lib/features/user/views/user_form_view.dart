import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';
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

  Future<void> submit() async {
    final user = User(
      uid: widget.userdata.id,
      email: widget.userdata.email ?? '',
      username: usernameController.text,
      age: int.parse(ageController.text),
      gender: gender,
    );
    await userRepository.addUserdata(user);
    userBloc.add(LoadUser(uid: widget.userdata.id));
    notificationsService.init(widget.userdata.id);
    userRepository.setOnline(widget.userdata.id);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
        NavScreen()
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
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
                      Field(title: 'Придумай никнейм', controller: usernameController),
                      Field(title: 'Укажи свой возраст', controller: ageController, type: TextInputType.number),
                      Text('Твой пол:', style: theme.textTheme.labelLarge),
                      DropdownButton(
                        value: gender,
                        items: [
                          DropdownMenuItem(child: Text('Мужской'), value: 'male'),
                          DropdownMenuItem(child: Text('Женский'), value: 'female')
                        ], 
                        onChanged: (value) => setState(() => gender = (value as String))
                      ),
                    ]
                  )
                ]
              ),
            )
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: ElevatedButton(
                onPressed: submit, 
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  backgroundColor: theme.primaryColor
                )
              )
            )
          )
        ],
      )
    );
  }
}