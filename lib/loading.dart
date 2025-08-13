import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/user/views/signin_view.dart';
import 'package:teamup/nav_screen.dart';

class Loading extends StatefulWidget {
  Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Text('Teamup', style: Theme.of(context).textTheme.headlineLarge)
            )
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 7)
              )
            )
          )
        ],
      )
    );
  }
}