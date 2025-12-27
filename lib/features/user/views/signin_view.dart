import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/signup_view.dart';
import 'package:teamup/features/user/views/user_form_view.dart';
import 'package:teamup/features/user/widgets/social_provider_widget.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teamup/widgets/outlined_field_widget.dart';

class SigninView extends StatefulWidget {
  SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final UserRepository userRepository = GetIt.I<UserRepository>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? passwordError;

  bool isShowVersion = false;
  String? version;

  void initState() {
    super.initState();

    getVersion();
  }

  Future<void> getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    setState(() {});
  }

  Future<void> onEmailSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    await userRepository.emailSignIn(email, password);

    // try {
    //   await userRepository.emailSignIn(email, password);
    // } on Exception catch (e) {
    //   print(e);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [ 
                  Text('Teamup', style: theme.textTheme.headlineLarge),
                  SizedBox(height: 20),
                  Text('Платформа для поиска\nтиммейтов в команду', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  SizedBox(height: 60),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 100), 
                      child: Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          OutlinedField(controller: emailController, error: emailError, hint: 'Почта'),
                          OutlinedField(controller: passwordController, error: passwordError, hint: 'Пароль', obscureText: true),
                          ElevatedButton(
                            onPressed: onEmailSignIn, 
                            child: Text('Войти', style: theme.textTheme.labelMedium)
                          ),
                          SizedBox(height: 5),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupView())), 
                            child: Text('Зарегистрироваться', style: theme.textTheme.labelMedium)
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )
            )
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialProviderWidget(provider: 'google', onClick: userRepository.googleSignIn),
                SizedBox(width: 20),
                SocialProviderWidget(provider: 'discord', onClick: userRepository.discordSignIn)
              ],
            )
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Author: MatveySuvorov', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                Text('tg: @Mot0511 web: https://matvey.vercel.app', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                SizedBox(height: 8),
                if (version != null)
                Text('ver. $version', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                SizedBox(height: 8),
              ],
            ),
          )
        ]
      )
    );
  }
}