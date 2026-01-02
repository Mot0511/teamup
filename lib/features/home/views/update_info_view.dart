import 'dart:io';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:teamup/features/home/models/update_info.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfoView extends StatefulWidget {
  const UpdateInfoView({super.key, required this.updateInfo});
  final UpdateInfo updateInfo;

  @override
  State<UpdateInfoView> createState() => _UpdateInfoViewState();
}

class _UpdateInfoViewState extends State<UpdateInfoView> {

  Future<void> onLaunchSite() async {
    final Uri url = Uri.parse('https://teamup-site.vercel.app/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> onLaunchRustore() async {
    final Uri url = Uri.parse('https://www.rustore.ru/catalog/app/ru.ballisty.teamup');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Обновление ${widget.updateInfo.currentVersion}', style: theme.textTheme.displayMedium),
                SizedBox(height: 30),
                Column(
                  children: [
                    Text('Что нового:', style: theme.textTheme.titleLarge),
                    SizedBox(height: 5),
                    Column(
                      children: widget.updateInfo.newFeatures.map((feature) => Text(feature, style: theme.textTheme.bodyMedium)).toList()
                    )
                  ],
                ),
              ]
            )
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onLaunchSite,
                  child: Text('Скачать с сайта Teamup', style: theme.textTheme.labelMedium)
                ),
                SizedBox(height: 10),
                if (Platform.isAndroid)
                ElevatedButton(
                  onPressed: onLaunchRustore, 
                  child: Text('Обновить в Rustore', style: theme.textTheme.labelMedium),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xff0077FF))
                ),
                SizedBox(height: 10)
              ],
            )
          )
        ],
      ),
      )
    );
  }
}