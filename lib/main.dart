import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/app.dart';
import 'package:teamup/features/chats/bloc/chats_bloc.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/home/bloc/search_bloc.dart';
import 'package:teamup/features/home/home_provider.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/teams/bloc/teams_bloc.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/teams/signaling_service.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/firebase_options.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_size/window_size.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Teamup');
    setWindowMinSize(const Size(540, 810));
    setWindowMaxSize(const Size(540, 810));
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_SERVICE_ROLE_KEY'),
  );
  
  GetIt.I.registerSingleton(Supabase.instance.client);

  GetIt.I.registerSingleton(UserRepository());
  GetIt.I.registerSingleton(TeamsRepository());
  GetIt.I.registerSingleton(SearchRepository());
  GetIt.I.registerSingleton(ChatsRepository());
  GetIt.I.registerSingleton(UserBloc(userRepository: GetIt.I<UserRepository>()));
  GetIt.I.registerSingleton(ChatsBloc(chatsRepository: GetIt.I<ChatsRepository>()));
  GetIt.I.registerSingleton(TeamsBloc(teamsRepository: GetIt.I<TeamsRepository>()));
  GetIt.I.registerSingleton(SearchBloc(searchRepository: GetIt.I<SearchRepository>()));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GlobalProvider>(create: (context) => GlobalProvider()),
        ChangeNotifierProvider<HomeProvider>(create: (context) => HomeProvider())
      ],
      child: Teamup(),
    )
  );
}
