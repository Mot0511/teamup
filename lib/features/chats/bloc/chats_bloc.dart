import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamup/features/chats/bloc/chats_events.dart';
import 'package:teamup/features/chats/bloc/chats_states.dart';
import 'package:teamup/features/chats/chats_repository.dart';
import 'package:teamup/features/chats/models/chat.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  ChatsBloc({required this.chatsRepository}) : super(ChatsStateInitial()) {
    on<LoadChats>((event, emit) async {
      if (event.completer == null) emit(ChatsStateLoading());
      try {
        final chats = await chatsRepository.getChats(event.uid);
        emit(ChatsStateLoaded(chats: chats));
        event.completer?.complete();
      } on Exception catch (e) {
        emit(ChatsStateError(e: e));
      }
    });

    on<AddChat>((event, emit) async {
      if (state is ChatsStateLoaded) {
        try {
          final List<Chat> chats = (state as ChatsStateLoaded).chats;
          emit(ChatsStateLoading());
          chats.add(event.chat);
          emit(ChatsStateLoaded(chats: chats));
        } on Exception catch (e) {
          emit(ChatsStateError(e: e));
        }
      }
    });

    on<RemoveChat>((event, emit) async {
      if (state is ChatsStateLoaded) {
        try {
          final List<Chat> chats = (state as ChatsStateLoaded).chats;
          await chatsRepository.removeChat(event.chat);
          emit(ChatsStateInitial());
          chats.remove(event.chat);
          emit(ChatsStateLoaded(chats: chats));
        } on Exception catch (e) {
          emit(ChatsStateError(e: e));
        }
      }
    });

    on<ClearChats>((event, emit) async {
      emit(ChatsStateInitial());
    });


  }

  final ChatsRepository chatsRepository;
}