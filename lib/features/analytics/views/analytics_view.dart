import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/analytics/models/analytics_results.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {

  AnalyticsResults? analytics;
  final analytcsRepository = GetIt.I<AnalyticsRepository>();
  int? period;

  Future<void> loadAnalytics({int? period}) async {
    analytics = null;
    this.period = period;
    setState(() {});
    analytics = await analytcsRepository.getAnalytics(period);
    setState(() {});
  }

  void initState() {
    super.initState();

    loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Аналитика')),
      body: Center(
        child: SingleChildScrollView(
          child: analytics != null
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton(
                  value: period,
                  items: [
                    DropdownMenuItem(child: Text('За все время'), value: null),
                    DropdownMenuItem(child: Text('За день'), value: 86400000),
                    DropdownMenuItem(child: Text('За неделю'), value: 604800000),
                    DropdownMenuItem(child: Text('За месяц'), value: 2629746000),
                    DropdownMenuItem(child: Text('За год'), value: 31536000000),
                  ], 
                  onChanged: (value) => loadAnalytics(period: value)
                ),
                Text(analytics!.usersCount.toString(), style: theme.textTheme.displayMedium),
                Text('пользователей в приложении', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.signUpCount.toString(), style: theme.textTheme.displayMedium),
                Text('регистраций', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.openAppCount.toString(), style: theme.textTheme.displayMedium),
                Text('заходов в приложение', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.startSearchingCount.toString(), style: theme.textTheme.displayMedium),
                Text('поисков', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.finishSearchingCount.toString(), style: theme.textTheme.displayMedium),
                Text('из них удачных', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.openTeamScreen.toString(), style: theme.textTheme.displayMedium),
                Text('заходов в команды', style: theme.textTheme.titleMedium),
                SizedBox(height: 30),
                Text(analytics!.openChatScreen.toString(), style: theme.textTheme.displayMedium),
                Text('заходов в личные чаты', style: theme.textTheme.titleMedium),
              ],
            )
          : Center(child: CircularProgressIndicator())
        )
      )
    );
  }
}