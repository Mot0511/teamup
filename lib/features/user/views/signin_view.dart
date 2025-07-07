import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/user/views/user_form_view.dart';
import 'package:teamup/nav_screen.dart';
import 'package:teamup/providers/global_provider.dart';

class SigninView extends StatelessWidget {
  SigninView({super.key});

  final UserRepository usersRepository = GetIt.I<UserRepository>();

  Future<void> googleSignInHandler(BuildContext context) async {
    final AuthResult? res = await usersRepository.googleSignIn(context);
    
    if (res == null) return;
    if (context.mounted) {
      if (res.isNew) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
          UserFormView(userdata: res.userdata)
        ));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => 
          NavScreen()
        ));
      }
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
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Teamup', style: theme.textTheme.headlineLarge),
                  SizedBox(height: 20),
                  Text('Платформа для поиска \nтиммейтов в команду', textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                ],
              )
            )
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // ElevatedButton(
                //   onPressed: () => signinViaProviderHandler(OAuthProvider.yandex, context),
                //   style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 187, 53, 0))),
                //   child: Text('Войти через Яндекс', style: theme.textTheme.labelMedium)
                // ),
                SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async => await googleSignInHandler(context),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0))),
                  child: Text('Войти через Google', style: theme.textTheme.labelMedium)
                ),
              ],
            )
          )
        ]
      ),
    );
  }
}