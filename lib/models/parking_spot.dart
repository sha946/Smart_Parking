import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSpot {
  final String id;
  final bool isOccupied;
  final String status; // 'free', 'occupied', 'reserved'
  final String? licensePlate;
  final String? entryTime;
  final String? exitTime;
  final String? reservationStart;
  final String? reservationEnd;

  ParkingSpot({
    required this.id,
    required this.isOccupied,
    required this.status,
    this.licensePlate,
    this.entryTime,
    this.exitTime,
    this.reservationStart,
    this.reservationEnd,
  });

  // Conversion depuis Firestore (méthode utilisée dans votre code)
  factory ParkingSpot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ParkingSpot(
      id: data['id'] ?? doc.id,
      isOccupied: data['isOccupied'] ?? false,
      status: data['status'] ?? 'free',
      licensePlate: data['licensePlate'],
      entryTime: data['entryTime'],
      exitTime: data['exitTime'],
      reservationStart: data['reservationStart'],
      reservationEnd: data['reservationEnd'],
    );
  }

  // Conversion depuis Map (méthode alternative)
  factory ParkingSpot.fromMap(Map<String, dynamic> data, String documentId) {
    return ParkingSpot(
      id: data['id'] ?? documentId,
      isOccupied: data['isOccupied'] ?? false,
      status: data['status'] ?? 'free',
      licensePlate: data['licensePlate'],
      entryTime: data['entryTime'],
      exitTime: data['exitTime'],
      reservationStart: data['reservationStart'],
      reservationEnd: data['reservationEnd'],
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'isOccupied': isOccupied,
      'status': status,
      'licensePlate': licensePlate,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'reservationStart': reservationStart,
      'reservationEnd': reservationEnd,
    };
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return toFirestore();
  }
}
