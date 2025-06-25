import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/app.dart';
import 'package:teamup/features/chats/bloc/chats_bloc.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/providers/global_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); 
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
  
  GetIt.I.registerSingleton(Supabase.instance.client);

  GetIt.I.registerSingleton(UserRepository());
  GetIt.I.registerSingleton(SearchRepository());
  GetIt.I.registerSingleton(ChatsRepository());
  GetIt.I.registerSingleton(UserBloc(userRepository: GetIt.I<UserRepository>()));
  GetIt.I.registerSingleton(ChatsBloc(chatsRepository: GetIt.I<ChatsRepository>()));
  
  runApp(ChangeNotifierProvider<GlobalProvider>(
    create: (context) => GlobalProvider(),
    child: Teamup()
  ));
}
