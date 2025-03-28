import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all clients for a specific dietitian
  Future<List<Client>> getClientsForDietitian(String dietitianUid) async {
    final snapshot = await _firestore
        .collection('clients')
        .where('dietitianUid', isEqualTo: dietitianUid)
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data()) as Client)
        .toList();
  }

  // Get a specific client by ID
  Future<Client?> getClientById(String uid) async {
    final doc = await _firestore.collection('clients').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!) as Client;
  }

  // Update client information
  Future<void> updateClient(Client client) async {
    await _firestore
        .collection('clients')
        .doc(client.uid)
        .update(client.toMap());
  }

  // Assign a client to a dietitian
  Future<void> assignClientToDietitian(
      String clientUid, String dietitianUid) async {
    await _firestore.collection('clients').doc(clientUid).update({
      'dietitianUid': dietitianUid,
    });
  }

  Future<void> addClientToDietitian({
    required String clientId,
    required String dietitianId,
  }) async {
    try {
      await _firestore.collection('clients').doc(clientId).update({
        'dietitianUid': dietitianId,
      });
      await _firestore.collection('users').doc(clientId).update({
        'dietitianUid': dietitianId,
      });
    } catch (e) {
      print('Error adding client to dietitian: $e');
      throw e;
    }
  }
}
