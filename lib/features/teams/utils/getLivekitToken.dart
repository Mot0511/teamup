import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> getLivekitToken(String uid, int roomID) async {

  final supabase = GetIt.I<SupabaseClient>();

  final response = await supabase.functions.invoke(
    'livekit-tokens',
    body: {'uid': uid, 'roomID': roomID},
  );

  if (response.data != null) return response.data['token'];
  return null;  
}