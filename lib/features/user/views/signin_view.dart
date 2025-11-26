import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/user_form_view.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SigninView extends StatefulWidget {
  SigninView({super.key});

  @override
  State<SigninView> createState() => _SigninViewState();
}

class _SigninViewState extends State<SigninView> {
  final UserRepository usersRepository = GetIt.I<UserRepository>();

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
                ],
              )
            )
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async => await usersRepository.discordSignIn(),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(const Color(0xff5865F2))),
                  child: Text('Войти через Discord', style: theme.textTheme.labelMedium)
                ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async => await usersRepository.googleSignIn(),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0))),
                  child: Text('Войти через Google', style: theme.textTheme.labelMedium)
                ),
              ],
            )
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text('Author: MatveySuvorov', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                Text('tg: @Mot0511 web: https://matvey.vercel.app', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                SizedBox(height: 8),
                if (version != null)
                Text('ver. $version', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          )
        ]
      ),
    );
  }
}