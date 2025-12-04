import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> getServerIP(String uid, int roomID) async {

  final supabase = GetIt.I<SupabaseClient>();
  final response = await supabase.functions.invoke(
    'get-server-ip',
    body: {},
  );

  if (response.data != null) return response.data['serverIP'];
  return null;  
}