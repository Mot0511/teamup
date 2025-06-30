import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart' as models;

class TeamsRepository {
  final supabase = GetIt.I<SupabaseClient>();

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
    await supabase.from('members').delete().eq('chat', team.id).eq('member', uid);
    if (team.users.length == 1) {
      await supabase.from('chats').delete().eq('id', team.id);
    }
  }

  Future<ImageProvider> getIcon(int id) async {
    final storage = supabase.storage.from('main');
    if (await storage.exists('team_icons/$id.png')){
      final imageUrl = supabase.storage.from('main').getPublicUrl('team_icons/$id.png');
      return NetworkImage(imageUrl);
    }
    return AssetImage('assets/default_team_icon.png');

  }

  Future<void> uploadAvatar(File file, int id) async {
    await supabase.storage.from('main').upload(
      'team_icons/$id.png', 
      file, 
      fileOptions: FileOptions(upsert: true)
    );
  }
}