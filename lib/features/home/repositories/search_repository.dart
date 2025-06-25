import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/models/game.dart';

class SearchRepository {
  final supabase = GetIt.I<sb.SupabaseClient>();

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
}