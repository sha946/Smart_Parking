// models/parking_spot.dart
class ParkingSpot {
  final String id;
  final bool isOccupied;
  final String status; // 'free', 'occupied', 'reserved'
  final String? licensePlate;
  final String? entryTime;
  final String? exitTime;
  final String? reservationStart;
  final String? reservationEnd;
  final String? plaque;

  ParkingSpot({
    required this.id,
    required this.isOccupied,
    required this.status,
    this.licensePlate,
    this.entryTime,
    this.exitTime,
    this.reservationStart,
    this.reservationEnd,
    this.plaque,
  });

  // Conversion depuis Realtime Database (Map)
  factory ParkingSpot.fromMap(Map<String, dynamic> data, String documentId) {
    return ParkingSpot(
      id: data['id'] ?? documentId,
      isOccupied: (data['isOccupied'] ?? false) as bool,
      status: (data['status'] ?? 'free').toString(),
      licensePlate: data['licensePlate']?.toString(),
      entryTime: data['entryTime']?.toString(),
      exitTime: data['exitTime']?.toString(),
      reservationStart: data['reservationStart']?.toString(),
      reservationEnd: data['reservationEnd']?.toString(),
      plaque: data['plaque']?.toString(),
    );
  }

  // Conversion vers Map (pour Realtime Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isOccupied': isOccupied,
      'status': status,
      'licensePlate': licensePlate,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'reservationStart': reservationStart,
      'reservationEnd': reservationEnd,
      'plaque': plaque,
    };
  }
}

// Modèle pour les réservations
class Reservation {
  final String id;
  final String spotId;
  final String licensePlate;
  final String email;
  final DateTime reservationDateTime;
  final DateTime creationDate;
  final int duration;
  final double price;
  final String status;

  Reservation({
    required this.id,
    required this.spotId,
    required this.licensePlate,
    required this.email,
    required this.reservationDateTime,
    required this.creationDate,
    required this.duration,
    required this.price,
    this.status = 'confirmed',
  });

  Map<String, dynamic> toMap() {
    return {
      'spotId': spotId,
      'licensePlate': licensePlate,
      'email': email,
      'reservationDateTime': reservationDateTime.millisecondsSinceEpoch,
      'creationDate': creationDate.millisecondsSinceEpoch,
      'duration': duration,
      'price': price,
      'status': status,
    };
  }

  static Reservation fromMap(Map<String, dynamic> map, String id) {
    // Parse timestamps from Realtime Database
    DateTime parseTimestamp(dynamic timestamp) {
      try {
        if (timestamp is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else if (timestamp is String) {
          return DateTime.parse(timestamp);
        } else if (timestamp is Map) {
          final tsMap = timestamp as Map<String, dynamic>;
          if (tsMap.containsKey('_seconds')) {
            return DateTime.fromMillisecondsSinceEpoch(
              (tsMap['_seconds'] ?? 0) * 1000,
            );
          }
        }
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    return Reservation(
      id: id,
      spotId: map['spotId']?.toString() ?? 'Unknown',
      licensePlate: map['licensePlate']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      reservationDateTime: parseTimestamp(map['reservationDateTime']),
      creationDate: parseTimestamp(map['creationDate']),
      duration: (map['duration'] ?? 1).toInt(),
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status']?.toString() ?? 'confirmed',
    );
  }

  // Getter pour formater l'heure
  String get formattedTime {
    return '${reservationDateTime.hour.toString().padLeft(2, '0')}:${reservationDateTime.minute.toString().padLeft(2, '0')}';
  }

  // Getter pour formater la date
  String get formattedDate {
    return '${reservationDateTime.day}/${reservationDateTime.month}/${reservationDateTime.year}';
  }

  // Getter pour formater la date de création
  String get formattedCreationDate {
    return '${creationDate.day}/${creationDate.month}/${creationDate.year} ${creationDate.hour.toString().padLeft(2, '0')}:${creationDate.minute.toString().padLeft(2, '0')}';
  }

  // Calculer l'heure de fin
  DateTime get endDateTime {
    return reservationDateTime.add(Duration(hours: duration));
  }

  // Formater l'heure de fin
  String get formattedEndTime {
    final endTime = endDateTime;
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
}
