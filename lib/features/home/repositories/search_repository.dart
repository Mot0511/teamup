import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/home/models/search_params.dart';
import 'package:teamup/features/home/utils/team_name_generator.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/teams/teams_repository.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/models/game.dart';

class SearchRepository {
  final supabase = GetIt.I<sb.SupabaseClient>();
  final teamsRepository = GetIt.I<TeamsRepository>();

  sb.RealtimeChannel? channel;
  int? currentPendingTeamID;

  Function? onTeamFormed;
  Function? onTeamFound;
  Function? onNewPendingUser;
  Function? onRemovePendingUser;

  Future<List<User>> getUsers(String? request) async {
    if (request != null) {
      final res = await supabase.from('users').select('*, favouriteGame(*)').like('username', '%$request%');
      final users = res.map((user) => User.fromJSON(user)).toList();
      return users;
    }

    final res = await supabase.from('users').select('*, favouriteGame(*)');
    final users = res.map((user) => User.fromJSON(user)).toList();
    return users;
    
  }


  Future<List<Game>> getGames() async {
    final res = await supabase.from('games').select();
    final games = res.map((game) => Game.fromJSON(game)).toList();
    return games;
  }

  Future<void> startSearching(
    User user, 
    SearchParams params,
  ) async {
    // Getting existing suitable pending teams
    late final List pendingTeams;
    if (params.gender == 'null') {
      pendingTeams = await supabase
        .from('pending_teams')
        .select()
        .eq('size', params.teamSize)
        .eq('game', params.gameID)
        .lte('min_age', params.age)
        .gte('max_age', params.age);
    } else {
      pendingTeams = await supabase
        .from('pending_teams')
        .select()
        .eq('gender', params.gender)
        .eq('size', params.teamSize)
        .eq('game', params.gameID)
        .lte('min_age', params.age)
        .gte('max_age', params.age);
    }

    // Creating a channel to listen new teams;
    channel = supabase.channel('teams-channel');

    // If there are suitable pending teams, I add myself to the first one
    if (pendingTeams.isNotEmpty) {
      final pendingTeam = pendingTeams[0];
      currentPendingTeamID = pendingTeam['id'];
      // If I am the last necessery member, I create a team
      if (pendingTeam['size'] - pendingTeam['users_count'] == 1) {
        final teamName = TeamNameGenerator.createTeamName();
        await supabase.from('chats').insert([
          {
            'id': pendingTeam['id'],
            'name': teamName,
            'is_team': true
          }
        ]);
        // delete pending team
        final data = await supabase.from('pending_users').select('user(*, favouriteGame(*))').eq('pending_team', pendingTeam['id']);
        // and add my teammates
        for (Map user in data) {
          await supabase.from('members').insert({
            'member': user['user']['uid'],
            'chat': pendingTeam['id']
          });
        }
        // and myself to the team
        await supabase.from('members').insert({
          'member': user.uid,
          'chat': pendingTeam['id']
        });
        final members = data.map((data) => User.fromJSON(data['user'])).toList();
        members.add(user);
        await supabase.from('pending_teams').delete().eq('id', pendingTeam['id']);
        onTeamFormed!(Team(id: pendingTeam['id'], users: members, name: teamName));
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

      // Subscribing on creating new team
      listenTeams(pendingTeam['id']);

      final pending_users = await supabase.from('pending_users').select('user(*, favouriteGame(*))').eq('pending_team', pendingTeam['id']);
      onTeamFound!(pending_users.map((user) => User.fromJSON(user['user'])).toList());
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
    listenTeams(teamID);
    onTeamFound!([user]);
  }

  void listenTeams(int teamID) {
    channel!.onPostgresChanges(
      table: 'pending_teams',
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'id', 
        value: teamID
      ),
      event: sb.PostgresChangeEvent.delete, 
      callback: (payload) async {
        final Team team = await teamsRepository.getTeam(payload.oldRecord['id']);
        onTeamFormed!(team);
        supabase.removeChannel(channel!);
        currentPendingTeamID = null;
      }
    );

    channel!.onPostgresChanges(
      table: 'pending_users',
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'team',
        value: teamID
      ),
      event: sb.PostgresChangeEvent.insert, 
      callback: (payload) async {
        final Map userdata = (await supabase.from('users').select('*, favouriteGame(*)').eq('uid', payload.newRecord['user']))[0];
        onNewPendingUser!(User.fromJSON(userdata));
      }
    );

    channel!.onPostgresChanges(
      table: 'pending_users',
      filter: sb.PostgresChangeFilter(
        type: sb.PostgresChangeFilterType.eq,
        column: 'team',
        value: teamID
      ),
      event: sb.PostgresChangeEvent.delete,
      callback: (payload) async {
        final users = await supabase.from('pending_users').select('user(*, favouriteGame(*))').eq('pending_team', teamID);
        onTeamFound!(users.map((user) => User.fromJSON(user['user'])).toList());
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