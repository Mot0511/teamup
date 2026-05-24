import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/widgets/widgets.dart';

class ResetPasswordView extends StatefulWidget {
  ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final supabase = GetIt.I<SupabaseClient>();

  final emailController = TextEditingController(text: "Mat0511@yandex.ru");

  String? emailError;

  Future<void> resetPassword() async {
    await supabase.auth.resetPasswordForEmail(
      emailController.text.trim(),
      redirectTo: 'http://localhost:3000/reset-password'
    );
    try {
      
    } on AuthApiException catch (e) {
      emailError = 'Ошибка: ${e.message}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Сброс пароля')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Напиши свою почту, а мы пришлем ссылку на восстановление пароля.', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            SizedBox(height: 20),
            OutlinedField(controller: emailController, error: emailError, hint: 'Почта'),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: resetPassword,
                child: Text('Сбросить пароль', style: theme.textTheme.titleMedium),
              )
            )
          ]
        ),
      )
    );
  }
}