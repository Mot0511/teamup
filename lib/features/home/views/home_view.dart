import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/home/views/all_users_view.dart';
import 'package:teamup/features/home/widgets/drop_down_widget.dart';
import 'package:teamup/features/home/widgets/widgets.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/user_repository.dart';


class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>{

  final userBloc = GetIt.I<UserBloc>();
  final supabase = GetIt.I<SupabaseClient>();

  Future<void> loadUser() async {
    if (userBloc.state is UserStateInitial) {
      try {
        final user = (await supabase.auth.getUser()).user;
        if (user == null) return;
        userBloc.add(LoadUser(uid: user.id));
      } on AuthSessionMissingException catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Teamup', style: theme.textTheme.headlineMedium), 
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllUsersView())), 
            icon: Icon(Icons.people_alt)
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: SearchBtn(),
            )
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Text("Фильтры поиска", style: theme.textTheme.headlineMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Игра",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                DropdowmWidget(
                  items: [
                    DropdownItem(text: "Minecraft", value: "Minecraft"),
                    DropdownItem(text: "Rust", value: "Rust"),
                  ],
                  hint: "Выберите игру",
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Кол-во игроков в команде",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                DropdowmWidget(
                  items: [
                    DropdownItem(text: "2", value: "2"),
                    DropdownItem(text: "3", value: "3"),
                  ],
                  hint: "2-3?",
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "Пол",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                DropdowmWidget(
                  items: [
                    DropdownItem(text: "Мужской", value: "male"),
                    DropdownItem(text: "Женский", value: "female"),
                  ],
                  hint: "Выберите пол",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
