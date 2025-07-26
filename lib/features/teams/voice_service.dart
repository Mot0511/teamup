import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class VoiceService {
  Socket? socket;
  
  VoiceService._();

  static final instance = VoiceService._();

  init({required String websocketUrl, required String callerID}) {
    socket = io(websocketUrl, {
      'transports': ['websocket'],
      'query': {'callerID': callerID}
    });

    socket!.onConnect((data) {
      print('Socket connected!');
    });

    socket!.onConnect((error) {
      print('Connect Error: $error');
    });

    socket!.connect();
  }
  
}