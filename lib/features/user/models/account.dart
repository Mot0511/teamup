class Account {
  final String uid;
  final String email;
  final bool isVerified;

  const Account({required this.uid, required this.isVerified, required this.email});


  factory Account.fromJson(Map data) {
    return Account(
      uid: data['uid'],
      email: '${data['email'] ?? ''}',
      isVerified: data['isVerified'] ?? false,
    );
  }
}