import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:teamup/features/chats/models/chat.dart';

abstract class ChatsEvent extends Equatable {}

class LoadChats extends ChatsEvent {
  final String uid;
  final Completer? completer;
  LoadChats({required this.uid, this.completer});

  @override
  List get props => [uid];
}

class AddChat extends ChatsEvent {
  final Chat chat;

  AddChat({required this.chat});

  @override
  List get props => [chat];
}

class RemoveChat extends ChatsEvent {
  final Chat chat;

  RemoveChat({required this.chat});

  @override
  List get props => [chat];
}

class ClearChats extends ChatsEvent {
  @override
  List get props => [];
}