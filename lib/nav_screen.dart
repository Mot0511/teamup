import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/views/chats_view.dart';
import 'package:teamup/features/home/views/home_view.dart';
import 'package:teamup/features/teams/views/teams_view.dart';
import 'package:teamup/features/user/views/profile_view.dart';
import 'package:teamup/features/user/views/views.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/models/navitem.dart';
import 'package:teamup/widgets/navbar_widget.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {

  int currentView = 0;
  List<Navitem> navitems = [
    Navitem(title: 'Главная', icon: Icons.home, page: HomeView()),
    Navitem(title: 'Команды', icon: Icons.people, page: TeamsView()),
    Navitem(title: 'Личные чаты', icon: Icons.chat_sharp, page: ChatsView()),
    Navitem(title: 'Профиль', icon: Icons.man, page: ProfileView()),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: navitems[currentView].page
          ),
          Navbar(items: navitems, currentView: currentView, onTap: (i) => setState(() => currentView = i))
        ],
      )
    );
  }
}