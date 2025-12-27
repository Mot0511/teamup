import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/email_confirmation_view.dart';
import 'package:teamup/features/user/views/user_form_view.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/widgets/outlined_field_widget.dart';
import 'package:teamup/widgets/widgets.dart';

class SignupView extends StatefulWidget {
  SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatedPasswordController = TextEditingController();

  final userRepository = GetIt.I<UserRepository>();

  String? error;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final repeatedPasssword = repeatedPasswordController.text.trim();
    if (email == '') {
      error = 'Нужно указать свою электронную почту';
      setState(() {});
      return;
    }
    if (await userRepository.isEmailExists(email)) {
      error = 'Пользователь с такой почтой уже есть';
      setState(() {});
      return;
    }
    if (password == '') {
      error = 'Нужно придумать пароль';
      setState(() {});
      return;
    }
    if (password.length < 6) {
      error = 'Пароль должен быть длиной хотя бы 6 символов';
      setState(() {});
      return;
    }
    if (password != repeatedPasssword) {
      error = 'Пароли не совпадают.';
      setState(() {});
      return;
    }

    try {
      await userRepository.emailSignUp(email, password);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => EmailConfirmationView()));
    } on sb.AuthApiException catch (e) {
      switch (e.code) {
        case 'validation_failed':
          error = 'Ты ввел некорректный адрес электронной почты';
          setState(() {});
          return;
        case 'over_email_send_rate_limit':
          error = 'Слишком много запросов, попробуй чуть позже';
          setState(() {});
          return;
      }
      print(e.message);
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
                Text('Регистрация', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
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
                      Field(controller: emailController, title: 'Почта'),
                      Field(controller: passwordController, title: 'Пароль', obscureText: true),
                      Field(controller: repeatedPasswordController, error: error, title: 'Повторите пароль', obscureText: true),
                    ]
                  )
                ]
              ),
            )
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 40),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                    )
                  ),
                  ElevatedButton(
                    onPressed: submit, 
                    child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40),
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(20),
                      backgroundColor: theme.primaryColor
                    )
                  )
                ],
              )
            )
          )
        ],
      )
    );
  }
}