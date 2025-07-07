import 'dart:async';

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
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:teamup/theme.dart';
import 'package:teamup/widgets/navbar_widget.dart';

enum LoginState {notLogined, noUserdata, logined}

class Teamup extends StatefulWidget {
  const Teamup({super.key});

  @override
  State<Teamup> createState() => _TeamupState();
}

class _TeamupState extends State<Teamup> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      theme: theme,
      home: Loading()
    );
  }
}
