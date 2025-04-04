enum UserType { dietitian, client }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserType userType;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': userType.toString(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    if (map['userType'] == 'client') {
      return Client(
        uid: map['uid'],
        name: map['name'],
        email: map['email'],
        height: map['height'] ?? 0,
        weight: map['weight']?.toDouble() ?? 0.0,
        allergies: List<String>.from(map['allergies'] ?? []),
        diseases: List<String>.from(map['diseases'] ?? []),
        dietitianUid: map['dietitianUid'],
      );
    } else {
      return Dietitian(
        uid: map['uid'],
        name: map['name'],
        email: map['email'],
        specialty: map['specialty'] ?? '',
        experience: map['experience'] ?? '',
        expertiseAreas: List<String>.from(map['expertiseAreas'] ?? []),
        education: map['education'] ?? '',
        about: map['about'] ?? '',
      );
    }
  }
}

class Client extends AppUser {
  final int height;
  final double weight;
  final List<String> allergies;
  final List<String> diseases;
  final String? dietitianUid;

  Client({
    required String uid,
    required String name,
    required String email,
    required this.height,
    required this.weight,
    this.allergies = const [],
    this.diseases = const [],
    this.dietitianUid,
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
      'dietitianUid': dietitianUid,
    };
  }

  @override
  String toString() {
    return 'Client{name: $name, email: $email, height: $height, weight: $weight, bmi: ${bmi.toStringAsFixed(2)}}';
  }
}

class Dietitian extends AppUser {
  final String specialty;
  final String experience;
  final List<String> expertiseAreas;
  final String education;
  final String about;

  Dietitian({
    required String uid,
    required String name,
    required String email,
    required this.specialty,
    this.experience = '',
    this.expertiseAreas = const [],
    this.education = '',
    this.about = '',
  }) : super(uid: uid, name: name, email: email, userType: UserType.dietitian);

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': 'dietitian',
      'specialty': specialty,
      'experience': experience,
      'expertiseAreas': expertiseAreas,
      'education': education,
      'about': about,
    };
  }

  @override
  String toString() {
    return 'Dietitian{name: $name, email: $email, specialty: $specialty, experience: $experience, expertiseAreas: $expertiseAreas, education: $education, about: $about}';
  }
}
