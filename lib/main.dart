import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/app.dart';
import 'package:teamup/features/chats/chats.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/interceptors/auth_interceptor.dart';
import 'package:teamup/features/user/providers/auth_provider.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/firebase_options.dart';
import 'package:teamup/providers/notifications_provider.dart';
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/services/notifications_service.dart';
import 'package:teamup/features/user/services/discord_auth_service.dart';
import 'package:teamup/features/user/services/google_auth_service.dart';
import 'package:teamup/services/realtime_service.dart';
import 'package:teamup/utils/register_app_links.dart';
import 'package:window_size/window_size.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:teamup/env.dart' as env;
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    tz_data.initializeTimeZones();
    
    await dotenv.load();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      setWindowTitle('Teamup');
      setWindowMinSize(const Size(440, 810));
      setWindowMaxSize(const Size(440, 810));
    }
    if (Platform.isWindows) {
      await registerAppLinks('teamup');
    }

    if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await Supabase.initialize(
      url: env.SUPABASE_URL,
      anonKey: env.SUPABASE_ANON_KEY,
    );
    
    final dio = Dio(
      BaseOptions(baseUrl: 'https://api.teamupp.ru')
    );
    GetIt.I.registerSingleton(FlutterSecureStorage());
    dio.interceptors.add(AuthInterceptor());
    
    GetIt.I.registerSingleton(dio);
    GetIt.I.registerLazySingleton(() => GoogleAuthService());
    GetIt.I.registerLazySingleton(() => DiscordAuthService());
    GetIt.I.registerLazySingleton<RealtimeService>(
      () => RealtimeService(
        url: 'https://api.teamupp.ru',
        getAccessToken: () async =>
            await GetIt.I<FlutterSecureStorage>().read(key: 'access_token'),
      ),
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
    GetIt.I.registerSingleton(GlobalKey<NavigatorState>());
    GetIt.I.registerSingleton(GlobalKey<ScaffoldMessengerState>());
    GetIt.I.registerSingleton(await SharedPreferences.getInstance());
    final notificationsService = NotificationsService();
    GetIt.I.registerSingleton(notificationsService);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentGame', '206');
  } on Exception catch (e) {
    Fluttertoast.showToast(msg: e.toString());
  }
  await SentryFlutter.init(
    (options) {
      options.dsn = env.SENTRY_URL;
      options.sendDefaultPii = true;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationsProvider>(
              create: (context) => NotificationsProvider()..setContext(context),
            ),
            ChangeNotifierProvider<HomeProvider>(create: (context) => HomeProvider()),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) {
                final provider = AuthProvider();
                provider.init();
                return provider;
              },
            )
          ],
          child: Teamup()
        )
      ),
    ),
  );
}