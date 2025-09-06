import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamup/features/chats/models/chat.dart';
import 'package:teamup/features/chats/models/message.dart';
import 'package:teamup/features/user/models/user.dart' as models;

class ChatsRepository {
  final SupabaseClient supabase = GetIt.I<SupabaseClient>();
  final Map<int, ImageProvider> attachmentProviders = {};

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

  Future<Chat> getChat(int id) async {
    final members = await supabase.from('members').select('member(*, favouriteGame(*))').eq('chat', id);
    return Chat(
      id: id,
      users: members.map((member) => models.User.fromJSON(member['member'])).toList(),
    );
  }

  Future<void> removeChat(Chat chat) async {
    await supabase.from('chats').delete().eq('id', chat.id);
    await supabase.from('members').delete().eq('chat', chat.id);
    await supabase.from('messages').delete().eq('chat', chat.id);
  }

  Future<List<Message>> getMessages(int chatID) async {
    final data = await supabase.from('messages').select('*, sender(*, favouriteGame(*))').eq('chat', chatID);
    final List<Message> messages = [];
    for (Map message in data) {
      if (message['attachment'] != null) {
        message['attachment'] = await getAttachment(message['attachment']);
      }
      messages.add(Message.fromJSON(message));
    }
    return messages;
  }

  Future<void> sendMessage(Message message, File? attachment) async {
    if (attachment != null) {
      await supabase.storage.from('main').upload('attachments/${message.id}.png', attachment);
    }
    await supabase.from('messages').insert(message.toJSON());
  }

  Future<void> editMessage(int id, String text) async {
    await supabase.from('messages').update({
      'text': text
    }).eq('id', id);
  }

  Future<void> deleteMessage(Message message) async {
    await supabase.from('messages').delete().eq('id', message.id);
    if (message.attachment != null) {
      supabase.storage.from('main').remove(['attachments/${message.id}.png']);
    }
  }

  Future<ImageProvider> getAttachment(int id) async {
    final ImageProvider? attachmentsProvider = attachmentProviders[id];
    if (attachmentsProvider != null) {
      return attachmentsProvider;
    }
    final storage = supabase.storage.from('main');
    final imageUrl = storage.getPublicUrl('attachments/$id.png');
    final provider = NetworkImage(imageUrl);
    attachmentProviders[id] = provider;
    return provider;
  }
}