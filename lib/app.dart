import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/views/views.dart';
import 'package:teamup/features/home/views/views.dart';
import 'package:teamup/features/teams/views/views.dart';
import 'package:teamup/features/user/views/signin_view.dart';
import 'package:teamup/features/user/views/views.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/models/navitem.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:teamup/theme.dart';
import 'package:teamup/widgets/navbar_widget.dart';

class Teamup extends StatefulWidget {
  Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> {

  int currentPage = 0;
  List<Navitem> navitems = [
    Navitem(title: 'Главная', icon: Icons.home, page: HomeView()),
    Navitem(title: 'Команды', icon: Icons.people, page: TeamsView()),
    Navitem(title: 'Личные чаты', icon: Icons.chat_sharp, page: ChatsView()),
    Navitem(title: 'Профиль', icon: Icons.man, page: ProfileView()),
  ];

  final SupabaseClient supabase = GetIt.I<SupabaseClient>();

  Future<void> checkAccount(GlobalProvider globalProvider) async {
    try {
      await supabase.auth.getUser();
      globalProvider.setIsLogined = true;
    } on AuthSessionMissingException catch (e) {
      globalProvider.setIsLogined = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalProvider = Provider.of<GlobalProvider>(context);
    checkAccount(globalProvider);
    return MaterialApp( 
      theme: theme,
      home: globalProvider.isLogined != null
        ? globalProvider.isLogined == true
          ? Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: navitems[currentPage].page
                ),
                Navbar(items: navitems, currentPage: currentPage, onTap: (i) => setState(() => currentPage = i))
              ],
            )
          )
          : SigninView()
        : Loading()
    );
  }
}