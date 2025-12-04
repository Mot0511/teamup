import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:teamup/features/teams/utils/getLivekitToken.dart';
import 'package:teamup/features/teams/utils/getServerIP.dart';

class VoiceService {
  Room? room;

  int? roomID;
  bool isVoiceOn = false;
  bool isSoundOn = true;

  void Function(List<String> peers)? onPeersChanged;

  List<String> get peers {
    if (room == null) return [];
    final remotes = room!.remoteParticipants.values;
    return remotes.map((p) => p.identity).toList()..sort();
  }

  Future<void> connect(String uid, int roomID, bool isVoiceOn, bool isSoundOn) async {
    this.roomID = roomID;

    final token = await getLivekitToken(uid, roomID);
    if (token == null) throw Exception('Произошла ошибка при получении Livekit токена');
    
    room = Room(
      roomOptions: const RoomOptions(
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: false,
          noiseSuppression: false,
          autoGainControl: false,
        ),
      ),
    );
    
    room!.events.listen((RoomEvent event) {
      if (event is ParticipantConnectedEvent ||
          event is ParticipantDisconnectedEvent) {
        onPeersChanged!(peers);
        print('Изменен состав комнаты $peers');
      }

      if (event is TrackSubscribedEvent) {
        print('Получен аудиотрек от ${event.participant.identity}');
      }

      if (event is TrackUnsubscribedEvent) {
        print('Трек отключён: ${event.participant.identity}');
      }

      if (event is RoomDisconnectedEvent) {
        print('Отключено от комнаты');
      }
    });

    final ip = await getServerIP(uid, roomID);
    await room!.connect(
      'ws://$ip:7880',
      token,
      connectOptions: ConnectOptions(
        autoSubscribe: true,
      ),
    );

    await room!.localParticipant?.setMicrophoneEnabled(isVoiceOn);
  }

  Future<void> setIsVoiceOn(bool value) async {
    await room?.localParticipant?.setMicrophoneEnabled(value);
  }

  Future<void> setIsSoundOn(bool value) async {
    for (RemoteParticipant participant in room!.remoteParticipants.values) {
      for (RemoteTrackPublication track in participant.audioTrackPublications) {
        if (value) {
          track.enable();
        } else {
          track.disable();
        }
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await room?.disconnect();
      room = null;
      roomID = null;
      onPeersChanged!([]);
    } catch (_) {}
  }
}