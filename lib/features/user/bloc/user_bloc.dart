import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:teamup/features/user/bloc/user_events.dart';
import 'package:teamup/features/user/bloc/user_states.dart';
import 'package:teamup/features/user/models/user.dart';
import 'package:teamup/features/user/user_repository.dart';
import 'package:teamup/features/analytics/repositories/analytics_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.userRepository}) : super(UserStateInitial()) {
    on<LoadUser>((event, emit) async {
      emit(UserStateLoading());
      try {
        final User user = await userRepository.getUserdata(event.uid);
        final analyticsRepository = GetIt.I<AnalyticsRepository>();
        analyticsRepository.logOpenApp(user);
        emit(UserStateLoaded(user: user));
      } on Exception catch (e) {
        emit(UserStateError(e: e));
      }
    });

    on<UpdateUser>((event, emit) async {
      try {
        emit(UserStateLoading());
        await userRepository.updateUser(event.user);
        if (event.choosenAvatar != null){
          await userRepository.uploadAvatar(event.choosenAvatar as File, event.user.uid);
        }
        emit(UserStateLoaded(user: event.user));
      } on Exception catch (e) {
        emit(UserStateError(e: e));
      }
    });

    on<Signout>((event, emit) {
      emit(UserStateInitial());
    });
  }

  final UserRepository userRepository;
}