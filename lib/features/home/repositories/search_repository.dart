import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/models/game.dart';

class SearchRepository {
  final supabase = GetIt.I<sb.SupabaseClient>();
  sb.RealtimeChannel? channel;
  int? currentPendingTeamID;

  Future<List<User>> getUsers() async {
    final res = await supabase.from('users').select('*, favouriteGame(*)');
    final users = res.map((user) => User.fromJSON(user)).toList();
    return users;
  }

  Future<List<Game>> getGames() async {
    final res = await supabase.from('games').select();
    final games = res.map((game) => Game.fromJSON(game)).toList();
    return games;
  }

  Future<void> startSearching(User user, SearchParams params, Function onTeamFormed) async {
    // Getting existing suitable pending teams
    final pendingTeams = await supabase
      .from('pending_teams')
      .select()
      .eq('gender', params.gender)
      .eq('size', params.teamSize)
      .eq('game', params.gameID)
      .lte('min_age', params.age)
      .gte('max_age', params.age);

    // Creating a channel to listen new teams;
    channel = supabase.channel('teams-channel');

    // If there are suitable pending teams, I add myself to the first one
    if (pendingTeams.isNotEmpty) {
      final pendingTeam = pendingTeams[0];
      // If I am the last necessery member, I create a team
      if (pendingTeam['size'] - pendingTeam['users_count'] == 1) {
        // delete pending team
        await supabase.from('pending_teams').delete().eq('id', pendingTeam['id']);
        final data = await supabase.from('pending_users').select('user(*, favouriteGame(*))').eq('pending_team', pendingTeam['id']);
        // and add my teammates
        for (Map user in data) {
          await supabase.from('members').insert({
            'member': user['uid'],
            'chat': pendingTeam['id']
          });
        }
        // and myself to the team
        await supabase.from('members').insert({
          'member': user.uid,
          'chat': pendingTeam['id']
        });

        final members = data.map((data) => User.fromJSON(data['member'])).toList();
        await supabase.from('chats').insert([
          {
            'id': pendingTeam['id'],
            'name': 'Команда',
            'is_team': true
          }
        ]);
        onTeamFormed(Team(id: pendingTeam['id'], users: members, name: 'Команда'));
        return;
      }

      // If I am not the last member, I just add myself
      await supabase.from('pending_users').insert([{
        'user': user.uid,
        'pending_team': pendingTeam['id']
      }]);

      await supabase
        .from('pending_teams')
        .update({
          'users_count': pendingTeam['users_count'] + 1
        })
        .eq('id', pendingTeam['id']);

      currentPendingTeamID = pendingTeam['id'];
      // Subscribing on creating new team
      channel!.onPostgresChanges(
        table: 'chats',
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'id', 
          value: pendingTeam['id']
        ),
        event: sb.PostgresChangeEvent.insert, 
        callback: (payload) {
          onTeamFormed(Team.fromJSON(payload.newRecord));
          supabase.removeChannel(channel!);
        }
      );
      return;
    }

    // If there isn't any suitable team, I create my one
    final teamID = DateTime.now().millisecondsSinceEpoch;
    await supabase.from('pending_teams').insert([{
      'id': teamID,
      'size': params.teamSize,
      'users_count': 1,
      'gender': params.gender,
      'game': params.gameID,
      'min_age': params.age - 2,
      'max_age': params.age + 2
    }]);

    // and add myself there
    await supabase.from('pending_users').insert([{
      'user': user.uid,
      'pending_team': teamID
    }]);

    currentPendingTeamID = teamID;
    // Listening creating a new team
    channel!.onPostgresChanges(
      table: 'chats',
      event: sb.PostgresChangeEvent.insert,
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'id', 
        value: teamID
      ),
      callback: (payload) async {
        onTeamFormed(Team.fromJSON(payload.newRecord));
        supabase.removeChannel(channel!);
      }
    );

    channel!.subscribe();
  }

  Future<void> stopSearching(User user) async {
    if (currentPendingTeamID != null) {
      supabase.removeChannel(channel!);
      final pendingTeam = (await supabase
        .from('pending_teams')
        .select()
        .eq('id', currentPendingTeamID!))[0];
      
      await supabase.from('pending_users').delete().eq('user', user.uid);
      if (pendingTeam['users_count'] == 1) {
        await supabase.from('pending_teams').delete().eq('id', pendingTeam['id']);
      } else {
        await supabase.from('pending_teams')
          .update(
            {
              'users_count': pendingTeam['users_count'] - 1
            }
          )
          .eq('id', pendingTeam['id']);

      }

    }
  }
}