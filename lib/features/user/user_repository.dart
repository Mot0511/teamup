import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:teamup/features/teams/voice_service.dart';
import 'package:teamup/features/user/enums.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/features/user/models/models.dart';
import 'package:teamup/nav_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthResult {
  final sb.User userdata;
  final bool isNew;

  AuthResult({required this.userdata, required this.isNew});
}

class UserRepository {

  final supabase = GetIt.I<sb.SupabaseClient>();

  final Map<String, ImageProvider> avatarProviders = {};

  Future<void> googleSignIn() async {
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
        final loginUrl = (await supabase.auth.getOAuthSignInUrl(
          provider: sb.OAuthProvider.google,
          redirectTo: "https://flvcuqostwctdicmncrb.supabase.co/auth/v1/callback"
        )).url;

        final result = await FlutterWebAuth2.authenticate(
          url: loginUrl,
          callbackUrlScheme: "http://localhost:3000/auth/v1/callback",
          options: FlutterWebAuth2Options(useWebview: false)
        );
        await supabase.auth.getSessionFromUrl(Uri.parse(result));
      }
  }

  Future<void> discordSignIn() async {
    if (Platform.isAndroid) {
      await supabase.auth.signInWithOAuth(
        sb.OAuthProvider.discord,
        redirectTo: 'teamup://home',
        queryParams: {
          'redirectTo': 'teamup://home'
        }
      );
    } else {
      final loginUrl = (await supabase.auth.getOAuthSignInUrl(
        provider: sb.OAuthProvider.discord,
        redirectTo: "https://flvcuqostwctdicmncrb.supabase.co/auth/v1/callback"
      )).url;

      final result = await FlutterWebAuth2.authenticate(
        url: loginUrl,
        callbackUrlScheme: "http://localhost:3000",
        options: FlutterWebAuth2Options(useWebview: false)
      );
      await supabase.auth.getSessionFromUrl(Uri.parse(result));
    }
  }

  Future<void> signout() async {
    try {
      await GoogleSignIn().disconnect();
    } on Exception catch (_) {}
    final uid = supabase.auth.currentUser!.id;
    await supabase.from('fcm_tokens').delete().eq('user_id', uid);
    await supabase.auth.signOut();
  }

  Future<void> addUserdata(User userdata) async {
    await supabase.from('users').insert([userdata.toJSON()]);
  }

  Future<User> getUserdata(String uid) async {
    final userdata = await supabase.from('users').select('*, favouriteGame(*)').eq('uid', uid).single();
    return User.fromJSON(userdata);
  }

  Future<bool> isUsernameExists(String username) async {
    final String? uid = supabase.auth.currentUser?.id;
    final users = await supabase.from('users').select('uid, username').eq('username', username);
    if (users.isNotEmpty) {
      if (uid != null && users[0]['uid'] == uid) {
        return false;
      }
      return true;
    }
    return false;
  }

  Future<void> updateUser(User user) async {
    await supabase.from('users').update(
      user.toJSON()
    ).eq('uid', user.uid);
  }
  

  Future<ImageProvider> getAvatar(String uid) async {
    final ImageProvider? avatarProvider = avatarProviders[uid];
    if (avatarProvider != null) {
      return avatarProvider;
    }
    final storage = supabase.storage.from('main');
    if (await storage.exists('avatars/$uid.png')){
      final imageUrl = supabase.storage.from('main').getPublicUrl('avatars/$uid.png');
      final provider = NetworkImage(imageUrl);
      avatarProviders[uid] = provider;
      return provider;
    }
    final provider = AssetImage('assets/images/default_avatar.png');
    avatarProviders[uid] = provider;
    return provider;

  }

  Future<void> uploadAvatar(File file, String uid) async {
    await supabase.storage.from('main').upload(
      'avatars/$uid.png', 
      file, 
      fileOptions: sb.FileOptions(upsert: true)
    );
  }

  void updateAvatarCache(String uid, ImageProvider avatar) {
    avatarProviders[uid] = avatar;
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

  Future<void> allowFriendRequest(String from_user, String to_user) async {
    await supabase.from('friends').update({
      'status': true
    }).eq('from_user', from_user)
    .eq('to_user', to_user);
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

  Future<void> setOnline(String uid) async {
    await supabase.from('users').update({
      'isOnline': true
    }).eq('uid', uid);
  }

  Future<void> setOffline(String uid) async {
    await supabase.from('users').update({
      'isOnline': false
    }).eq('uid', uid);
  }
  
  Future<bool> getIsOnline(String uid) async {
    return (await supabase.from('users').select('isOnline').eq('uid', uid).single())['isOnline'];
  }

}
