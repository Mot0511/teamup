import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/analytics/models/analytics_results.dart';
import 'package:teamup/features/user/models/models.dart';

class AnalyticsRepository {

  final supabase = GetIt.I<sb.SupabaseClient>();

  AnalyticsRepository();

  Future<AnalyticsResults> getAnalytics(int? period) async {
    if (period != null) {
      final int time = DateTime.now().millisecondsSinceEpoch;
      return AnalyticsResults(
        usersCount: await supabase.from('users').count(),
        signUpCount: (await supabase.from('stats').select('id').eq('event', 'sign_up').gte('timestamp', time - period).count()).count,
        openAppCount: (await supabase.from('stats').select('id').eq('event', 'open_app').gte('timestamp', time - period).count()).count,
        openTeamScreen: (await supabase.from('stats').select('id').eq('event', 'open_team_screen').gte('timestamp', time - period).count()).count,
        openChatScreen: (await supabase.from('stats').select('id').eq('event', 'open_chat_screen').gte('timestamp', time - period).count()).count,
        startSearchingCount: (await supabase.from('stats').select('id').eq('event', 'start_searching').gte('timestamp', time - period).count()).count,
        finishSearchingCount: (await supabase.from('stats').select('id').eq('event', 'finish_searching').gte('timestamp', time - period).count()).count,
      );
    }

    return AnalyticsResults(
      usersCount: await supabase.from('users').count(),
      signUpCount: await supabase.from('stats').count().eq('event', 'sign_up'), 
      openAppCount: await supabase.from('stats').count().eq('event', 'open_app'), 
      openTeamScreen: await supabase.from('stats').count().eq('event', 'open_team_screen'), 
      openChatScreen: await supabase.from('stats').count().eq('event', 'open_chat_screen'), 
      startSearchingCount: await supabase.from('stats').count().eq('event', 'start_searching'), 
      finishSearchingCount: await supabase.from('stats').count().eq('event', 'finish_searching')
    );
  }

  Future<void> logSignup(User user, BuildContext context) async {
    await logEvent('sign_up', properties: {
      'Country': Localizations.localeOf(context).countryCode,
      'Age': user.age,
      'Gender': user.gender,
      'OS': Platform.operatingSystem
    });
  }

  Future<void> logOpenApp(User user) async {
    await logEvent('open_app', properties: {
      'Age': user.age,
      'Gender': user.gender,
      'OS': Platform.operatingSystem
    });
  }

  Future<void> logEvent(String eventName, {Map? properties}) async {
    if (supabase.auth.currentUser != null) {
      await supabase.from('stats').insert([{
        'event': eventName,
        'properties': properties,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }]);
    }

  }
}