import 'package:equatable/equatable.dart';
import 'package:teamup/features/chats/models/chat.dart';

abstract class ChatsState extends Equatable {}

class ChatsStateInitial extends ChatsState {
  @override
  List get props => [];
}

class ChatsStateLoading extends ChatsState {
  @override
  List get props => [];
}

class ChatsStateLoaded extends ChatsState {
  final List<Chat> chats;

  ChatsStateLoaded({required this.chats});

  @override
  List get props => [chats];
}

class ChatsStateError extends ChatsState {
  final Object e;

  ChatsStateError({required this.e});

  @override
  List get props => [e];
}