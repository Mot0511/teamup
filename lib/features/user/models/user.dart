import 'package:flutter/material.dart';
import 'package:teamup/features/user/models/friendship.dart';
import 'package:teamup/models/game.dart';

class User {
  final String uid;
  final String email;
  String username;
  String? description;
  String gender;
  int age;
  Game? favouriteGame;

  User({
    required this.uid, 
    required this.username, 
    this.description, 
    required this.email, 
    required this.gender, 
    required this.age, 
    this.favouriteGame, 
  });

  factory User.fromJSON(Map data) {
    return User(
      uid: data['uid'],
      username: data['username'],
      description: data['description'],
      email: data['email'],
      gender: data['gender'],
      age: data['age'],
      favouriteGame: data['favouriteGame'] != null && data['favouriteGame'].runtimeType != int ? Game.fromJSON(data['favouriteGame']) : null,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'uid': uid,
      'username': username,
      'description': description,
      'email': email,
      'gender': gender,
      'age': age,
      'favouriteGame': favouriteGame?.id,
    };
  }

}