import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/navitem.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:teamup/widgets/navbar_widget.dart';
import 'package:teamup/widgets/web_navbar_widget.dart';

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

  void insertOverlay(context) {
    final provider = Provider.of<NotificationsProvider>(context);
    if (provider.isNotificationVisible) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    insertOverlay(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: kIsWeb
        ? Row(
          children: [
            WebNavbar(items: navitems, currentView: currentView, onTap: (i) => setState(() => currentView = i)),
            Expanded(
              child: navitems[currentView].page
            )
          ],
        )
        : Scaffold(
            body: Column(
            children: [
              Expanded(
                child: navitems[currentView].page,
              ),
              Navbar(items: navitems, currentView: currentView, onTap: (i) => setState(() => currentView = i))
            ],
          ),
        )
    );
  }
}