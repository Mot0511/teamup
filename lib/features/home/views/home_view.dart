import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/home/views/all_users_view.dart';
import 'package:teamup/features/home/widgets/widgets.dart';
import 'package:teamup/features/user/bloc/user_bloc.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/user_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>{

  final userBloc = GetIt.I<UserBloc>();
  final supabase = GetIt.I<SupabaseClient>();

  Future<void> loadUser() async {
    final user = (await supabase.auth.getUser()).user;
    if (user == null) return;
    userBloc.add(LoadUser(uid: user.id));
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Teamup', style: theme.textTheme.headlineMedium), 
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllUsersView())), 
            icon: Icon(Icons.people_alt)
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: SearchBtn(),
            )
          ),
          Expanded(
            flex: 4,
            child: SizedBox.shrink()
          )
        ],
      ),
    );
  }
}