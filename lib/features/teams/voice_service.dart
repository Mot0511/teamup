import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:teamup/features/teams/models/team.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class VoiceService {
  final zego = ZegoExpressEngine.instance;
  
  Future<ZegoRoomLoginResult> loginRoom(User user, Team team) async {
    final zegouser = ZegoUser(user.uid, user.username);

    final String roomID = team.id.toString();

    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()..isUserStatusNotify = true;

    // if (kIsWeb) {
    //   roomConfig.token = ZegoTokenUtils.generateToken(appID, serverSecret, widget.localUserID);
    // }
    // log in to a room
    return ZegoExpressEngine.instance.loginRoom(roomID, zegouser, config: roomConfig).then((ZegoRoomLoginResult loginRoomResult) {
      debugPrint('loginRoom: errorCode:${loginRoomResult.errorCode}, extendedData:${loginRoomResult.extendedData}');
      if (loginRoomResult.errorCode == 0) {
        startPublish(user, team);
      } else {
        Fluttertoast.showToast(msg: 'Ошибка при подключении к голосовому чату: ${loginRoomResult.errorCode}');
      }
      return loginRoomResult;
    });
  }

  Future<ZegoRoomLogoutResult> logoutRoom(Team team) async {
    stopPublish();
    return ZegoExpressEngine.instance.logoutRoom(team.id.toString());
  }

  Future<void> startPublish(User user, Team team) async{
    // After calling the `loginRoom` method, call this method to publish streams.
    // The StreamID must be unique in the room.
    String streamID = '${team.id.toString()}_${user.uid}_call';
    ZegoExpressEngine.instance.enableCamera(false);
    return ZegoExpressEngine.instance.startPublishingStream(streamID);
  }

  Future<void> stopPublish() async {
    return ZegoExpressEngine.instance.stopPublishingStream();
  }
  
  Future<void> startPlayStream(String streamID) async {
    ZegoExpressEngine.instance.startPlayingStream(streamID);
  }

  Future<void> stopPlayStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
  }
}