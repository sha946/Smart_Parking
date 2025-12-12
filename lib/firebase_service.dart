import 'package:firebase_database/firebase_database.dart';
import '../models/parking_spot.dart';
import 'database_service.dart';

class FirebaseService {
  final DatabaseService _databaseService = DatabaseService();

  DatabaseReference get _database => _databaseService.ref;

  // Récupérer toutes les places
  Stream<List<ParkingSpot>> getParkingSpots() {
    return _database.child('parking_spots').onValue.map((event) {
      final Map<dynamic, dynamic>? data =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        return <ParkingSpot>[];
      }

      final spots = <ParkingSpot>[];

      data.forEach((key, value) {
        try {
          if (value != null && value is Map<dynamic, dynamic>) {
            final spotMap = Map<String, dynamic>.from(value);
            final spotId = key.toString();
            spotMap['id'] = spotId;

            if (spotMap.containsKey('isOccupied')) {
              spotMap['isOccupied'] = spotMap['isOccupied'] == true;
            } else {
              spotMap['isOccupied'] = false;
            }

            if (!spotMap.containsKey('status')) {
              spotMap['status'] = spotMap['isOccupied'] ? 'occupied' : 'free';
            }

            final spot = ParkingSpot.fromMap(spotMap, spotId);
            spots.add(spot);
          }
        } catch (e) {
          print('Error parsing parking spot $key: $e');
        }
      });

      return spots;
    });
  }

  // Log parking history
  Future<void> logParkingHistory({
    required String spotId,
    required String licensePlate,
    required String action,
  }) async {
    try {
      final historyRef = _database.child('historique').push();
      await historyRef.set({
        'spotId': spotId,
        'licensePlate': licensePlate.toUpperCase(),
        'action': action,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error logging history: $e');
    }
  }

  // Réserver une place
  Future<void> reserveSpot({
    required String spotId,
    required String licensePlate,
    required String email,
    required DateTime reservationDate,
    required int hour,
    required int minute,
    int duration = 1,
    double price = 0.0,
  }) async {
    final reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      hour,
      minute,
    );

    final reservedUntil = reservationDateTime.add(Duration(hours: duration));

    await _database.child('parking_spots/$spotId').update({
      'status': 'reserved',
      'isOccupied': false,
      'licensePlate': licensePlate.toUpperCase(),
      'plaque': licensePlate.toUpperCase(),
      'reservationStart': reservationDateTime.toIso8601String(),
      'reservationEnd': reservedUntil.toIso8601String(),
    });

    final reservationRef = _database.child('reservations').push();
    await reservationRef.set({
      'spotId': spotId,
      'email': email,
      'licensePlate': licensePlate.toUpperCase(),
      'reservationDateTime': reservationDateTime.millisecondsSinceEpoch,
      'creationDate': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
      'price': price,
      'status': 'confirmed',
    });

    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'reservation',
    );
  }

  // Récupérer les réservations par email
  Stream<List<Reservation>> getUserReservations(String email) {
    return _database
        .child('reservations')
        .orderByChild('email')
        .equalTo(email)
        .onValue
        .map((event) {
          final Map<dynamic, dynamic>? data =
              event.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null || data.isEmpty) {
            return <Reservation>[];
          }

          final reservations = <Reservation>[];

          data.forEach((key, value) {
            try {
              final reservationMap = Map<String, dynamic>.from(
                value as Map<dynamic, dynamic>,
              );
              final reservation = Reservation.fromMap(
                reservationMap,
                key as String,
              );
              reservations.add(reservation);
            } catch (e) {
              print('Error parsing reservation $key: $e');
            }
          });

          reservations.sort((a, b) => b.creationDate.compareTo(a.creationDate));
          return reservations;
        });
  }

  // Vérifier disponibilité
  Future<bool> isSpotAvailable(String spotId) async {
    try {
      final snapshot = await _database.child('parking_spots/$spotId').get();
      if (!snapshot.exists) return false;

      final spotData = Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
      final isOccupied = spotData['isOccupied'] ?? false;
      final status = spotData['status']?.toString() ?? 'free';

      return !isOccupied && status != 'reserved';
    } catch (e) {
      print('Error checking spot availability: $e');
      return false;
    }
  }

  // Annuler une réservation
  Future<void> cancelReservation(String spotId) async {
    final snapshot = await _database.child('parking_spots/$spotId').get();
    final spotData = snapshot.value as Map<dynamic, dynamic>?;
    final licensePlate = spotData?['licensePlate']?.toString() ?? 'Unknown';

    await _database.child('parking_spots/$spotId').update({
      'status': 'free',
      'licensePlate': null,
      'plaque': null,
      'reservationStart': null,
      'reservationEnd': null,
    });

    final reservationsSnapshot = await _database
        .child('reservations')
        .orderByChild('spotId')
        .equalTo(spotId)
        .limitToFirst(1)
        .get();

    if (reservationsSnapshot.exists) {
      final reservations = Map<dynamic, dynamic>.from(
        reservationsSnapshot.value as Map<dynamic, dynamic>,
      );
      reservations.forEach((key, value) async {
        await _database.child('reservations/$key').update({
          'status': 'cancelled',
          'cancelledAt': DateTime.now().millisecondsSinceEpoch,
        });
      });
    }

    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'cancellation',
    );
  }

  // Libérer une place
  Future<void> freeSpot(String spotId) async {
    final snapshot = await _database.child('parking_spots/$spotId').get();
    final spotData = snapshot.value as Map<dynamic, dynamic>?;
    final licensePlate =
        spotData?['licensePlate']?.toString() ??
        spotData?['plaque']?.toString() ??
        'Unknown';

    await _database.child('parking_spots/$spotId').update({
      'isOccupied': false,
      'status': 'free',
      'licensePlate': null,
      'plaque': null,
      'entryTime': null,
      'exitTime': DateTime.now().toIso8601String(),
      'reservationStart': null,
      'reservationEnd': null,
    });

    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'exit',
    );
  }

  // Occuper une place
  Future<void> occupySpot(String spotId, String licensePlate) async {
    await _database.child('parking_spots/$spotId').update({
      'isOccupied': true,
      'licensePlate': licensePlate.toUpperCase(),
      'plaque': licensePlate.toUpperCase(),
      'entryTime': DateTime.now().toIso8601String(),
      'status': 'occupied',
    });

    await logParkingHistory(
      spotId: spotId,
      licensePlate: licensePlate,
      action: 'entry',
    );
  }

  // Historique
  Stream<DatabaseEvent> getParkingHistory() {
    return _database
        .child('historique')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue;
  }

  Stream<DatabaseEvent> getSpotHistory(String spotId) {
    return _database
        .child('historique')
        .orderByChild('spotId')
        .equalTo(spotId)
        .limitToLast(20)
        .onValue;
  }

  Stream<DatabaseEvent> getLicensePlateHistory(String licensePlate) {
    return _database
        .child('historique')
        .orderByChild('licensePlate')
        .equalTo(licensePlate.toUpperCase())
        .limitToLast(20)
        .onValue;
  }

  // Get a single parking spot
  Stream<ParkingSpot?> getParkingSpot(String spotId) {
    return _database.child('parking_spots/$spotId').onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      data['id'] = spotId;

      if (data.containsKey('isOccupied')) {
        data['isOccupied'] = data['isOccupied'] == true;
      }

      return ParkingSpot.fromMap(data, spotId);
    });
  }

  // Update spot status
  Future<void> updateSpotStatus(String spotId, String status) async {
    await _database.child('parking_spots/$spotId').update({'status': status});
  }

  // Get all reservations
  Stream<List<Reservation>> getAllReservations() {
    return _database
        .child('reservations')
        .orderByChild('creationDate')
        .onValue
        .map((event) {
          final Map<dynamic, dynamic>? data =
              event.snapshot.value as Map<dynamic, dynamic>?;

          if (data == null || data.isEmpty) {
            return <Reservation>[];
          }

          final reservations = <Reservation>[];

          data.forEach((key, value) {
            try {
              final reservationMap = Map<String, dynamic>.from(
                value as Map<dynamic, dynamic>,
              );
              final reservation = Reservation.fromMap(
                reservationMap,
                key as String,
              );
              reservations.add(reservation);
            } catch (e) {
              print('Error parsing reservation $key: $e');
            }
          });

          return reservations;
        });
  }

  // Check if license plate is parked
  Future<bool> isLicensePlateParked(String licensePlate) async {
    try {
      final snapshot = await _database
          .child('parking_spots')
          .orderByChild('licensePlate')
          .equalTo(licensePlate.toUpperCase())
          .get();

      return snapshot.exists;
    } catch (e) {
      print('Error checking license plate: $e');
      return false;
    }
  }

  // Get spot by license plate
  Future<String?> getSpotIdByLicensePlate(String licensePlate) async {
    try {
      final snapshot = await _database
          .child('parking_spots')
          .orderByChild('licensePlate')
          .equalTo(licensePlate.toUpperCase())
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(
          snapshot.value as Map<dynamic, dynamic>,
        );
        return data.keys.first as String?;
      }
      return null;
    } catch (e) {
      print('Error getting spot by license plate: $e');
      return null;
    }
  }

  // Get parking stats
  Future<Map<String, int>> getParkingStats() async {
    try {
      final snapshot = await _database.child('parking_spots').get();
      if (!snapshot.exists) return {'total': 0, 'occupied': 0, 'free': 0};

      final data = Map<dynamic, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );

      int total = 0;
      int occupied = 0;

      data.forEach((key, value) {
        if (value != null && value is Map<dynamic, dynamic>) {
          total++;
          final spot = Map<String, dynamic>.from(value);
          if (spot['isOccupied'] == true) {
            occupied++;
          }
        }
      });

      return {'total': total, 'occupied': occupied, 'free': total - occupied};
    } catch (e) {
      print('Error getting parking stats: $e');
      return {'total': 0, 'occupied': 0, 'free': 0};
    }
  }
}
