enum UserType { dietitian, client }

abstract class AppUser {
  final String uid; // Firebase UID
  final String name;
  final String email;
  final UserType userType;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
  });

  // Firestore'dan gelen veriyi User nesnesine çevirme
  factory AppUser.fromMap(Map<String, dynamic> map) {
    UserType userType =
        map['userType'] == 'dietitian' ? UserType.dietitian : UserType.client;

    if (userType == UserType.client) {
      return Client(
        uid: map['uid'],
        name: map['name'],
        email: map['email'],
        height: map['height'] ?? 0,
        weight: map['weight']?.toDouble() ?? 0.0,
        allergies: List<String>.from(map['allergies'] ?? []),
        diseases: List<String>.from(map['diseases'] ?? []),
      );
    } else {
      return Dietitian(
        uid: map['uid'],
        name: map['name'],
        email: map['email'],
        specialty: map['specialty'] ?? '',
      );
    }
  }

  // Firestore'a kaydetmek için Map'e çevirme
  Map<String, dynamic> toMap();
}

class Client extends AppUser {
  final int height;
  final double weight;
  final List<String> allergies;
  final List<String> diseases;

  Client({
    required String uid,
    required String name,
    required String email,
    required this.height,
    required this.weight,
    this.allergies = const [],
    this.diseases = const [],
  }) : super(uid: uid, name: name, email: email, userType: UserType.client);

  double get bmi {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': 'client',
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'diseases': diseases,
    };
  }

  @override
  String toString() {
    return 'Client{name: $name, email: $email, height: $height, weight: $weight, bmi: ${bmi.toStringAsFixed(2)}}';
  }
}

class Dietitian extends AppUser {
  final String specialty;

  Dietitian({
    required String uid,
    required String name,
    required String email,
    required this.specialty,
  }) : super(uid: uid, name: name, email: email, userType: UserType.dietitian);

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': 'dietitian',
      'specialty': specialty,
    };
  }

  @override
  String toString() {
    return 'Dietitian{name: $name, email: $email, specialty: $specialty}';
  }
}
