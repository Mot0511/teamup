import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/widgets/shimmer_widget.dart';

class AllUsersView extends StatefulWidget {
  const AllUsersView({super.key});

  @override
  State<AllUsersView> createState() => _AllUsersViewState();
}

class _AllUsersViewState extends State<AllUsersView> {
  static const int _pageSize = 20;

  List<User>? users;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _listGeneration = 0;
  String _searchText = '';

  final searchRepository = GetIt.I<SearchRepository>();
  final ScrollController _scrollController = ScrollController();

  Future<void> _loadUsers({String? request, bool append = false}) async {
    if (append) {
      if (_isLoadingMore || !_hasMore || users == null) return;
      final gen = _listGeneration;
      final offset = users!.length;
      _isLoadingMore = true;
      setState(() {});

      try {
        final next = await searchRepository.getUsersPage(
          request: _searchText.isEmpty ? null : _searchText,
          offset: offset,
          limit: _pageSize,
        );
        if (!mounted || gen != _listGeneration) return;
        if (next.isEmpty) {
          _hasMore = false;
        } else {
          users!.addAll(next);
          if (next.length < _pageSize) _hasMore = false;
        }
      } finally {
        _isLoadingMore = false;
        if (mounted) setState(() {});
      }
      return;
    }

    _listGeneration++;
    final gen = _listGeneration;
    final q = request ?? '';
    _searchText = q;

    setState(() {
      users = null;
      _hasMore = true;
    });

    final first = await searchRepository.getUsersPage(
      request: q.isEmpty ? null : q,
      offset: 0,
      limit: _pageSize,
    );
    if (!mounted || gen != _listGeneration) return;

    setState(() {
      users = first;
      _hasMore = first.length >= _pageSize;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore || users == null) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadUsers(append: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers(request: '');
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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
              onChanged: (value) => _loadUsers(request: value),
            ),
            SizedBox(height: 20),
            Expanded(
              child: users != null
                ? ListView.builder(
                    controller: _scrollController,
                    itemCount: users!.length + (_isLoadingMore && _hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == users!.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return UserWidget(user: users![index]);
                    },
                  )
                : ListView.builder(
                    itemCount: 3 + Random().nextInt(5),
                    itemBuilder: (context, state) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: ShimmerWidget(),
                      )
                  )
            )
          ],
        ),
      )
    );
  }
}