import 'package:teamup/features/user/user.dart';

class Friendship {
  final User friend;
  FriendState state;

  Friendship({required this.friend, required this.state});
}