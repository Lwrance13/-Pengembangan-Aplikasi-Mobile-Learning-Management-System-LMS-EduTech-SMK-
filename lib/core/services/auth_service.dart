import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';
import 'user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getUserData(credential.user!.uid);
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? nisn,
    String? nip,
    String? kelas,
    String? mapel,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);

    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      name: name,
      role: role,
      nisn: nisn,
      nip: nip,
      kelas: kelas,
      mapel: mapel,
      createdAt: DateTime.now(),
    );

    await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
