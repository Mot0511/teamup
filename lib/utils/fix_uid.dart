import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> fixUid(String uid, String email) async {
  final supabase = GetIt.I<SupabaseClient>();

  final oldUid = 'f84a7261-4da8-40b4-943b-2a22bfb74524';
  
  await supabase.from('users').update({ 
    'uid': uid
  }).eq('uid', oldUid);

  await supabase.from('fcm_tokens').update({
    'user_id': uid
  }).eq('user_id', oldUid);

  await supabase.from('friends').update({
    'from_user': uid
  }).eq('from_user', oldUid);

  await supabase.from('friends').update({ 
    'to_user': uid
  }).eq('to_user', oldUid);

  await supabase.from('members').update({ 
    'member': uid
  }).eq('member', oldUid);

  await supabase.from('messages').update({ 
    'sender': uid
  }).eq('sender', oldUid);

  await supabase.from('pending_users').update({ 
    'pending_user': uid
  }).eq('pending_user', oldUid);

  await supabase.from('readed_messages').update({ 
    'user': uid
  }).eq('user', oldUid);

  // await supabase.storage.from('main').move('avatars/$oldUid.png', 'avatars/$uid.png');
}