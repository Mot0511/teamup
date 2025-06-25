import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/chats/bloc/chats_events.dart';
import 'package:teamup/features/chats/bloc/chats_states.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/models/chat.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  ChatsBloc({required this.chatsRepository}) : super(ChatsStateInitial()) {
    on<LoadChats>((event, emit) async {
      emit(ChatsStateLoading());
      try {
        final chats = await chatsRepository.getChats(event.uid);
        emit(ChatsStateLoaded(chats: chats));
      } on Exception catch (e) {
        emit(ChatsStateError(e: e));
      }
    });

    on<AddChat>((event, emit) async {
      if (state is ChatsStateLoaded) {
        final List<Chat> chats = (state as ChatsStateLoaded).chats;
        emit(ChatsStateLoading());
        chats.add(event.chat);
        emit(ChatsStateLoaded(chats: chats));
      }
    });


  }

  final ChatsRepository chatsRepository;
}