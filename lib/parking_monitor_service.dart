import 'package:firebase_database/firebase_database.dart';
import 'notification_service.dart';

class ParkingMonitorService {
  static final ParkingMonitorService _instance =
      ParkingMonitorService._internal();
  factory ParkingMonitorService() => _instance;
  ParkingMonitorService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final NotificationService _notificationService = NotificationService();

  final Map<String, bool> _spotStates = {};
  bool _monitoring = false;

  void startMonitoring() {
    if (_monitoring) return;

    print('🔍 Surveillance des places de parking démarrée...');
    _monitoring = true;

    _database.ref('parking_spots').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) async {
          if (value is Map) {
            final spotId = key.toString();
            final isOccupied = value['isOccupied'] ?? false;
            final status = value['status'] ?? 'free';

            // Vérifier si la place est passée d'occupée à libre
            if (_spotStates.containsKey(spotId)) {
              final wasOccupied = _spotStates[spotId]!;

              if (wasOccupied && !isOccupied && status == 'free') {
                print('🎉 La place $spotId est devenue libre!');

                // Afficher la notification
                await _notificationService.showFreeSpotNotification(
                  spotId: spotId,
                  additionalInfo: 'Réservez maintenant!',
                );
              }
            }

            _spotStates[spotId] = isOccupied;
          }
        });
      }
    });
  }

  void stopMonitoring() {
    _monitoring = false;
    _spotStates.clear();
    print('⏸️ Surveillance des places arrêtée');
  }
}
