// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:teamup/features/teams/voice_service.dart';
// import 'package:teamup/features/user/bloc/user_bloc.dart';
// import 'package:teamup/features/user/bloc/user_states.dart';
// import 'package:teamup/features/user/models/models.dart';

// class VoiceProvider extends ChangeNotifier {
//   bool isVoiceOn = true;
//   bool isSoundOn = true;
//   List<String> peers = [];

//   final userBloc = GetIt.I<UserBloc>();

//   VoiceService? voiceService;
  
//   Future<void> init(
//     {required roomId,
//     required String selfId,
//     required bool isSoundOn,
//     required bool isVoiceOn}
//   ) async {
//     this.isSoundOn = isSoundOn;
//     this.isVoiceOn = isVoiceOn;
//     voiceService = VoiceService(
//       roomId: roomId.toString(), 
//       selfId: selfId,
//       onPeersChanged: (peers) async {
//         this.peers = peers;
//         if (!this.isSoundOn) {
//           for (String peer in peers) {
//             await voiceService?.setRemoteMuted(peer, true);
//           }
//         }
//         notifyListeners();
//       },
//     );
//     await voiceService?.init();
//     if (!isVoiceOn) {
//       await voiceService?.setMuted(true);
//     }
//     notifyListeners();
//   }  

//   Future<void> toggleVoice() async {
//     if (isVoiceOn) {
//       isVoiceOn = false;
//       await voiceService?.setMuted(true);
//     } else {
//       isVoiceOn = true;
//       await voiceService?.setMuted(false);
//     }
//     notifyListeners();
//   }
  
//   Future<void> toggleSound() async {
//     if (isSoundOn) {
//       isSoundOn = false;
//       for (String peer in peers) {
//         await voiceService?.setRemoteMuted(peer, true);
//       }
//     } else {
//       isSoundOn = true;
//       for (String peer in peers) {
//         await voiceService?.setRemoteMuted(peer, false);
//       }
//     }
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     voiceService?.dispose();
//     voiceService = null;
//   }
// }