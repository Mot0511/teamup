import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/app.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/firebase_options.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:window_size/window_size.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:teamup/env.dart' as env;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      setWindowTitle('Teamup');
      setWindowMinSize(const Size(540, 810));
      setWindowMaxSize(const Size(540, 810));
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Supabase.initialize(
      url: env.SUPABASE_URL,
      anonKey: env.SUPABASE_SERVICE_ROLE_KEY,
    );

    
    GetIt.I.registerSingleton(Supabase.instance.client);

    GetIt.I.registerSingleton(UserRepository());
    GetIt.I.registerSingleton(TeamsRepository());
    GetIt.I.registerSingleton(AnalyticsRepository());
    GetIt.I.registerSingleton(UserBloc(userRepository: GetIt.I<UserRepository>()));
    GetIt.I.registerSingleton(SearchRepository());
    GetIt.I.registerSingleton(ChatsRepository());
    GetIt.I.registerSingleton(VoiceService());
    GetIt.I.registerSingleton(ChatsBloc(chatsRepository: GetIt.I<ChatsRepository>())); 
    GetIt.I.registerSingleton(TeamsBloc(teamsRepository: GetIt.I<TeamsRepository>()));
    GetIt.I.registerSingleton(SearchBloc(searchRepository: GetIt.I<SearchRepository>()));
    GetIt.I.registerSingleton(await SharedPreferences.getInstance());

    final notificationsService = NotificationsService();
    // if (!kIsWeb && Platform.isAndroid) {
    //   await notificationService.init();
    // }
    GetIt.I.registerSingleton(notificationsService);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentGame', '206');
  } on Exception catch (e) {
    Fluttertoast.showToast(msg: e.toString());
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = env.SENTRY_URL;
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationsProvider>(create: (context) => NotificationsProvider()),
            ChangeNotifierProvider<HomeProvider>(create: (context) => HomeProvider()),
          ],
          child: Teamup(),
        )
      ),
    ),
  );
}
