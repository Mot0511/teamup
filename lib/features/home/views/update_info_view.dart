import 'dart:io';
import 'package:flutter/material.dart';
import 'package:teamup/features/home/home.dart';
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
      appBar: AppBar(
        title: Text('Обновление ${widget.updateInfo.currentVersion}'),
      ),
      body: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Expanded(
                  child: Column(
                    children: [
                      Text('Что нового:', style: theme.textTheme.headlineMedium),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          children: widget.updateInfo.newFeatures.map((feature) => 
                            Padding(
                              padding: EdgeInsets.only(left: 20, bottom: 10),
                              child: Text(feature, style: theme.textTheme.bodyLarge),
                            )
                          ).toList()
                        ),
                      )
                    ],
                  ),
                )
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