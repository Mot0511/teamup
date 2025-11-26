import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/models/models.dart';

class Friendship {
  final User friend;
  FriendState state;

  Friendship({required this.friend, required this.state});
}