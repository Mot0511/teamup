import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/models/chat.dart';

class ChatsRepository {
  final SupabaseClient supabase = GetIt.I<SupabaseClient>();

  Future<List<Chat>> getChats(String uid) async {
    final data = await supabase
      .from('chats')
      .select('id, user1(*, favouriteGame(*)), user2(*, favouriteGame(*))')
      .or('user1.eq.$uid, user2.eq.$uid');

    final chats = data.map((row) => Chat.fromJSON(row)).toList();
    return chats;
  }

  Future<void> addChat(Chat chat) async {
    await supabase.from('chats').insert(chat.toJSON());
  }
}