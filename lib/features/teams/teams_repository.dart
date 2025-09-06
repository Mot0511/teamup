import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart' as models;

class TeamsRepository {
  final supabase = GetIt.I<SupabaseClient>();

  final Map<int, ImageProvider> iconProviders = {};

  Future<List<Team>> getTeams(String uid) async {
    final data = await supabase
      .from('members')
      .select('chat(*)')
      .eq('member', uid)
      .eq('chat.is_team', true);

      
    final List<Team> teams = [];
    for (Map row in data) {
      final team = row['chat'];
      if (team == null) continue;
      final members = await supabase.from('members').select('member(*, favouriteGame(*))').eq('chat', team['id']);
      teams.add(Team(
        id: team['id'],
        users: members.map((member) => models.User.fromJSON(member['member'])).toList(),
        name: team['name']
      ));
    }
    return teams;
  }

  Future<Team> getTeam(int id) async {
    final teams_data = (await supabase.from('chats').select().eq('id', id))[0];
    final members =  await supabase.from('members').select('member(*, favouriteGame(*))').eq('chat', id);
    return Team(
      id: id,
      users: members.map((member) => models.User.fromJSON(member['member'])).toList(),
      name: teams_data['name']
    );
  }

  Future<void> addTeam(Team team) async {
    await supabase.from('chats').insert(team.toJSON());
    for (models.User user in team.users) {
      await supabase.from('members').insert({
        'chat': team.id,
        'member': user.uid
      });
    }
  }

  Future<void> editTeam(Team team, List<models.User> addedMembers, List<models.User> removedMembers) async {
    await supabase.from('chats').update(team.toJSON()).eq('id', team.id);
    await supabase.from('members').insert(addedMembers.map((member) => {
      'member': member.uid,
      'chat': team.id
    }).toList());
    for (models.User user in removedMembers) {
      await supabase.from('members').delete().eq('chat', team.id).eq('member', user.uid);
    }
  }

  Future<void> removeTeam(Team team, String uid) async {
    await supabase.from('members').delete().eq('member', uid).eq('chat', team.id);
    if (team.users.length == 1) {
      await supabase.from('chats').delete().eq('id', team.id);
    }
    await supabase.from('messages').delete().eq('chat', team.id);
  }

  Future<ImageProvider> getIcon(int id) async {
    final ImageProvider? iconProvider = iconProviders[id];
    if (iconProvider != null) {
      return iconProvider;
    }
    final storage = supabase.storage.from('main');
    if (await storage.exists('team_icons/$id.png')){
      final imageUrl = supabase.storage.from('main').getPublicUrl('team_icons/$id.png');
      final provider = NetworkImage(imageUrl);
      iconProviders[id] = provider;
      return provider;
    }
    final provider = AssetImage('assets/images/default_team_icon.png');
    iconProviders[id] = provider;
    return provider;

  }

  Future<void> uploadIcon(int id, File file) async {
    iconProviders[id] = FileImage(file);
    await supabase.storage.from('main').upload(
      'team_icons/$id.png', 
      file, 
      fileOptions: FileOptions(upsert: true)
    );
  }

  void updateIconCache(int id, ImageProvider provider) async {
    iconProviders[id] = provider;
  }
}