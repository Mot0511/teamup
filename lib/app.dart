import 'package:flutter/material.dart';
import 'package:teamup/features/chats/views/views.dart';
import 'package:teamup/features/home/views/views.dart';
import 'package:teamup/features/teams/views/views.dart';
import 'package:teamup/features/users/views/views.dart';
import 'package:teamup/models/navitem.dart';
import 'package:teamup/theme.dart';
import 'package:teamup/widgtes/navbar.dart';

class Teamup extends StatefulWidget {
  const Teamup({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Column(
          children: [
            Expanded(child: navitems[currentPage].page),
            Navbar(
              items: navitems,
              currentPage: currentPage,
              onTap: (i) => setState(() => currentPage = i),
            ),
          ],
        ),
      ),
    );
  }
}
