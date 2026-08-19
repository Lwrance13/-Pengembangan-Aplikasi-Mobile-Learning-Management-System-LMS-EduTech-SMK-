import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? photoUrl;
  final String? nisn; // for students
  final String? nip; // for teachers
  final String? kelas; // for students / wali kelas
  final String? mapel; // for guru mapel
  final String? fcmToken;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.nisn,
    this.nip,
    this.kelas,
    this.mapel,
    this.fcmToken,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      photoUrl: data['photo_url'],
      nisn: data['nisn'],
      nip: data['nip'],
      kelas: data['kelas'],
      mapel: data['mapel'],
      fcmToken: data['fcm_token'],
      isActive: data['is_active'] ?? true,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'photo_url': photoUrl,
      'nisn': nisn,
      'nip': nip,
      'kelas': kelas,
      'mapel': mapel,
      'fcm_token': fcmToken,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? role,
    String? photoUrl,
    String? nisn,
    String? nip,
    String? kelas,
    String? mapel,
    String? fcmToken,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      nisn: nisn ?? this.nisn,
      nip: nip ?? this.nip,
      kelas: kelas ?? this.kelas,
      mapel: mapel ?? this.mapel,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
