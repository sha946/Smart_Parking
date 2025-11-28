import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer toutes les places
  Stream<List<ParkingSpot>> getParkingSpots() {
    return _firestore
        .collection('parkingSpots')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingSpot.fromFirestore(doc))
              .toList(),
        );
  }

  // Méthode pour réserver une place
  Future<void> reserveSpot({
    required String spotId,
    required String licensePlate,
    required String email,
    required DateTime reservationDate,
    required int hour,
    required int minute,
    int duration = 1,
  }) async {
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      hour,
      minute,
    );

    final reservedUntil = reservationDateTime.add(const Duration(hours: 1));

    // Mettre à jour la place
    await _firestore.collection('parkingSpots').doc(spotId).update({
      'status': 'reserved',
      'isOccupied': false,
      'licensePlate': licensePlate.toUpperCase(),
      'reservedUntil': reservedUntil.toIso8601String(),
      'reservationEmail': email,
      'reservationStart': reservationDateTime.toIso8601String(),
      'reservationEnd': reservedUntil.toIso8601String(),
      'lastUpdate': FieldValue.serverTimestamp(),
      'duration_hours': duration,
    });

    // Créer une entrée dans la collection des réservations
    await _firestore.collection('reservations').add({
      'spot_id': spotId,
      'email': email,
      'license_plate': licensePlate.toUpperCase(),
      'reservation_date': reservationDateTime.toIso8601String(),
      'reserved_until': reservedUntil.toIso8601String(),
      'created_at': FieldValue.serverTimestamp(),
      'status': 'confirmed',
      'reservation_id': 'RES${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  // Vérifier si une place est disponible
  Future<bool> isSpotAvailable(String spotId) async {
    try {
      final doc = await _firestore.collection('parkingSpots').doc(spotId).get();
      if (!doc.exists) return false;

      final spot = ParkingSpot.fromFirestore(doc);
      return !spot.isOccupied && spot.status != 'reserved';
    } catch (e) {
      return false;
    }
  }

  // Annuler une réservation
  Future<void> cancelReservation(String spotId) async {
    await _firestore.collection('parkingSpots').doc(spotId).update({
      'status': 'free',
      'licensePlate': null,
      'reservedUntil': null,
      'reservationEmail': null,
      'reservationStart': null,
      'reservationEnd': null,
    });
  }

  // Méthode pour libérer une place
  Future<void> freeSpot(String spotId) {
    return _firestore.collection('parkingSpots').doc(spotId).update({
      'isOccupied': false,
      'status': 'free',
      'licensePlate': null,
      'reservedUntil': null,
      'reservationEmail': null,
      'reservationStart': null,
      'reservationEnd': null,
      'entryTime': null,
      'exitTime': DateTime.now().toIso8601String(),
    });
  }
}
