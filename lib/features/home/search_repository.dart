import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/analytics/analytics.dart';
import 'package:teamup/features/home/home.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';
import 'package:teamup/services/realtime_service.dart';

class SearchRepository {
  final dio = GetIt.I<Dio>();
  final realtime = GetIt.I<RealtimeService>();
  final userBloc = GetIt.I<UserBloc>();
  final analyticsRepository = GetIt.I<AnalyticsRepository>();

  void Function()? _searchUnsub;
  String? currentSearchId;

  Function? onTeamFormed;
  Function? onTeamFound;
  Function? onNewPendingUser;
  Function? onRemovePendingUser;

  final Map<int, ImageProvider> gameCoversCache = {};
  final Map<int, ImageProvider> gameIconsCache = {};

  /// Постраничная выборка для списка пользователей.
  /// Бэкенд пагинация идёт по страницам; поиск по имени выполняется локально.
  Future<List<User>> getUsersPage({
    String? request,
    required int offset,
    int limit = 15,
  }) async {
    final int page = (offset ~/ limit) + 1;
    final res = await dio.get('/users/', queryParameters: {'page': page, 'limit': limit});
    final List<User> users = (res.data as List)
        .cast<Map>()
        .map((user) => User.fromJSON(user))
        .toList();

    if (request != null && request.isNotEmpty) {
      return users.where((user) => user.username.contains(request)).toList();
    }
    return users;
  }

  Future<List<Game>> getGames() async {
    final res = await dio.get('/games/');
    final games = (res.data as List)
        .cast<Map>()
        .map((game) => Game.fromJSON(game))
        .toList();
    games.sort((a, b) => a.id.compareTo(b.id));
    return games;
  }

  Future<ImageProvider> getGameCover(int id) async {
    final ImageProvider? coverProvider = gameCoversCache[id];
    if (coverProvider != null) return coverProvider;
    try {
      final res = await dio.get('/games/$id/url');
      final provider = NetworkImage('${res.data}');
      gameCoversCache[id] = provider;
      return provider;
    } on DioException {
      return AssetImage('assets/images/game_cover.png');
    }
  }

  Future<ImageProvider?> getGameIcon(int id) async {
    final ImageProvider? iconProvider = gameIconsCache[id];
    if (iconProvider != null) return iconProvider;
    try {
      final res = await dio.get('/games/$id/url');
      final provider = NetworkImage('${res.data}');
      gameIconsCache[id] = provider;
      return provider;
    } on DioException {
      return null;
    }
  }

  /// Восстановление активного поиска после перезапуска: бэкенд не поддерживает,
  /// поэтому всегда null.
  Future<int?> getPendingTeamID(String uid) async {
    return null;
  }

  Future<SearchParams> restoreSearching(int pendingTeamID) async {
    throw UnsupportedError('restore searching is not supported by backend');
  }

  Future<void> startSearching(User user, SearchParams params) async {
    analyticsRepository.logEvent('start_searching', properties: params.toJSON());
    final res = await dio.post('/searches/', queryParameters: {
      'game': params.gameID,
      'gender': params.gender,
      'size': params.teamSize,
      'age': params.age,
    });

    final data = (res.data) as Map<String, dynamic>;

  
    if (data['result'] == 'FORMED') {
      // Команда набрана сразу — команда уже создана на сервере.
      final teamData = data['team'] as Map<String, dynamic>;
      final chatUsers = await _getChatUsers((teamData['id'] as num).toInt());
      final team = Team.fromJSON(teamData, users: chatUsers);
      onTeamFormed!(team);
      return;
    }

    final search = (data['search'] ?? const {}) as Map<String, dynamic>;
    final String? searchId = search['id']?.toString();
    if (searchId != null) {
      currentSearchId = searchId;
      listenSearch();
    }

    final users = ((search['users']) as List?)
            ?.map((u) => User.fromJSON(u))
            .toList() ??
        <User>[];
    onTeamFound!(users);
  }

  Future<List<User>> _getChatUsers(int chatId) async {
    final res = await dio.get('/chats/$chatId/users');
    return (res.data as List).cast<Map>().map((user) => User.fromJSON(user)).toList();
  }

  void listenSearch() {
    final String? searchId = currentSearchId;
    if (searchId == null) return;

    _searchUnsub?.call();
    _searchUnsub = realtime.subscribe('/topic/searches/$searchId', (payload) {
      final String? event = payload['event']?.toString();
      final dynamic eventPayload = payload['payload'];

      switch (event) {
        case 'NEW_USER':
          onNewPendingUser!(User.fromJSON(eventPayload));
          break;
        case 'LEAVE_USER':
          onRemovePendingUser!(eventPayload);
          break;
        case 'FORMED':
          final teamData = (eventPayload) as Map<String, dynamic>;
          _handleTeamFormed(teamData);
          break;
      }
    });
  }

  Future<void> _handleTeamFormed(Map<String, dynamic> teamData) async {
    final chatUsers = await _getChatUsers((teamData['id'] as num).toInt());
    final team = Team.fromJSON(teamData, users: chatUsers);
    onTeamFormed!(team);
  }

  Future<void> stopSearching(User user) async {
    final String? searchId = currentSearchId;
    if (searchId == null) return;
    await dio.post('/searches/$searchId/leave');
    currentSearchId = null;
    _searchUnsub?.call();
    _searchUnsub = null;
  }
}