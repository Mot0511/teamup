import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> getLivekitToken(String uid, int roomID) async {
  final dio = GetIt.I<Dio>();
  final res = await dio.post("/voice/$roomID/livekit-token");
  return res.data;
}