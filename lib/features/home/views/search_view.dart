import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/repositories/search_repository.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/widgets/user_widget.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class AllUsersView extends StatefulWidget {
  const AllUsersView({super.key});

  @override
  State<AllUsersView> createState() => _AllUsersViewState();
}

class _AllUsersViewState extends State<AllUsersView> {

  List<User>? users;
  final searchRepository = GetIt.I<SearchRepository>();

  Future<void> getUsers([String? request]) async {
    users = await searchRepository.getUsers(request);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Все пользователи')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Поиск',
                hintStyle: theme.textTheme.labelMedium?.copyWith(color: Colors.grey),
                border: UnderlineInputBorder(),
              ),
              style: theme.textTheme.labelMedium,
              maxLines: 1,
              onChanged: getUsers,
            ),
            SizedBox(height: 20),
            Expanded(
              child: users != null
                ? ListView(
                  children: users!.map((user) => UserWidget(user: user)).toList()
                )
                : ListView.builder(
                    itemCount: 3 + Random().nextInt(5),
                    itemBuilder: (context, state) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SihmmerWidget(),
                      )
                  )
            )
          ],
        ),
      )
    );
  }
}