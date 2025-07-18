import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/user_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.userRepository}) : super(UserStateInitial()) {
    on<LoadUser>((event, emit) async {
      emit(UserStateLoading());
      try {
        final User user = await userRepository.getUserdata(event.uid);
        emit(UserStateLoaded(user: user));
      } on Exception catch (e) {
        emit(UserStateError(e: e));
        Fluttertoast.showToast(msg: "Произошла ошибка при загрузке данных пользователя");
      }
    });

    on<UpdateUser>((event, emit) async {
      emit(UserStateLoading());
      await userRepository.updateUser(event.user);
      if (event.choosenAvatar != null){
        await userRepository.uploadAvatar(event.choosenAvatar as File, event.user.uid);
      }
      emit(UserStateLoaded(user: event.user));
    });

    on<Signout>((event, emit) {
      emit(UserStateInitial());
    });
  }

  final UserRepository userRepository;
}