import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/app.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/providers/global_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://flvcuqostwctdicmncrb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsdmN1cW9zdHdjdGRpY21uY3JiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1NzY3NjYsImV4cCI6MjA2NjE1Mjc2Nn0.zxofJ6gvsd1nQCn9eSe3lDnk9C_h12_8OZnf7FXF41s',
  );
  
  GetIt.I.registerSingleton(Supabase.instance.client);

  GetIt.I.registerSingleton(UserRepository());
  GetIt.I.registerSingleton(SearchRepository());
  GetIt.I.registerSingleton(UserBloc(userRepository: GetIt.I<UserRepository>()));
  
  runApp(ChangeNotifierProvider<GlobalProvider>(
    create: (context) => GlobalProvider(),
    child: Teamup()
  ));
}
