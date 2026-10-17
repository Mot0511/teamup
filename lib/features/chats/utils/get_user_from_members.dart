import 'package:teamup/features/user/models/models.dart';

User getUserFromMembers(String uid, List<User> users) {
  User sender;
  try {
    final List<User> matches = users
        .where((user) => user.uid == uid)
        .toList();
    sender = matches.isNotEmpty ? matches.first : User(uid: uid, username: uid, email: '', gender: '', age: 0);
  } catch (_) {
    sender = User(uid: uid, username: uid, email: '', gender: '', age: 0);
  }

  return sender;
}