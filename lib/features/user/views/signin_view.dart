import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/user/providers/auth_provider.dart';
import 'package:teamup/features/user/user.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teamup/features/user/views/reset_password_view.dart';
import 'package:teamup/widgets/outlined_field_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class SigninView extends StatefulWidget {
  SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final emailController = TextEditingController(text: "Mat0511@yandex.ru");
  final passwordController = TextEditingController(text: "motik0511");

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

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.login(email, password);
    } on AuthException catch (e) {
      setState(() => passwordError = e.message);
    }
  }

  Future<void> onGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.googleLogin();
  }

  bool discordLoading = false;

  Future<void> onDiscordSignIn() async {
    if (discordLoading) return;
    setState(() => discordLoading = true);

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.discordLogin();
    } catch (e) {
      debugPrint('Discord login failed: $e');
    } finally {
      if (mounted) setState(() => discordLoading = false);
    }
  }

  void onForgotPassword() {
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResetPasswordView()));
    }
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Column(
                        children: [
                          OutlinedField(controller: emailController, error: emailError, hint: 'Почта'),
                          OutlinedField(controller: passwordController, error: passwordError, hint: 'Пароль', obscureText: true),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onEmailSignIn, 
                              child: Text('Войти', style: theme.textTheme.labelMedium)
                            )
                          ),
                          SizedBox(height: 5),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupView())), 
                            child: Text('Зарегистрироваться', style: theme.textTheme.labelMedium)
                          ),
                          TextButton(
                            onPressed: onForgotPassword,
                            child: Text('Забыли пароль?', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                          )
                        ],
                      ),
                    )
                  ),
                ],
              )
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialProviderWidget(provider: 'google', onClick: onGoogleSignIn),
                SizedBox(width: 20),
                SocialProviderWidget(provider: 'discord', onClick: onDiscordSignIn)
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