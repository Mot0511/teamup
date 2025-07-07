import 'dart:async';

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
  
  final SupabaseClient supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NavScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SigninView()));
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

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