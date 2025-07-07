import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/user/models/user.dart' as models;

class ChatsRepository {
  final SupabaseClient supabase = GetIt.I<SupabaseClient>();

  Future<List<Chat>> getChats(String uid) async {
    final data = await supabase
      .from('members')
      .select('chat(*)')
      .eq('member', uid)
      .eq('chat.is_team', false);

      
    final List<Chat> chats = [];
    for (Map row in data) {
      final chat = row['chat'];
      if (chat == null) continue;
      final members = await supabase.from('members').select('member(*, favouriteGame(*))').eq('chat', chat['id']);
      chats.add(Chat(
        id: chat['id'],
        users: members.map((member) => models.User.fromJSON(member['member'])).toList(),
      ));
    }
    return chats;
  }

  Future<void> addChat(Chat chat) async {
    await supabase.from('chats').insert(chat.toJSON());
    for (models.User user in chat.users) {
      await supabase.from('members').insert({
        'chat': chat.id,
        'member': user.uid
      });
    }
  }

  Future<void> removeChat(Chat chat) async {
    await supabase.from('chats').delete().eq('id', chat.id);
    await supabase.from('members').delete().eq('chat', chat.id);
  }
}