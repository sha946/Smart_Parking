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

  // Method to log parking history
  Future<void> logParkingHistory({
    required String spotId,
    required String licensePlate,
    required String action, // 'entry', 'exit', 'reservation', 'cancellation'
  }) async {
    try {
      await _firestore.collection('historique').add({
        'spot_id': spotId,
        'license_plate': licensePlate.toUpperCase(),
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging history: $e');
      // Don't rethrow - history logging shouldn't block main operations
    }
  }

  // Méthode pour réserver une place (mise à jour avec paramètre price)
  Future<void> reserveSpot({
    required String spotId,
    required String licensePlate,
    required String email,
    required DateTime reservationDate,
    required int hour,
    required int minute,
    int duration = 1,
    double price = 0.0, // Nouveau paramètre
  }) async {
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      hour,
      minute,
    );

    final reservedUntil = reservationDateTime.add(Duration(hours: duration));

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
      'spotId': spotId,
      'email': email,
      'licensePlate': licensePlate.toUpperCase(),
      'reservationDateTime': Timestamp.fromDate(reservationDateTime),
      'creationDate': FieldValue.serverTimestamp(),
      'duration': duration,
      'price': price, // Prix ajouté
      'status': 'confirmed',
    });

    // Log reservation to history
    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'reservation',
    );
  }

  // Méthode pour récupérer les réservations par email
  Stream<List<Reservation>> getUserReservations(String email) {
    try {
      return _firestore
          .collection('reservations')
          .where('email', isEqualTo: email)
          .orderBy('creationDate', descending: true)
          .snapshots()
          .map((snapshot) {
            final reservations = <Reservation>[];

            for (final doc in snapshot.docs) {
              try {
                final reservation = Reservation.fromMap(doc.data(), doc.id);
                reservations.add(reservation);
              } catch (e) {
                print('Error parsing reservation ${doc.id}: $e');
                // Continuer avec les autres réservations
              }
            }

            return reservations;
          });
    } catch (e) {
      print('Error in getUserReservations: $e');
      return Stream.value([]);
    }
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
    // Get the license plate before cancelling
    final doc = await _firestore.collection('parkingSpots').doc(spotId).get();
    final licensePlate = doc.data()?['licensePlate'] ?? 'Unknown';

    await _firestore.collection('parkingSpots').doc(spotId).update({
      'status': 'free',
      'licensePlate': null,
      'reservedUntil': null,
      'reservationEmail': null,
      'reservationStart': null,
      'reservationEnd': null,
    });

    // Log cancellation to history
    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'cancellation',
    );
  }

  // Méthode pour libérer une place
  Future<void> freeSpot(String spotId) async {
    // Get the license plate before freeing
    final doc = await _firestore.collection('parkingSpots').doc(spotId).get();
    final licensePlate = doc.data()?['licensePlate'] ?? 'Unknown';

    await _firestore.collection('parkingSpots').doc(spotId).update({
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

    // Log exit to history
    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'exit',
    );
  }

  // Méthode pour occuper une place (entry)
  Future<void> occupySpot(String spotId, String licensePlate) async {
    await _firestore.collection('parkingSpots').doc(spotId).update({
      'isOccupied': true,
      'plaque': licensePlate.toUpperCase(),
      'entryTime': DateTime.now().toIso8601String(),
      'status': 'occupied',
    });

    // Log entry to history
    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'entry',
    );
  }

  // Method to get history stream (for real-time updates)
  Stream<QuerySnapshot> getParkingHistory() {
    return _firestore
        .collection('historique')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Method to get history for a specific spot
  Stream<QuerySnapshot> getSpotHistory(String spotId) {
    return _firestore
        .collection('historique')
        .where('spot_id', isEqualTo: spotId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Method to get history for a specific license plate
  Stream<QuerySnapshot> getLicensePlateHistory(String licensePlate) {
    return _firestore
        .collection('historique')
        .where('license_plate', isEqualTo: licensePlate.toUpperCase())
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
