import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/teams/teams.dart';
import 'package:teamup/features/user/user.dart';
import 'package:teamup/models/game.dart';

enum CapabilityToJoin {capable, notCapable, expiredInvite}

class TeamsRepository {
  final dio = GetIt.I<Dio>();

  final Map<int, ImageProvider> iconProviders = {};

  Future<List<Team>> getTeams([String? uid]) async {

    late dynamic res;
    if (uid != null) {
      res = await dio.get('/teams/');
    } else {
      res = await dio.get('/teams/public');
    }

    final data = (res.data as List).cast<Map>().toList();

    final List<Team> teams = [];
    final List<int> added = [];
    for (Map row in data) {
      final dynamic teamId = row['id'];
      if (teamId == null) continue;
      if (row['team'] != true) continue;
      final int id = (teamId as num).toInt();
      if (added.contains(id)) continue;

      final users = await getTeamUsers(id);
      teams.add(Team(
        id: id,
        users: users,
        name: '${row['name'] ?? ''}',
        isPublic: row['public'] ?? false,
        game: row['game'] != null ? Game.fromJSON(row['game']) : null,
      ));
      added.add(id);
    }
    return teams;
  }

  Future<Team> getTeam(int id) async {
    final res = await dio.get('/chats/$id');
    final users = await getTeamUsers(id);
    return Team(
      id: id,
      users: users,
      name: res.data['name'] ?? '',
      isPublic: res.data['public'] ?? false,
      game: res.data['game'] != null ? Game.fromId(int.parse('${res.data['game']}')) : null,
    );
  }

  Future<List<User>> getTeamUsers(int id) async {
    final res = await dio.get('/chats/$id/users');
    return (res.data as List)
    .cast<Map>()
    .map((user) => User.fromJSON(user)).toList();
  }

  Future<Team> addTeam(Team team) async {
    final res = await dio.post("/teams/", data: {
      'name': team.name,
      'gameId': team.game?.id,
      'isPublic': team.isPublic
    });
    return Team.fromJSON(res.data);
  }

  Future<void> editTeam(Team team, List<User> addedMembers, List<User> removedMembers) async {
    await dio.put("/teams/", data: {
      'teamId': team.id,
      'newName': team.name,
      'addedMembers': addedMembers,
      'removedMembers': removedMembers
    });
  }

  Future<void> removeTeam(int chatID) async {
    await dio.delete('/teams/$chatID');
  }

  Future<String> getInviteLink(int teamID) async {
    final res = await dio.get('/$teamID/invitation');
    return res.data;
  }

  Future<Team> acceptInvitation(int teamID, int number) async {
    final res = await dio.post('/$teamID/invitation/$number/accept');
    return Team.fromJSON(res.data);
  }

  Future<void> join(int teamID) async {
    return;
  }

  Future<ImageProvider> getIcon(int id) async {
    final ImageProvider? iconProvider = iconProviders[id];
    if (iconProvider != null) {
      return iconProvider;
    }
    final provider = AssetImage('assets/images/default_team_icon.png');
    iconProviders[id] = provider;
    return provider;
  }

  Future<void> uploadIcon(int id, Uint8List file) async {
    iconProviders[id] = MemoryImage(file);
  }

  void updateIconCache(int id, ImageProvider provider) async {
    iconProviders[id] = provider;
  }
}