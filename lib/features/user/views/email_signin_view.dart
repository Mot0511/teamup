import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/widgets/field_widget.dart';

class EmailSigninView extends StatefulWidget {
  const EmailSigninView({super.key});

  @override
  State<EmailSigninView> createState() => _EmailSigninViewState();
}

class _EmailSigninViewState extends State<EmailSigninView> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  final userRepository = GetIt.I<UserRepository>();

  final String emailError = '';
  final String passwordError = '';

  Future<void> submit() async {
    if (passwordController.text.trim() != repeatPasswordController.text.trim()) return;
    await userRepository.emailSignIn(emailController.text.trim(), passwordController.text.trim());
    
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
                Text('Вход по Email', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
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
                      Field(title: 'Почта', controller: emailController, error: emailError),
                      Field(title: 'Пароль', controller: passwordController, type: TextInputType.number, error: ''),
                      Field(title: 'Подтвердите пароль', controller: repeatPasswordController, type: TextInputType.number, error: passwordError),
                    ]
                  )
                ]
              ),
            )
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: ElevatedButton(
                onPressed: submit, 
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  backgroundColor: theme.primaryColor
                )
              )
            )
          )
        ],
      )
    );
  }
}