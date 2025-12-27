import 'package:flutter/material.dart';
import 'package:teamup/features/user/views/views.dart';

class EmailConfirmationView extends StatelessWidget {
  const EmailConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Подтверждение аккаунта', style: theme.textTheme.titleLarge),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 100),
            child: Text('Перейди по ссылке из письма, чтобы подтвердить аккаунт.', textAlign: TextAlign.center),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SigninView())), 
            child: Text('Вернуться на страницу входа', style: theme.textTheme.titleMedium)
          )
        ],
      )
    );
  }
}