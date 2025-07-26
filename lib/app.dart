import 'package:flutter/material.dart';
import 'package:teamup/loading.dart';
import 'package:teamup/theme.dart';

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
