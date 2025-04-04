import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı kayıt işlemi
  Future<AppUser?> signUp(String email, String password, UserType userType,
      String name, int height, double weight,
      {String? dietitianUid}) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      Map<String, dynamic> userBasicData = {
        'uid': uid,
        'email': email,
        'name': name, //buraya name ekleyince sorun çözüldü
        'userType': userType == UserType.client ? 'client' : 'dietitian',
      };
      print("Firestore'a kaydedilecek veri: $userBasicData");

      if (userType == UserType.client) {
        Client newUser = Client(
          uid: uid,
          name: name,
          email: email,
          height: height,
          weight: weight,
          allergies: [],
          diseases: [],
          dietitianUid: dietitianUid,
        );

        await _firestore.collection('clients').doc(uid).set(newUser.toMap());
      } else {
        Dietitian newUser =
            Dietitian(uid: uid, name: name, email: email, specialty: '');
        await _firestore.collection('dietitians').doc(uid).set(newUser.toMap());
      }

      // Users koleksiyonuna sadece temel bilgileri kaydet
      await _firestore.collection('users').doc(uid).set(userBasicData);
      if (userCredential.user == null) {
        print("Kullanıcı oluşturulamadı, userCredential.user null döndü!");
        return null;
      }

      return AppUser.fromMap(userBasicData); // Kullanıcı objesi döndür
    } catch (e) {
      print("Kayıt hatası: $e");
      return null;
    }
  }

  // Kullanıcı giriş işlemi
  Future<AppUser?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          String userType = userDoc.get('userType').toString();

          if (userType == 'dietitian') {
            DocumentSnapshot dietitianDoc =
                await _firestore.collection('dietitians').doc(uid).get();
            if (dietitianDoc.exists) {
              Map<String, dynamic> dietitianData =
                  dietitianDoc.data() as Map<String, dynamic>;
              return Dietitian(
                uid: uid,
                email: email,
                name: dietitianData['name'] ?? '',
                specialty: dietitianData['specialty'] ?? '',
                experience: dietitianData['experience'] ?? '',
                education: dietitianData['education'] ?? '',
                about: dietitianData['about'] ?? '',
                expertiseAreas:
                    List<String>.from(dietitianData['expertiseAreas'] ?? []),
              );
            }
          } else if (userType == 'client') {
            print("Danışan girişi tespit edildi");
            DocumentSnapshot clientDoc =
                await _firestore.collection('clients').doc(uid).get();
            if (clientDoc.exists) {
              Map<String, dynamic> clientData =
                  clientDoc.data() as Map<String, dynamic>;
              return Client(
                uid: uid,
                email: email,
                name: clientData['name'] ?? '',
                height: clientData['height'] ?? 0,
                weight: clientData['weight'] ?? 0.0,
                allergies: List<String>.from(clientData['allergies'] ?? []),
                diseases: List<String>.from(clientData['diseases'] ?? []),
                dietitianUid: clientData['dietitianUid'],
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      print("Giriş hatası detayı: $e");
      return null;
    }
  }

  // Kullanıcı çıkış işlemi
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şu an giriş yapan kullanıcıyı getir
  Future<AppUser?> getCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        String userType = userDoc.get('userType').toString();

        if (userType == 'dietitian') {
          DocumentSnapshot dietitianDoc = await _firestore
              .collection('dietitians')
              .doc(firebaseUser.uid)
              .get();
          if (dietitianDoc.exists) {
            Map<String, dynamic> dietitianData =
                dietitianDoc.data() as Map<String, dynamic>;
            return Dietitian(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: dietitianData['name'] ?? '',
              specialty: dietitianData['specialty'] ?? '',
              experience: dietitianData['experience'] ?? '',
              education: dietitianData['education'] ?? '',
              about: dietitianData['about'] ?? '',
              expertiseAreas:
                  List<String>.from(dietitianData['expertiseAreas'] ?? []),
            );
          }
        } else if (userType == 'client') {
          DocumentSnapshot clientDoc = await _firestore
              .collection('clients')
              .doc(firebaseUser.uid)
              .get();
          if (clientDoc.exists) {
            Map<String, dynamic> clientData =
                clientDoc.data() as Map<String, dynamic>;
            return Client(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: clientData['name'] ?? '',
              height: clientData['height'] ?? 0,
              weight: clientData['weight'] ?? 0.0,
              allergies: List<String>.from(clientData['allergies'] ?? []),
              diseases: List<String>.from(clientData['diseases'] ?? []),
              dietitianUid: clientData['dietitianUid'],
            );
          }
        }
      }
    }
    return null;
  }
}
