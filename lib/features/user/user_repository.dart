import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/features/user/models/models.dart';

class AuthResult {
  final sb.User userdata;
  final bool isNew;

  AuthResult({required this.userdata, required this.isNew});
}

class UserRepository {

  final sb.SupabaseClient supabase = GetIt.I<sb.SupabaseClient>();

  Future<void> updateUser(User user) async {
    await supabase.from('users').update(
      user.toJSON()
    ).eq('uid', user.uid);
  }

  Future<AuthResult?> googleSignIn(context) async {
    try {
      const androidClientId = '677191252450-plq6hd0tkmh0befgpm2lrh06hpf7mj37.apps.googleusercontent.com';
      const desktopClientId = '677191252450-ibg34ij1u3kcjo5pid4ptjtf8dadp10f.apps.googleusercontent.com';
      const webClientId = '677191252450-s6a7kuf9dek6arhufeot9i968a8bhloh.apps.googleusercontent.com';
      
      if (Platform.isAndroid) {
        final googleSignIn = GoogleSignIn(
          clientId: androidClientId,
          serverClientId: webClientId,
          scopes: ["profile", "email"],
        );
        final googleUser = await googleSignIn.signIn();
        final googleAuth = await googleUser!.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null) {
          throw 'No Access Token found.';
        }
        if (idToken == null) {
          throw 'No ID Token found.';
        }

        await supabase.auth.signInWithIdToken(
          provider: sb.OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
      } else {
        await supabase.auth.signInWithOAuth(
          sb.OAuthProvider.google,
          redirectTo: 'https://google.com',
          authScreenLaunchMode: sb.LaunchMode.inAppWebView,
        );
      }

      final userdata = (await supabase.auth.getUser()).user;
      if (userdata != null) {
          final users = await supabase.from('users').select().eq('uid', userdata.id);
          if (users.isEmpty) {
            return AuthResult(
              userdata: userdata,
              isNew: true
            );
          }
          return AuthResult(
            userdata: userdata,
            isNew: false
          );
      }
    } on AppwriteException catch (e) {
      Fluttertoast.showToast(msg: 'Произошла ошибка при авторизации');
    }
  }

  Future<void> signout() async {
    await GoogleSignIn().disconnect();
    await supabase.auth.signOut();
  }

  Future<void> addUserdata(User userdata) async {
    await supabase.from('users').insert([userdata.toJSON()]);
  }

  Future<User> getUserdata(String uid) async {
    final userdata = await supabase.from('users').select('*, favouriteGame(*)').eq('uid', uid).single();
    return User.fromJSON(userdata);
  }

  Future<ImageProvider> getAvatar(String uid) async {
    final storage = supabase.storage.from('main');
    if (await storage.exists('avatars/$uid.png')){
      final imageUrl = supabase.storage.from('main').getPublicUrl('avatars/$uid.png');
      return NetworkImage(imageUrl);
    }
    return AssetImage('assets/default_avatar.png');

  }

  Future<void> uploadAvatar(File file, String uid) async {
    await supabase.storage.from('main').upload(
      'avatars/$uid.png', 
      file, 
      fileOptions: sb.FileOptions(upsert: true)
    );
  }

  Future<void> addFriend(User user, User friend) async {
    await supabase.from('friends').insert([
      {
        'from_user': user.uid,
        'to_user': friend.uid,
        'status': false
      }
    ]);
  }

  Future<void> allowFriendRequest(String uid) async {
    await supabase.from('friends').update({
      'status': true
    }).eq('to_user', uid);
  }

  Future<List<Friendship>> getFriends(String uid) async {
    final List data = await supabase.from('friends').select('from_user(*, favouriteGame(*)), to_user(*, favouriteGame(*)), status').or('from_user.eq.$uid,to_user.eq.$uid');
    final List<Friendship> friends = data.map((row) {
      if (row['status']) {
        if (row['from_user']['uid'] == uid) {
          return Friendship(friend: User.fromJSON(row['to_user']), state: FriendState.friend);
        } else {
          return Friendship(friend: User.fromJSON(row['from_user']), state: FriendState.friend);
        }
      } else {
        if (row['from_user']['uid'] == uid) {
          return Friendship(friend: User.fromJSON(row['to_user']), state: FriendState.iRequested);
        } else {
          return Friendship(friend: User.fromJSON(row['from_user']), state: FriendState.requestedToMe);
        }
      }
    }).toList();

    return friends;
  }

  Future<void> removeFriend(String uid) async {
    await supabase.from('friends').delete().or('from_user.eq.$uid, to_user.eq.$uid');
  }

}
