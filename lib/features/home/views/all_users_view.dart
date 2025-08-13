import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';

class AllUsersView extends StatefulWidget {
  const AllUsersView({super.key});

  @override
  State<AllUsersView> createState() => _AllUsersViewState();
}

class _AllUsersViewState extends State<AllUsersView> {

  List<User>? users;
  final searchRepository = GetIt.I<SearchRepository>();


  Future<void> getUsers() async {
    users = await searchRepository.getUsers();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Все пользователи')),
      body: users != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              children: users!.map((user) => UserWidget(user: user)).toList()
            ),
          )
        : Center(child: CircularProgressIndicator())
    );
  }
}